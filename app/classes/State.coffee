

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


  constructor: ->
    @_state = {
      FRAGMENT_SHADER: Tamarind.DEFAULT_FSHADER_SOURCE
      VERTEX_SHADER: Tamarind.DEFAULT_VSHADER_SOURCE
      vertexCount: 4
      drawingMode: 'TRIANGLE_FAN'
    }
    @_transientState = @_makeDefaultTransientState()

  # Get the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderSource: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_state[shaderType]


  # Set the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param value GLSL source code for the shader
  setShaderSource: (shaderType, value) ->
    @_validateShaderType(shaderType)
    @_validateType(value, 'string', 'shaderType')
    if @_state[shaderType] isnt value
      @_state[shaderType] = value
      @emit @SHADER_CHANGE, shaderType
      @_scheduleChangeEvent()
    return


  # Get the list of Tamarind.ShaderError error objects for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderErrors: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_transientState.shaders[shaderType].errors.slice()


  # Set the list of errors for a shader
  # @param shaderType [string] either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param errorText [String] the error text returned by the browser, used for the purposes of checking if the errors have changed
  # @param errors [number] an array of ShaderError objects
  setShaderErrors: (shaderType, errorText, errors) ->
    @_validateShaderType(shaderType)
    if @_transientState.shaders[shaderType].errorText isnt errorText
      @_transientState.shaders[shaderType].errorText = errorText
      @_transientState.shaders[shaderType].errors = errors
      @emit @SHADER_ERRORS_CHANGE, shaderType

    return




  # Serialise this object as a JSON string
  save: ->
    return JSON.stringify @_state

  # receive notifications when a specific property changes
  onPropertyChange: (propertyName, callback) ->
    if @[propertyName] is undefined
      throw new Error("Invalid property name '#{propertyName}'")
    @on propertyName + 'Change', callback
    #TODO cache names
    return

  # Restore this object from a previously saved
  restore: (saved) ->
    for key, value of JSON.parse(saved)
      if key is Tamarind.FRAGMENT_SHADER or key is Tamarind.VERTEX_SHADER
        @setShaderSource key, value
      else
        @[key] = value
    @_transientState = @_makeDefaultTransientState()
    return



  _scheduleChangeEvent: ->
    unless @_changeEventScheduled
      @_changeEventScheduled = true
      requestAnimationFrame =>
        @emit @CHANGE
        return
    return
  

  _validateShaderType: (shaderType) ->
    if @_state[shaderType] is undefined
      throw new Error("Invalid shader type: #{shaderType}")

  _validateType: (actualValue, expectedType, propertyName) ->
    unless typeof actualValue is expectedType
      throw new Error("Can't set '#{propertyName}' to '#{actualValue}': expected a '#{expectedType}'")


  _makeDefaultTransientState: ->
    return {
      shaders:
        FRAGMENT_SHADER:
          errors: []
          errorText: []
        VERTEX_SHADER:
          errors: []
          errorText: [],
      selectedTab: Tamarind.FRAGMENT_SHADER,
      debugMode: false
    }



  # define a read/write property that maps to getProperty and setProperty
  _defineProperty = (propertyName, storage) =>

    config =
      enumerable: true
      get: -> @[storage][propertyName]
      set: (value) ->
        @_validateType(value, typeof @[storage][propertyName], propertyName)
        if @[storage][propertyName] isnt value
          @[storage][propertyName] = value
          @emit @PROPERTY_CHANGE, propertyName
          @emit propertyName + 'Change', value
          @_scheduleChangeEvent()
        return

    Object.defineProperty @.prototype, propertyName, config

    return

  _defineProperty 'vertexCount', '_state'
  _defineProperty 'drawingMode', '_state'
  _defineProperty 'debugMode', '_transientState'
  _defineProperty 'selectedTab', '_transientState'

