

###
  An object associated with a canvas element that manages the WebGL context
  and associated resources.

  THE RESOURCE MANAGEMENT GRAPH


             -- VERT
           /         \
    CONTEXT -- FRAG -- LINK -- RENDER
           \                 /
             -- GEOM --------


  1. CONTEXT:  set up WebGL context
  2. VERT:     compile vertex shader
  3. FRAG:     compile fragment shader
  4. LINK:     link program, look up and cache attribute and uniform locations
  5. GEOM:     generate vertex buffer with geometry
  6. RENDER:   set values for uniforms, update viewport dimensions, render scene

  When the object is first created, each step is performed in dependency order from context creation
  to rendering. Various API methods will invalidate a specific step, requiring that it and all dependent steps
  are cleaned up and done again. For example, changing vertexCount will invalidate the GEOM step which
  requires uniforms to be set again.
###
class WebGLCanvas extends EventEmitter

  @DEFAULT_VSHADER_SOURCE = '''
attribute float a_VertexIndex;
varying vec2 position;

void main() {
  // this is the default vertex shader. It positions 4 points, one in each corner clockwise from top left, creating a rectangle that fills the whole canvas.
  if (a_VertexIndex == 0.0) {
    position = vec2(-1, -1);
  } else if (a_VertexIndex == 1.0) {
    position = vec2(1, -1);
  } else if (a_VertexIndex == 2.0) {
    position = vec2(1, 1);
  } else if (a_VertexIndex == 3.0) {
    position = vec2(-1, 1);
  } else {
    position = vec2(0);
  }
  gl_Position.xy = position;
}
'''


  @DEFAULT_FSHADER_SOURCE = '''
precision mediump float;
uniform vec2 u_CanvasSize;
varying vec2 position;

void main() {
  gl_FragColor = vec4(position, 1, 1);
}
'''

  VERTEX_INDEX_ATTRIBUTE_LOCATION = 0

  VALID_DRAWING_MODES = 'POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN'.split(',')

  SET_UNIFORM_FUNCTION_NAMES = [null, 'uniform1f', 'uniform2f', 'uniform3f', 'uniform4f']

  # Event name for compilation events. The event argument is a CompileStatus object
  @COMPILE = 'compile'

  # Event name for compilation error events. The event argument is `false` if there was no error or
  # an error message if there was an error.
  @LINK = 'link'

  ##
  ## PUBLIC MEMBER PROPERTIES
  ##


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

  ##
  ## PUBLIC API METHODS
  ##

  # @param [HTMLCanvasElement] @@canvasElement the canvas element to render onto
  # @param [boolean] @debugMode the initial value of the `debugMode` property
  constructor: (@canvasElement, @debugMode = false) ->

    unless Tamarind.browserSupportsRequiredFeatures()
      throw new Error 'This browser does not support WebGL'

    @canvasElement.addEventListener 'webglcontextcreationerror', (event) =>
      @trace.error event.statusMessage
      return

    @canvasElement.addEventListener 'webglcontextlost', @_handleContextLost
    @canvasElement.addEventListener 'webglcontextrestored', @_handleContextRestored

    @_shaders = {} # OpenGL shader object references
    @_shaderSources = {} # GLSL source code
    @_shaderSources[Tamarind.FRAGMENT_SHADER] = WebGLCanvas.DEFAULT_FSHADER_SOURCE
    @_shaderSources[Tamarind.VERTEX_SHADER] = WebGLCanvas.DEFAULT_VSHADER_SOURCE
    @_shaderDirty = {} # boolean flag indicating source has changed

    @_createContext()

    unless @gl
      throw new Error('Could not create WebGL context for canvas')

    @drawingMode = 'TRIANGLE_FAN'

    @_scheduleFrame()

    return


  ##
  ## PRIVATE METHODS
  ##


  # @private
  _scheduleFrame: ->
    unless @_frameScheduled
      @_frameScheduled = true
      requestAnimationFrame @_doFrame

    return

  # @private
  _doFrame: =>

    @_frameScheduled = false

    if @_contextLost
      return false

    isNewContext = @_contextRequiresSetup

    if @_contextRequiresSetup
      unless @_setupContext()
        return false
      @_contextRequiresSetup = false


    if @_geometryIsDirty or isNewContext
      unless @_updateGeometry()
        return false
      @_geometryIsDirty = false

    for shaderType in [Tamarind.VERTEX_SHADER, Tamarind.FRAGMENT_SHADER]
      if @_shaderDirty[shaderType] or isNewContext
        unless @_compileShader(shaderType)
          return false
        @_shaderDirty[shaderType]
        requiresLink = true

    if requiresLink
      unless @_linkProgram()
        return false

    return @_render()



  #
  # Functions for each step in the resource management graph (see diagram on class comment)
  #

  # @private
  _createContext: ->
    opts = {premultipliedAlpha: false}
    @nativeContext = @canvasElement.getContext('webgl', opts) or @canvasElement.getContext('experimental-webgl', opts)

    # passing undefined as an argument to any WebGL function is an
    # error, so throw an exception to catch it early
    onFunctionCall = (functionName, args) ->
      for arg in args
        if arg is undefined
          throw new Error('undefined passed to gl.' + functionName + '(' + WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ')')
      return


    @debugContext = WebGLDebugUtils.makeDebugContext @nativeContext, null, onFunctionCall, null

    @_contextRequiresSetup = true

    @gl = if @_debugMode then @debugContext else @nativeContext


    @_drawingModeNames = {}
    for mode in VALID_DRAWING_MODES
      intMode = @gl[mode]
      if intMode is undefined
        throw new Error(mode + ' is not a valid drawing mode')
      @_drawingModeNames[intMode] = mode

    return


  # @private
  _setupContext: ->
    gl = @gl

    unless @_program = gl.createProgram()
      return false

    @_shaders = {}

    unless @_vertexBuffer = gl.createBuffer()
      return false

    return true


  # @private
  _compileShader: (shaderType) ->

    gl = @gl

    source = @_shaderSources[shaderType]

    oldShader = @_shaders[shaderType]

    if oldShader
      # Note - deliberately not reusing shader objects. According to the spec we should be able to
      # reuse a shader object for compiling new source, but a Firefox bug makes gl.getShaderParameter
      # unreliable except on the first use of a shader object
      gl.detachShader(@_program, oldShader)
      gl.deleteShader(oldShader)


    @_shaders[shaderType] = shader = gl.createShader(gl[shaderType])

    unless shader
      return false

    gl.attachShader @_program, shader

    gl.shaderSource shader, source
    gl.compileShader shader
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS)

    error = if compiled then null else gl.getShaderInfoLog(shader)
    @emit WebGLCanvas.COMPILE, new CompileStatus(shaderType, error)

    return compiled


  # @private
  _linkProgram: () ->
    gl = @gl

    gl.bindAttribLocation @_program, VERTEX_INDEX_ATTRIBUTE_LOCATION, 'a_VertexIndex'

    gl.linkProgram @_program

    linked = gl.getProgramParameter(@_program, gl.LINK_STATUS)
    unless linked
      @emit WebGLCanvas.LINK, gl.getProgramInfoLog(@_program).trim()
      return false

    @emit WebGLCanvas.LINK, false

    gl.useProgram @_program

    # get and cache a list of uniform names to locations
    numUniforms = gl.getProgramParameter(@_program, gl.ACTIVE_UNIFORMS)
    @_uniformInfoByName = {}
    for i in [0..numUniforms - 1] by 1
      uniform = gl.getActiveUniform(@_program, i)
      @_uniformInfoByName[uniform.name] =
        location: gl.getUniformLocation(@_program, i)
        type: uniform.type

    return true


  # @private
  _updateGeometry: ->

    gl = @gl

    # Create vertex buffer
    vertices = new Float32Array(@vertexCount)
    for i of vertices
      vertices[i] = i

    gl.bindBuffer gl.ARRAY_BUFFER, @_vertexBuffer
    gl.bufferData gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW

    gl.vertexAttribPointer VERTEX_INDEX_ATTRIBUTE_LOCATION, 1, gl.FLOAT, false, 0, 0
    gl.enableVertexAttribArray VERTEX_INDEX_ATTRIBUTE_LOCATION

    return true


  # @private
  _render: (explicitWidth, explicitHeight) ->
    gl = @gl


    width = explicitWidth or Math.round(@canvasElement.offsetWidth * (window.devicePixelRatio or 1))
    height = explicitHeight or Math.round(@canvasElement.offsetHeight * (window.devicePixelRatio or 1))

    @_setUniform 'u_CanvasSize', width, height

    unless width is @_width and height is @_height

      @_width = @canvasElement.width = width
      @_height = @canvasElement.height = height

      gl.viewport 0, 0, width, height



    gl.clearColor 0, 0, 0, 0
    gl.clear gl.COLOR_BUFFER_BIT
    gl.drawArrays @_drawingMode, 0, @vertexCount

    return true


  # Take a snapshot of the current scene and return it as a PNG encoded data url
  #
  # @param [int] width the width of the rendered image
  # @param [int] height the height of the rendered image
  captureImage: (width, height) ->
    valid = @_doFrame()
    if valid
      @_render(width, height)
    image = @canvasElement.toDataURL 'image/png'
    if valid
      @_render() # restore previous size

    return image


  # @private
  _setUniform: (name, args...) ->
    gl = @gl
    uniformInfo = @_uniformInfoByName[name]

    unless uniformInfo
      return false

    uniformInfo.location = gl.getUniformLocation(@_program, 'u_CanvasSize')

    f = SET_UNIFORM_FUNCTION_NAMES[args.length]
    unless f
      throw new Error("Can't set uniform with #{args.length} values")

    gl[f](uniformInfo.location, args...)

    return true


  # @private
  _handleContextLost: (e) =>
    @trace.log 'WebGL context lost, suspending all GL calls'
    @_contextLost = true
    (e or window.event).preventDefault()

    return


  # @private
  _handleContextRestored: =>
    @trace.log 'WebGL context restored, resuming rendering'
    @_contextLost = false
    @_contextRequiresSetup = true
    @_scheduleFrame()

    return


  ##
  ## GETTERS AND SETTERS
  ##

  # Get the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  getShaderSource: (shaderType) -> @_shaderSources[shaderType]

  # Set the source code for a shader
  # @param shaderType either Tamarind.VERTEX_SHADER or Tamarind.FRAGMENT_SHADER
  # @param value GLSL source code for the shader
  setShaderSource: (shaderType, value) ->
    @_shaderSources[shaderType] = value
    @_shaderDirty[shaderType] = true
    @_scheduleFrame()

    return


  # @private
  _getFragmentShaderSource: -> @getShaderSource(Tamarind.FRAGMENT_SHADER)

  # @private
  _setFragmentShaderSource: (value) ->
    @setShaderSource(Tamarind.FRAGMENT_SHADER, value)

    return


  # @private
  _getVertexShaderSource: -> @getShaderSource(Tamarind.VERTEX_SHADER)

  # @private
  _setVertexShaderSource: (value) ->
    @setShaderSource(Tamarind.VERTEX_SHADER, value)

    return

  # @private
  _getVertexCount: -> @_vertexCount

  # @private
  _setVertexCount: (value) ->
    @_vertexCount = value
    @_geometryIsDirty = true
    @_scheduleFrame()

    return


  # @private
  _getDrawingMode: -> @_drawingModeNames[@_drawingMode]

  # @private
  _setDrawingMode: (value) ->
    intValue = @gl[value]
    if intValue is undefined
      throw new Error(value + ' is not a valid drawing mode.')
    @_drawingMode = intValue
    @_scheduleFrame()

    return


  # @private
  _getDebugMode: -> @_debugMode

  # @private
  _setDebugMode: (value) ->
    value = !!value
    if @_debugMode isnt value or not @trace
      @_debugMode = value
      if @_debugMode
        @trace = new ConsoleTracer
        @trace.log 'Using WebGL API debugging proxy - turn off debug mode for production apps, it hurts performance'
        @gl = @debugContext
      else
        @trace = new NullTracer
        @gl = @debugContext

    return


Tamarind.defineClassProperty(WebGLCanvas, 'debugMode')
Tamarind.defineClassProperty(WebGLCanvas, 'drawingMode')
Tamarind.defineClassProperty(WebGLCanvas, 'vertexCount')
Tamarind.defineClassProperty(WebGLCanvas, 'vertexShaderSource')
Tamarind.defineClassProperty(WebGLCanvas, 'fragmentShaderSource')


class CompileStatus

  # @property [array] an array of error objects like {message, severity ('warning' | 'error'), line}
  errors: []

  constructor: (@shaderType, error) ->

    @errors = []

    if error

      for line in error.split('\n')

        parts = /^ERROR:\s*\d+\s*:\s*(\d+|\?)\s*:\s*(.*)/.exec(line) or /^\((\d+),\s*\d+\):\s*(.*)/.exec(line)

        if parts
          line = parseInt(parts[1]) or 0
          @errors.push(
            message: parts[2]
            line: line - 1 # GLSL lines are 1 indexed, CodeMirror expects 0 indexed
          )

  toString: ->
    return "CompileStatus('#{@shaderType}', [#{@errors.length} errors])"