utils              = require './utils.coffee'
EventEmitter       = require './EventEmitter.coffee'
ProgramAnalyser    = require './commands/ProgramAnalyser.coffee'
std_command_parser = require './commands/std_command_parser.coffee'
constants          = require './constants.coffee'
indexBy            = require 'lodash/collection/indexBy'
isEqual            = require 'lodash/lang/isEqual'
fill               = require 'lodash/array/fill'


###
  An object shared between the various Tamarind visual components that
  enables state synchronisation and event-based communication.
###
class State extends EventEmitter



  # @property [int] The number of vertices drawn.
  # Vertices are created at the origin (coordinate 0,0,0) and are positioned by the vertex
  # shader. The vertex shader gets an attribute a_VertexIndex, being a number between 0 and
  # `vertexCount - 1` that it can use to distinguish vertices
  vertexCount: 4


  # @property [String] A string mode name as used by WebGL's drawArrays method
  # i.e. one of: POINTS, LINES, LINE_LOOP, LINE_STRIP, TRIANGLES, TRIANGLE_STRIP or TRIANGLE_FAN
  drawingMode: 'TRIANGLE_FAN'

  # @property [Number] the x position of the mouse, 0 at centre, -1 at left, 1 at right
  mouseX: 0

  # @property [Number] the y position of the mouse, 0 at centre, -1 at top, 1 at bottom
  mouseY: 0

  # @property [Number] the width of the HTML canvas element in device pixels. This property is updated to match the
  # current canvas size - setting it doesn't control the canvas!
  canvasWidth: 0

  # @property [Number] the height of the HTML canvas element in device pixels. This property is updated to match the
  # current canvas size - setting it doesn't control the canvas!
  canvasHeight: 0

  # @property [boolean] Whether the control draw is open allowing the user to interact with the shader
  controlsExpanded: false

  # @property [Array] A read-only array of Input objects
  inputs: []

  # @property [String] the name of the currently selected UI tab. Not saved and restored.
  selectedTab: constants.FRAGMENT_SHADER

  # @property [string] Name of event emitted when shaders change. The shader type, e.g. constants.FRAGMENT_SHADER, is passed as the event argument.
  SHADER_CHANGE: 'shaderChange'

  # @property [string] This event is dispatched asynchronously when any non-transient state changes, with
  #                    one event dispatched per animation frame if there were 1 or more changes in the previous frame
  CHANGE: 'change'

  # @property [string] Name of event emitted when shaders change. The shader type, e.g. constants.FRAGMENT_SHADER, will be the event argument.
  SHADER_ERRORS_CHANGE: 'shaderErrorsChange'

  # @property [string] Name of event dispatched when the value of a specific input changes. The input name is passed as an event argument.
  INPUT_VALUE_CHANGE: 'inputValueChange'


  constructor: ->
    @_resetState()

    # state that lasts the lifetime of this State object
    @_lifetime = {
      mouseX: PROPERTY_DEFAULTS.mouseX
      mouseY: PROPERTY_DEFAULTS.mouseY
      canvasWidth: PROPERTY_DEFAULTS.canvasWidth
      canvasHeight: PROPERTY_DEFAULTS.canvasHeight
    }


  # @private
  _resetState: ->
    # state that is save()'d and restore()'d
    @_persistent = {
      FRAGMENT_SHADER: constants.DEFAULT_FSHADER_SOURCE
      VERTEX_SHADER: constants.DEFAULT_VSHADER_SOURCE
      vertexCount: PROPERTY_DEFAULTS.vertexCount
      drawingMode: PROPERTY_DEFAULTS.drawingMode
      controlsExpanded: PROPERTY_DEFAULTS.controlsExpanded
      inputValues: {}
    }

    @_analyser = new ProgramAnalyser(std_command_parser)

    # state that is reset each time we restore()
    @_transient = {
      shaders:
        FRAGMENT_SHADER:
          errors: []
          errorText: []
        VERTEX_SHADER:
          errors: []
          errorText: []
      inputs: []
      propertyJSON: {}
      selectedTab: PROPERTY_DEFAULTS.selectedTab
      inputsByName: {}
    }

    return



  # Get the source code for a shader
  # @param shaderType either constants.VERTEX_SHADER or constants.FRAGMENT_SHADER
  getShaderSource: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_persistent[shaderType]


  # Set the source code for a shader
  # @param shaderType either constants.VERTEX_SHADER or constants.FRAGMENT_SHADER
  # @param value GLSL source code for the shader
  setShaderSource: (shaderType, source) ->
    @_validateShaderType(shaderType)
    utils.validateType(source, 'string', 'shaderType')
    if @_persistent[shaderType] isnt source
      @_persistent[shaderType] = source
      @_analyser.setShaderSource(shaderType, source)
      @_setInputs(@_analyser.getCommands())
      @emit @SHADER_CHANGE, shaderType
      @emit @SHADER_ERRORS_CHANGE, shaderType
      @_scheduleChangeEvent()
    return




  # Return true is getShaderErrors(shaderType) would return an array of length > 1
  # @param shaderType either constants.VERTEX_SHADER or constants.FRAGMENT_SHADER
  hasShaderErrors: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_transient.shaders[shaderType].errors.length > 0

  # Get the list of ShaderCompileError error objects for a shader
  # @param shaderType either constants.VERTEX_SHADER or constants.FRAGMENT_SHADER
  getShaderErrors: (shaderType) ->
    @_validateShaderType(shaderType)
    sourceErrors = @_transient.shaders[shaderType].errors
    commandErrors = @_analyser.getCommandErrors(shaderType)
    return sourceErrors.concat(commandErrors)


  # Set the list of errors for a shader
  # @param shaderType [string] either constants.VERTEX_SHADER or constants.FRAGMENT_SHADER
  # @param errorText [String] the error text returned by the browser, used for the purposes of checking if the errors have changed
  # @param errors [number] an array of ShaderCompileError objects
  setShaderErrors: (shaderType, errorText, errors) ->
    @_validateShaderType(shaderType)
    if @_transient.shaders[shaderType].errorText isnt errorText
      @_transient.shaders[shaderType].errorText = errorText
      @_transient.shaders[shaderType].errors = errors
      @emit @SHADER_ERRORS_CHANGE, shaderType

    return



  # receive notifications when a specific property changes
  onPropertyChange: (propertyName, callback) ->
    if @[propertyName] is undefined
      throw new Error("Invalid property name '#{propertyName}'")
    @on PROPERTY_CHANGE_EVENTS[propertyName], callback
    return


  # Overwrite the existing inputs array with a new one.
  # @param inputs an array of objects representing inputs, see the Inputs class for details.
  _setInputs: (inputs) ->

    if isEqual(@_transient.inputs, inputs)
      return

    @_transient.inputs = inputs
    @_transient.inputsByName = indexBy inputs, 'uniformName'

    newInputValues = {}
    for input in inputs
      value = @_persistent.inputValues[input.uniformName]
      unless value and value.length is input.type.dataLength
        value = fill(Array(input.type.dataLength), 0)
      newInputValues[input.uniformName] = value
    @_persistent.inputValues = newInputValues

    @emit PROPERTY_CHANGE_EVENTS.inputs, @_transient.inputs
    @_scheduleChangeEvent()

    if @_analyser.getCommandErrors(constants.FRAGMENT_SHADER).length > 0
      @emit @SHADER_ERRORS_CHANGE, constants.FRAGMENT_SHADER

    if @_analyser.getCommandErrors(constants.VERTEX_SHADER).length > 0
      @emit @SHADER_ERRORS_CHANGE, constants.VERTEX_SHADER

    return



  # get the value of a specific input
  getInputValue: (inputName) ->
    value = @_persistent.inputValues[inputName]
    if value is undefined
      throw new Error("no input '#{inputName}'")
    return value

  # set the value of a specific input
  setInputValue: (inputName, value) ->
    input = @_getInputByName(inputName)
    unless Array.isArray(value) and value.length is input.type.dataLength
      utils.logError "invalid value for #{inputName}: " + JSON.stringify(value)
      return
    unless isEqual(@_persistent.inputValues[inputName], value)
      @_persistent.inputValues[inputName] = value
      @emit @INPUT_VALUE_CHANGE, inputName
      @_scheduleChangeEvent()
    return

  _getInputByName: (inputName) ->
    input = @_transient.inputsByName[inputName]
    return input



  # Serialise this object as a JSON string
  save: ->
    return JSON.stringify @_persistent

  # Restore this object from a previously saved
  restore: (saved) ->
    @_resetState()
    for key, value of JSON.parse(saved)
      if key is constants.FRAGMENT_SHADER or key is constants.VERTEX_SHADER
        @setShaderSource key, value
      else if WRITABLE_PROPERTIES[key]
        @[key] = value
        @emit PROPERTY_CHANGE_EVENTS[key], value
      else if key is 'inputValues'
        for k, v of value
          @setInputValue(k, v)
      else
        utils.logError 'restore() ignoring unrecognised key ' + key
    return


  # @private
  _scheduleChangeEvent: ->
    unless @_changeEventScheduled
      @_changeEventScheduled = true
      requestAnimationFrame =>
        @_changeEventScheduled = false
        @emit @CHANGE
        return
    return

  # @private
  _validateShaderType: (shaderType) ->
    if @_persistent[shaderType] is undefined
      throw new Error("Invalid shader type: #{shaderType}")


  PROPERTY_DEFAULTS = {}
  WRITABLE_PROPERTIES = {}
  PROPERTY_CHANGE_EVENTS = {}

  # define a read/write property that maps to getProperty and setProperty
  _defineProperty = (propertyName, storage, readOnly = false) =>

    defaultValue = State.prototype[propertyName]
    valueType = typeof defaultValue

    if valueType is 'undefined'
      throw new Error('No default value for property ' + propertyName)

    PROPERTY_DEFAULTS[propertyName] = defaultValue
    PROPERTY_CHANGE_EVENTS[propertyName] = propertyName + 'Changed'

    unless readOnly
      WRITABLE_PROPERTIES[propertyName] = true


    config =
      enumerable: true

      get: -> @[storage][propertyName]

      set: (newValue) ->
        if readOnly
          throw new Error("#{propertyName} is read only")
        utils.validateType(newValue, valueType, propertyName)
        unless @[storage][propertyName] is newValue
          @[storage][propertyName] = newValue
          @emit PROPERTY_CHANGE_EVENTS[propertyName], newValue
          @_scheduleChangeEvent()
        return

    Object.defineProperty @.prototype, propertyName, config

    return


  _defineProperty 'vertexCount', '_persistent'
  _defineProperty 'drawingMode', '_persistent'
  _defineProperty 'controlsExpanded', '_persistent'
  _defineProperty 'mouseX', '_lifetime'
  _defineProperty 'mouseY', '_lifetime'
  _defineProperty 'canvasWidth', '_lifetime'
  _defineProperty 'canvasHeight', '_lifetime'
  _defineProperty 'inputs', '_transient', true
  _defineProperty 'selectedTab', '_transient'

module.exports = State