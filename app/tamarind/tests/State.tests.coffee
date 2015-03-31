State = require('../State.coffee')
constants = require('../constants.coffee')
ShaderCompileError = require('../ShaderCompileError.coffee')
{mockInput, interestingInput, expectCallHistory, pollUntil} = require('./testutils.coffee')

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

    state = new State()
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

    state = new State()
    listener = stateListener(state)

    state.setShaderSource constants.VERTEX_SHADER, constants.DEFAULT_VSHADER_SOURCE # no event
    state.setShaderSource constants.FRAGMENT_SHADER, 'frag' # yes event
    state.setShaderSource constants.FRAGMENT_SHADER, 'frag' # no event

    expectCallHistory listener.SHADER_CHANGE, [constants.FRAGMENT_SHADER]

    return

  it 'should allow saving and restoring of content', ->

    state = new State()

    state.setShaderSource constants.FRAGMENT_SHADER, 'frag'
    state.setShaderSource constants.VERTEX_SHADER, 'vert'
    state.vertexCount = 12345
    state.setInputs [ interestingInput(name: 'my_input', value: [2]) ]

    serialized = state.save()

    state = new State()

    expect(state.vertexCount).not.toEqual(12345)
    expect(state.getShaderSource constants.FRAGMENT_SHADER).not.toEqual('frag')
    expect(state.getShaderSource constants.VERTEX_SHADER).not.toEqual('vert')

    listener = stateListener(state)

    state.restore(serialized)

    expect(state.vertexCount).toEqual(12345)
    expect(state.getShaderSource constants.FRAGMENT_SHADER).toEqual('frag')
    expect(state.getShaderSource constants.VERTEX_SHADER).toEqual('vert')
    expect(state.inputs).toEqual [ interestingInput(name: 'my_input', value: [2]) ]


    expectCallHistory listener.SHADER_CHANGE, [constants.FRAGMENT_SHADER, constants.VERTEX_SHADER]
    expectCallHistory listener.INPUT_VALUE_CHANGE, [] # setting inputs doesn't fire INPUT_VALUE_CHANGE
    expectCallHistory listener.inputs, [ [ interestingInput(name: 'my_input', value: [2]) ] ]
    expectCallHistory listener.controlsExpanded, [false]

    return


  it 'should log an error if invalid properties given to restore', ->

    state = new State()
    state.debugMode = true
    expect(-> state.restore '{"blarty": "shiz"}').toThrow(new Error('debugMode: restore() ignoring unrecognised key blarty'))

    return

  it 'should delete transient state on restore', ->

    state = new State()
    saved = state.save()
    state.setShaderErrors constants.VERTEX_SHADER, '', [new ShaderCompileError('', 1)]
    state.selectedTab = 'CONFIG'

    state.restore(saved)

    expect(state.selectedTab).not.toEqual('config')
    expect(state.getShaderErrors constants.VERTEX_SHADER).toEqual([])

    return



  it 'should handle log and error messages', ->
    state = new State()

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

  it 'should allow setting of inputs through setInputs', ->

    state = new State()
    listener = stateListener(state)

    expect(state.inputs).toEqual []

    evts = [ interestingInput(name: 'in', value: [4]) ]

    state.setInputs evts
    #    state.setInputs evts.slice() # no change

    expect(state.getInputValue('in')).toEqual [4]
    expect(state.inputs).toEqual(evts)
    expectCallHistory listener.inputs, [evts]

    state.setInputs [interestingInput(name: 'in', value: [7])]
    expect(state.getInputValue('in')).toEqual [7]

    return

  it 'should preserve the existing values of inputs through setInputs when asked', ->

    state = new State()
    listener = stateListener(state)

    state.setInputs [
      interestingInput(name: 'a', value: [1])
      interestingInput(name: 'b', value: [2])
    ]

    expect(state.inputs).toEqual [
      interestingInput(name: 'a', value: [1])
      interestingInput(name: 'b', value: [2])
    ]

    state.setInputs [
      interestingInput(name: 'a', value: [3])
      interestingInput(name: 'b', value: [4])
      interestingInput(name: 'c', value: [5])
    ], true

    expect(state.inputs).toEqual [
      interestingInput(name: 'a', value: [1])
      interestingInput(name: 'b', value: [2])
      interestingInput(name: 'c', value: [5])
    ]

    return


  it 'should allow the access to input values through (get/set)InputValue', ->

    state = new State()
    listener = stateListener(state)

    spyOn(console, 'error')

    state.setInputs [ interestingInput(name: 'my_slider', value: [5]) ]

    expect(state.getInputValue 'my_slider').toEqual [5]

    state.setInputValue 'my_slider', null # error message, no event, no effect

    expect(state.getInputValue 'my_slider').toEqual [5]

    state.setInputValue 'my_slider', [5] # no change, no effect

    state.setInputValue 'my_slider', [6] # change

    expectCallHistory console.error, ['invalid value for my_slider: null']



    expectCallHistory listener.INPUT_VALUE_CHANGE, [ 'my_slider' ]

    return

  return
