

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

  # @property [string] Name of event emitted when shaders change. The shader type will be the event argument.
  SHADER_CHANGE: 'shaderChange'

  # @property [string] Name of event emitted when a top level property like vertexCount changes. The property name will be the event argument.
  PROPERTY_CHANGE: 'propertyChange'

  # @property [string] Name of event emitted when shaders change. The shader type will be the event argument.
  SHADER_ERRORS_CHANGE: 'shaderErrorsChange'


  constructor: ->
    @_state = {
      FRAGMENT_SHADER: Tamarind.DEFAULT_FSHADER_SOURCE
      VERTEX_SHADER: Tamarind.DEFAULT_VSHADER_SOURCE
      vertexCount: 4
      drawingMode: 'TRIANGLE_FAN'
      debugMode: false
    }
    @_shaderErrors = {
      FRAGMENT_SHADER: []
      VERTEX_SHADER: []
    }


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
    return


  # Get the list of Tamarind.ShaderError error objects for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderErrors: (shaderType) ->
    @_validateShaderType(shaderType)
    return @_shaderErrors[shaderType].slice()


  # Set the list of errors for a shader
  # @param shaderType [string] either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param value [array] list of Tamarind.ShaderError objects
  setShaderErrors: (shaderType, value) ->
    @_validateShaderType(shaderType)
    @_shaderErrors[shaderType] = value.slice()
    @emit @SHADER_ERRORS_CHANGE, shaderType
    return


  # Serialise this object as a JSON string
  save: ->
    return JSON.stringify @_state


  # Restore this object from a previously saved
  restore: (saved) ->
    for key, value of JSON.parse(saved)
      if key is Tamarind.FRAGMENT_SHADER or key is Tamarind.VERTEX_SHADER
        @setShaderSource key, value
      else
        @_setProperty key, value

  # @private
  _getProperty: (propertyName) -> @_state[propertyName]

  # @private
  _setProperty: (propertyName, value) ->
    @_validateType(value, typeof @_state[propertyName], propertyName)
    if @_state[propertyName] isnt value
      @_state[propertyName] = value
      @emit @PROPERTY_CHANGE, propertyName
    return

  _validateShaderType: (shaderType) ->
    if @_state[shaderType] is undefined
      throw new Error("Invalid shader type: #{shaderType}")

  _validateType: (actualValue, expectedType, propertyName) ->
    unless typeof actualValue is expectedType
      throw new Error("Can't set '#{propertyName}' to '#{actualValue}': expected a '#{expectedType}'")



  # define a read/write property that maps to getProperty and setProperty
  defineProperty = (name) =>

    config =
      enumerable: true
      get: -> @_getProperty(name)
      set: (value) ->
        @_setProperty(name, value)
        return

    Object.defineProperty @.prototype, name, config

    return

  defineProperty 'vertexCount'
  defineProperty 'drawingMode'
  defineProperty 'debugMode'

