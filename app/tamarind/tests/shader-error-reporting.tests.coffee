State              = require '../State.coffee'
WebGLCanvas        = require '../WebGLCanvas.coffee'
ShaderCompileError = require '../ShaderCompileError.coffee'
utils              = require '../utils.coffee'
constants          = require '../constants.coffee'
map                = require 'lodash/collection/map'

{expectCallHistory, stateListener, expectProperties} = require('./testutils.coffee')

INPUT_ERROR_SOURCE = '''
  precision mediump float;
  uniform vec4 mouse; //! mouse

  void main() {
    float foo = 4.0;
  }
'''
GL_ERROR_SOURCE = '''
  precision mediump float;
  uniform vec2 mouse; //! mouse

  void main() {
    float foo = 4;
  }
'''
TWO_ERROR_SOURCE = '''
  precision mediump float;
  uniform vec4 mouse; //! mouse

  void main() {
    float foo = 4;
  }
'''
NO_ERROR_SOURCE = '''
  precision mediump float;
  uniform vec2 mouse; //! mouse

  void main() {
    float foo = 4.0;
  }
'''

describe 'the WebGL error reporting system', ->

  createState = ->
    state = new State()
    new WebGLCanvas(state)
    return state

  it 'should return a combination of shader and command errors from getShaderErrors', (done) ->

    state = createState()
    listener = stateListener(state)


    state.setShaderSource(constants.FRAGMENT_SHADER, TWO_ERROR_SOURCE)

    state.on state.CHANGE, ->

      expectProperties state.getShaderErrors(constants.FRAGMENT_SHADER), [
        {message: /\bint\b/}, # should complain about int type
        {message: "'mouse' command can only be applied to a uniform vec2"}
      ]

      expect(listener.SHADER_ERRORS_CHANGE.calls.count()).toBeGreaterThan 0

      done()

      return


    return


  expectClearingOfErrors = (done, nextCode, nextErrorCount) ->
    state = createState()
    listener = null


    state.setShaderSource(constants.FRAGMENT_SHADER, TWO_ERROR_SOURCE)

    callCount = 0

    state.on state.CHANGE, ->
      ++callCount

      if callCount is 1

        expect(state.getShaderErrors(constants.FRAGMENT_SHADER).length).toEqual 2

        listener = stateListener(state)

        state.setShaderSource(constants.FRAGMENT_SHADER, nextCode)


      else if callCount is 2

        expect(state.getShaderErrors(constants.FRAGMENT_SHADER).length).toEqual nextErrorCount
        expect(listener.SHADER_ERRORS_CHANGE.calls.count()).toBeGreaterThan 0

        done()

      return

    return

  it 'should dispatch a SHADER_ERRORS_CHANGE event when all errors are cleared from the program', (done) ->

    expectClearingOfErrors(done, NO_ERROR_SOURCE, 0)
    return

  it 'should dispatch a SHADER_ERRORS_CHANGE event when GL errors are cleared from the program', (done) ->

    expectClearingOfErrors(done, INPUT_ERROR_SOURCE, 1)
    return

  it 'should dispatch a SHADER_ERRORS_CHANGE event when validation errors are cleared from the program', (done) ->

    expectClearingOfErrors(done, GL_ERROR_SOURCE, 1)
    return


  return
