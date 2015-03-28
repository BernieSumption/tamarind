

describe 'State', ->

  stateListener = (state) ->

    listener = {}

    for prop in ['SHADER_CHANGE', 'CHANGE', 'INPUT_VALUE_CHANGE']
      listener[prop] = ->
      spyOn(listener, prop)
      state.on state[prop], listener[prop]

    for prop in ['vertexCount', 'debugMode', 'drawingMode', 'selectedTab', 'controlsExpanded', 'inputs']
      listener[prop] = ->
      spyOn(listener, prop)
      state.onPropertyChange prop, listener[prop]


    return listener

  it 'should dispatch events when properties change', (done) ->

    state = new Tamarind.State()
    listener = stateListener(state)

    state.vertexCount = 111
    state.vertexCount = 222
    state.vertexCount = 222 # no change
    state.debugMode = true

    # expect one general PROPERTY_CHANGE event per change with property name as argument
    expect(state.vertexCount).toEqual 222
    expect(state.debugMode).toEqual true

    # expect one specific change event per change, with new value as argument
    expectCallHistory listener.vertexCount, [111, 222]
    expectCallHistory listener.debugMode, [true]

    # expect a single CHANGE, dispatched asynchronously
    pollUntil (-> listener.CHANGE.calls.count() > 0), ->
      expectCallHistory listener.CHANGE, [undefined]

      # trigger another change event
      state.vertexCount = 333
      pollUntil (-> listener.CHANGE.calls.count() > 1), ->
        expectCallHistory listener.CHANGE, [undefined, undefined ]
        done()
        return

      return

    return



  it 'should dispatch an event when a shader changes', ->

    state = new Tamarind.State()
    listener = stateListener(state)

    state.setShaderSource Tamarind.VERTEX_SHADER, Tamarind.DEFAULT_VSHADER_SOURCE # no event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # yes event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # no event

    expectCallHistory listener.SHADER_CHANGE, [Tamarind.FRAGMENT_SHADER]

    return

  it 'should allow saving and restoring of content', ->

    state = new Tamarind.State()

    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag'
    state.setShaderSource Tamarind.VERTEX_SHADER, 'vert'
    state.vertexCount = 12345
    state.inputs = [ interestingInput(name: 'my_input', value: [2]) ]

    serialized = state.save()

    state = new Tamarind.State()

    expect(state.vertexCount).not.toEqual(12345)
    expect(state.getShaderSource Tamarind.FRAGMENT_SHADER).not.toEqual('frag')
    expect(state.getShaderSource Tamarind.VERTEX_SHADER).not.toEqual('vert')

    listener = stateListener(state)

    state.restore(serialized)

    expect(state.vertexCount).toEqual(12345)
    expect(state.getShaderSource Tamarind.FRAGMENT_SHADER).toEqual('frag')
    expect(state.getShaderSource Tamarind.VERTEX_SHADER).toEqual('vert')
    expect(state.inputs).toEqual [ interestingInput(name: 'my_input', value: [2]) ]


    expectCallHistory listener.SHADER_CHANGE, [Tamarind.FRAGMENT_SHADER, Tamarind.VERTEX_SHADER]
    expectCallHistory listener.INPUT_VALUE_CHANGE, [] # setting inputs doesn't fire INPUT_VALUE_CHANGE
    expectCallHistory listener.inputs, [ [ interestingInput(name: 'my_input', value: [2]) ] ]
    expectCallHistory listener.controlsExpanded, [false]

    return


  it 'should log an error if invalid properties given to restore', ->

    state = new Tamarind.State()
    state.debugMode = true
    expect(-> state.restore '{"blarty": "shiz"}').toThrow(new Error('debugMode: restore() ignoring unrecognised key blarty'))

    return

  it 'should delete transient state on restore', ->

    state = new Tamarind.State()
    saved = state.save()
    state.setShaderErrors Tamarind.VERTEX_SHADER, '', [new Tamarind.ShaderCompileError('', 1)]
    state.selectedTab = 'CONFIG'

    state.restore(saved)

    expect(state.selectedTab).not.toEqual('config')
    expect(state.getShaderErrors Tamarind.VERTEX_SHADER).toEqual([])

    return

  it 'should not expose mutable state through the (get/set)ShaderErrors API', ->

    state = new Tamarind.State()

    # mutating refs returned from getShaderErrors shouldn't alter internal state
    errors = state.getShaderErrors(Tamarind.FRAGMENT_SHADER)
    expect(errors).toEqual []
    errors.push(new Tamarind.ShaderCompileError('Message', 0))
    errors = state.getShaderErrors(Tamarind.FRAGMENT_SHADER)
    expect(errors).toEqual []

    # mutating input passed to setShaderErrors shouldn't alter internal state
    error = new Tamarind.ShaderCompileError('', 0)
    errorsRef = [error]
    state.setShaderErrors Tamarind.FRAGMENT_SHADER, '', [error]
    expect(state.getShaderErrors Tamarind.FRAGMENT_SHADER).toEqual [error]
    errorsRef.push(new Tamarind.ShaderCompileError('', 1))
    expect(state.getShaderErrors Tamarind.FRAGMENT_SHADER).toEqual [error]

    return



  it 'should handle log and error messages', ->
    state = new Tamarind.State()

    spyOn(console, 'log')
    spyOn(console, 'error')

    state.logError('err1') # should console error
    state.logInfo('info1') # should be ignored

    state.debugMode = true
    expect(-> state.logError('err2')).toThrow new Error('debugMode: err2') # should throw exception
    state.logInfo('info2') # should console log

    expectCallHistory console.error, ['err1']
    expectCallHistory console.log, ['info2']

    return

  it 'should dispatch events when inputs change', ->

    state = new Tamarind.State()
    listener = stateListener(state)

    expect(state.inputs).toEqual []

    evts = [
      {
        type: 'slider'
        name: 'my_slider'
        min: 0
        max: 10
        step: 0.1
        value: [0]
      }
    ]

    state.inputs = [] # no change
    state.inputs = evts
#    state.inputs = evts.slice() # no change

    expect(state.inputs).toEqual(evts)
    expectCallHistory listener.inputs, [[], evts]

    return

  it 'should not expose mutable state through the (get/set)Inputs API', ->

    state = new Tamarind.State()

    inputs = state.inputs
    inputs.push interestingInput(name: 'a')
    expect(state.inputs).toEqual([])

    inputs = [interestingInput(name: 'b')]
    state.inputs = inputs
    inputs.push interestingInput(name: 'c')
    expect(state.inputs).toEqual [ interestingInput(name: 'b') ]

    return


  it 'should allow the access to input values through (get/set)InputValue', ->

    state = new Tamarind.State()
    listener = stateListener(state)

    spyOn(console, 'error')

    state.inputs = [ interestingInput(name: 'my_slider', value: [5]) ]

    expect(state.getInputValue 'my_slider').toEqual [5]

    state.setInputValue 'my_slider', null # error message, no event, no effect

    expect(state.getInputValue 'my_slider').toEqual [5]

    state.setInputValue 'my_slider', [5] # no change, no effect

    state.setInputValue 'my_slider', [6] # change

    expectCallHistory console.error, ['invalid value for my_slider: null']



    expectCallHistory listener.INPUT_VALUE_CHANGE, [ 'my_slider' ]

    return

  return
