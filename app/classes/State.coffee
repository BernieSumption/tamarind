

###
  An object shared between the various Tamarind visual components that
  enables state synchronisation and event-based communication.
###
class Tamarind.State extends Tamarind.EventEmitter


  # @property [int] The number of vertices drawn.
  # Vertices are created at the origin (coordinate 0,0,0) and are positioned by the vertex
  # shader. The vertex shader gets an attribute a_VertexIndex, being a number between 0 and
  # `vertexCount - 1` that it can use to distinguish vertices
  vertexCount: 4


  # @property [String] A string mode name as used by WebGL's drawArrays method
  # i.e. one of: POINTS, LINES, LINE_LOOP, LINE_STRIP, TRIANGLES, TRIANGLE_STRIP or TRIANGLE_FAN
  drawingMode: 'TRIANGLE_FAN'

  # @property [boolean] Whether to log more data, including all WebGL errors. This
  # requires checking with WebGL for an error after each operation, which is very
  # slow. Don't use this in production
  debugMode: false

  # @property [String] the name of the currently selected UI tab. Not saved and restored.
  selectedTab: Tamarind.FRAGMENT_SHADER

  # @property [string] Name of event emitted when shaders change. The shader type, e.g. Tamarind.FRAGMENT_SHADER, is passed as the event argument.
  SHADER_CHANGE: 'shaderChange'

  # @property [string] Name of event emitted when a top level property like vertexCount changes. The property name, e.g. 'vertexCount', will be the event argument.
  PROPERTY_CHANGE: 'propertyChange'

  # @property [string] Name of event emitted when any non-transient state changes.
  CHANGE: 'change'

  # @property [string] Name of event emitted when shaders change. The shader type, e.g. Tamarind.FRAGMENT_SHADER, will be the event argument.
  SHADER_ERRORS_CHANGE: 'shaderErrorsChange'

  # @property [string] Name of event dispatched when the inputs change.
  INPUTS_CHANGE: 'inputsChange'

  # @property [string] Name of event dispatched when the value of a specific input changes. The input name is passed as an event argument.
  INPUT_VALUE_CHANGE: 'inputValueChange'


  constructor: ->
    @_resetState()

    # state that lasts the lifetime of this State object
    @_lifetime = {
      debugMode: PROPERTY_DEFAULTS.debugMode
    }


  # @private
  _resetState: ->
    # state that is save()'d and restore()'d
    @_persistent = {
      FRAGMENT_SHADER: Tamarind.DEFAULT_FSHADER_SOURCE
      VERTEX_SHADER: Tamarind.DEFAULT_VSHADER_SOURCE
      inputs: []
      vertexCount: PROPERTY_DEFAULTS.vertexCount
      drawingMode: PROPERTY_DEFAULTS.drawingMode
    }

    # state that is reset each time we restore()
    @_transient = {
      shaders:
        FRAGMENT_SHADER:
          errors: []
          errorText: []
        VERTEX_SHADER:
          errors: []
          errorText: [],
      selectedTab: PROPERTY_DEFAULTS.selectedTab
    }

    return



  # Get the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderSource: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_persistent[shaderType]


  # Set the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param value GLSL source code for the shader
  setShaderSource: (shaderType, value) ->
    @_validateShaderType(shaderType)
    @_validateType(value, 'string', 'shaderType')
    if @_persistent[shaderType] isnt value
      @_persistent[shaderType] = value
      @emit @SHADER_CHANGE, shaderType
      @_scheduleChangeEvent()
    return




  # Get the list of Tamarind.ShaderError error objects for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderErrors: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_transient.shaders[shaderType].errors.slice()


  # Set the list of errors for a shader
  # @param shaderType [string] either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param errorText [String] the error text returned by the browser, used for the purposes of checking if the errors have changed
  # @param errors [number] an array of ShaderError objects
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



  # Return a list of input objects.
  getInputs: ->
    return JSON.parse(JSON.stringify @_persistent.inputs)

  # Set the list of input objects.
  setInputs: (value) ->
    newInputsJSON = JSON.stringify value
    unless @_transient.inputsJSON is newInputsJSON
      @_transient.inputsJSON = newInputsJSON
      @_persistent.inputs = []
      @_transient.inputsByName = {}
      for input in JSON.parse(newInputsJSON)
        input = Inputs.validate(input, @)
        if input
          @_persistent.inputs.push(input)
          @_transient.inputsByName[input.name] = input

      for input in @_persistent.inputs
        @_transient.inputsByName[input.name] = input
        @emit @INPUT_VALUE_CHANGE, input.name

      @emit @INPUTS_CHANGE
    return


  # get the value of a specific input
  getInputValue: (inputName) ->
    return @_getInputByName(inputName).value

  # set the value of a specific input
  setInputValue: (inputName, value) ->
    unless typeof value is 'number' and not isNaN(value)
      @logError "invalid value for #{inputName}: " + JSON.stringify(value)
      return
    input = @_getInputByName(inputName)
    unless input.value is value
      input.value = value
      @emit @INPUT_VALUE_CHANGE, inputName
    return

  _getInputByName: (inputName) ->
    input = @_transient.inputsByName[inputName]
    unless input
      throw new Error("no input '#{inputName}'")
    return input



  # Serialise this object as a JSON string
  save: ->
    return JSON.stringify @_persistent

  # Restore this object from a previously saved
  restore: (saved) ->
    @_resetState()
    for key, value of JSON.parse(saved)
      if key is Tamarind.FRAGMENT_SHADER or key is Tamarind.VERTEX_SHADER
        @setShaderSource key, value
      else if key is 'inputs'
        @setInputs value
      else if PROPERTY_DEFAULTS[key] isnt undefined
        @[key] = value
      else
        @logError 'restore() ignoring unrecognised key ' + key
    return


  # Record an error. This will results in a thrown exception in debugMode or a console error in normal mode
  logError: (message) ->
    if @debugMode
      throw new Error('debugMode: ' + message)
    else
      console.error message
    return


  # Record an event. This will results in a console log in debugMode or nothing in normal mode
  logInfo: (message) ->
    if @debugMode
      console.log message
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

  # @private
  _validateType: (actualValue, expectedType, propertyName) ->
    unless typeof actualValue is expectedType
      throw new Error("Can't set '#{propertyName}' to '#{actualValue}': expected a '#{expectedType}'")



  PROPERTY_DEFAULTS = {}
  PROPERTY_CHANGE_EVENTS = {}

  # define a read/write property that maps to getProperty and setProperty
  _defineProperty = (propertyName, storage) =>

    PROPERTY_DEFAULTS[propertyName] = State.prototype[propertyName]
    PROPERTY_CHANGE_EVENTS[propertyName] = propertyName + 'Changed'

    config =
      enumerable: true
      get: -> @[storage][propertyName]
      set: (value) ->
        @_validateType(value, typeof @[storage][propertyName], propertyName)
        if @[storage][propertyName] isnt value
          @[storage][propertyName] = value
          @emit @PROPERTY_CHANGE, propertyName
          @emit PROPERTY_CHANGE_EVENTS[propertyName], value
          @_scheduleChangeEvent()
        return

    Object.defineProperty @.prototype, propertyName, config

    return


  _defineProperty 'vertexCount', '_persistent'
  _defineProperty 'drawingMode', '_persistent'
  _defineProperty 'debugMode', '_lifetime'
  _defineProperty 'selectedTab', '_transient'

