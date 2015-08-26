State              = require '../State.coffee'
Tamarind           = require '../Tamarind.coffee'
utils              = require '../utils.coffee'
constants          = require '../constants.coffee'
ShaderCompileError = require '../ShaderCompileError.coffee'

{mockSliderInput, mockColorInput, expectCallHistory, pollUntil, stateListener, expectProperties} = require('./testutils.coffee')

describe 'State', ->


  it 'should dispatch events when properties change', (done) ->

    state = new State()
    listener = stateListener(state)

    state.vertexCount = 111
    state.vertexCount = 222
    state.vertexCount = 222 # no change

    # expect one general PROPERTY_CHANGE event per change with property name as argument
    expect(state.vertexCount).toEqual 222

    # expect one specific change event per change, with new value as argument
    expectCallHistory listener.vertexCount, [111, 222]

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

    expectCallHistory listener.SHADER_SOURCE_CHANGE, [constants.FRAGMENT_SHADER]

    return

  it 'should allow saving and restoring of content', ->

    state = new State()

    state.setShaderSource constants.FRAGMENT_SHADER, 'uniform float foo; //! slider'
    state.setShaderSource constants.VERTEX_SHADER, 'vert'
    state.vertexCount = 12345
    state.setInputValue('foo', [6])


    serialized = state.save()

    state = new State()

    expect(state.vertexCount).not.toEqual(12345)
    expect(state.getShaderSource constants.FRAGMENT_SHADER).not.toEqual('uniform float foo; //! slider')
    expect(state.getShaderSource constants.VERTEX_SHADER).not.toEqual('vert')
    expect(-> state.getInputValue('foo')).toThrowError()

    listener = stateListener(state)

    state.restore(serialized)

    expect(state.vertexCount).toEqual(12345)
    expect(state.getShaderSource constants.FRAGMENT_SHADER).toEqual('uniform float foo; //! slider')
    expect(state.getShaderSource constants.VERTEX_SHADER).toEqual('vert')
    expect(state.getInputValue 'foo').toEqual [6]


    expect(listener.inputs.calls.count()).toEqual 1
    expectCallHistory listener.SHADER_SOURCE_CHANGE, [constants.FRAGMENT_SHADER, constants.VERTEX_SHADER]
    expectCallHistory listener.INPUT_VALUE_CHANGE, [ 'foo' ]
    expectCallHistory listener.controlsExpanded, [false]

    return


  it 'should log an error if invalid properties given to restore', ->

    state = new State()

    spyOn(console, 'error')

    state.restore '{"blarty": "shiz"}'

    expectCallHistory console.error, ['restore() ignoring unrecognised key blarty']

    return

  it 'should delete transient state on restore', ->

    state = new State()
    saved = state.save()
    state.setShaderErrors constants.VERTEX_SHADER, '', [new ShaderCompileError('', 1)]

    state.restore(saved)

    expect(state.getShaderErrors constants.VERTEX_SHADER).toEqual([])

    return


  it 'should handle log and error messages', ->

    spyOn(console, 'log')
    spyOn(console, 'error')

    utils.logError('err1') # should console error
    utils.logInfo('info1') # should be ignored

    Tamarind.debugMode = true

    expect(-> utils.logError('err2')).toThrow new Error('debugMode: err2') # should throw exception
    utils.logInfo('info2') # should console log

    expectCallHistory console.error, ['err1']
    expectCallHistory console.log, ['info2']

    Tamarind.debugMode = false

    return


  it 'should allow setting of inputs through _setInputs', ->

    state = new State()
    listener = stateListener(state)

    expect(state.inputs).toEqual []

    inputs = [ mockSliderInput(name: 'in' ) ]

    state._setInputs inputs

    expect(state.inputs).toEqual(inputs)
    expectCallHistory listener.inputs, [inputs]

    return


  it 'should allow setting of input values through get/setInputValue', ->

    state = new State()

    state._setInputs [ mockSliderInput(name: 'in' ) ]

    state.setInputValue('in', [5])

    expect(state.getInputValue('in')).toEqual [5]

    return


  it 'should only dispatch inputsChange events when the inputs actually change', ->

    state = new State()
    listener = stateListener(state)

    expect(state.inputs).toEqual []

    inputs = [ mockSliderInput(name: 'in' ) ]

    state._setInputs inputs
    state._setInputs [ mockSliderInput(name: 'in' ) ] # equivalent but different objects

    expectCallHistory listener.inputs, [inputs]

    return


  it 'should throw an error when asked for the value of a non-existent input', ->

    state = new State()

    expect(-> state.getInputValue('blarty')).toThrow(new Error("no input 'blarty'"))


    return


  it 'should default the value of a new input to an array of zeroes of the correct length', ->

    state = new State()

    state._setInputs [
      mockSliderInput(name: 'slider'),
      mockColorInput(name: 'color'),
    ]

    expect(state.getInputValue('slider')).toEqual [0]
    expect(state.getInputValue('color')).toEqual [0, 0, 0]

    return


  it 'should preserve the existing values of inputs when the input is re-set to an input of the same type using _setInputs', ->

    state = new State()

    state._setInputs [
      mockSliderInput(name: 'a')
    ]

    state.setInputValue('a', [1])

    expect(state.getInputValue 'a').toEqual [1]

    state._setInputs [
      mockSliderInput(name: 'a', min: -20)
    ]

    expect(state.getInputValue 'a').toEqual [1]

    state._setInputs [
      mockColorInput(name: 'a')
    ]

    expect(state.getInputValue 'a').toEqual [0, 0, 0]

    return


  it 'should remove an input value from the persisted value map when the corresponding input is removed', ->

    state = new State()

    state._setInputs [
      mockSliderInput(name: 'a')
    ]

    state.setInputValue('a', [1])

    expect(state._persistent.inputValues).toEqual {a: [1]}

    state._setInputs [
      mockSliderInput(name: 'b')
    ]

    expect(state._persistent.inputValues).toEqual {b: [0]}

    return



  it 'should dispatch INPUT_VALUE_CHANGE events when... well, when an input value changes I suppose', ->

    state = new State()
    listener = stateListener(state)

    spyOn(console, 'error')

    state._setInputs [ mockSliderInput(name: 'my_slider') ]

    state.setInputValue('my_slider', [0]) # same as default value, no change event

    state.setInputValue('my_slider', [5]) # new value, change event

    state.setInputValue 'my_slider', null # error message, no change event, no effect

    expect(state.getInputValue 'my_slider').toEqual [5]

    state.setInputValue 'my_slider', [5] # no change, no effect

    state.setInputValue 'my_slider', [6] # change

    expectCallHistory console.error, ['invalid value for my_slider: null']

    expectCallHistory listener.INPUT_VALUE_CHANGE, [ 'my_slider', 'my_slider' ]

    return


  it 'should return a combination of shader and command errors from getShaderErrors', ->

    state = new State()

    source = '''
      uniform vec4 mouse; //! mouse
    ''' # error - mouse requires vec2

    state.setShaderSource(constants.FRAGMENT_SHADER, source)

    state.setShaderErrors(constants.FRAGMENT_SHADER, null, [new ShaderCompileError('hello world')])

    expectProperties state.getShaderErrors(constants.FRAGMENT_SHADER), [
      {message: 'hello world'},
      {message: "'mouse' command can only be applied to a uniform vec2"}
    ]

    return


  return
