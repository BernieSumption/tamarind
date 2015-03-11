

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

  VSHADER_HEADER = '''
attribute float a_VertexIndex;
'''

  DEFAULT_VSHADER_SOURCE = '''
void main() {
  // 4 points, one in each corner, clockwise from top left
  if (a_VertexIndex == 0.0) {
    gl_Position.xy = vec2(-1, -1);
  } else if (a_VertexIndex == 1.0) {
    gl_Position.xy = vec2(1, -1);
  } else if (a_VertexIndex == 2.0) {
    gl_Position.xy = vec2(1, 1);
  } else if (a_VertexIndex == 3.0) {
    gl_Position.xy = vec2(-1, 1);
  } else {
    gl_Position.xy = vec2(0);
  }
}
'''

  FSHADER_HEADER = '''
precision mediump float;
uniform vec2 u_CanvasSize;
'''

  DEFAULT_FSHADER_SOURCE = '''
void main() {
  gl_FragColor.r = u_CanvasSize.x;
  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);
}
'''

  VSHADER_HEADER_SIZE = VSHADER_HEADER.split('\n').length
  FSHADER_HEADER_SIZE = FSHADER_HEADER.split('\n').length

  VERTEX_INDEX_ATTRIBUTE_LOCATION = 0

  VALID_DRAWING_MODES = 'POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN'.split(',')

  SET_UNIFORM_FUNCTION_NAMES = [null, 'uniform1f', 'uniform2f', 'uniform3f', 'uniform4f']

  # Event name for compilation error events
  # @example
  #     canvas.on WebGLCanvas.COMPILE, (event) -> console.log event
  @COMPILE = 'compile'

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

  # @property [string] GLSL source code for the fragment shader, excluding
  # attribute and uniform definitions which will be added automatically
  fragmentShaderSource: DEFAULT_FSHADER_SOURCE

  # @property [string] GLSL source code for the vertex shader, excluding
  # attribute and uniform definitions which will be added automatically
  vertexShaderSource: DEFAULT_VSHADER_SOURCE

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

    unless browserSupportsRequiredFeatures()
      throw new Error 'This browser does not support WebGL'

    @canvasElement.addEventListener 'webglcontextcreationerror', (event) =>
      @trace.error event.statusMessage
      return

    @canvasElement.addEventListener 'webglcontextlost', @_handleContextLost
    @canvasElement.addEventListener 'webglcontextrestored', @_handleContextRestored

    @_shaders = {}

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
      return

    if @_contextRequiresSetup
      unless @_setupContext()
        return
      @_contextRequiresSetup = false
      @_vertexShaderIsDirty = @_fragmentShaderIsDirty = @_geometryIsDirty = true

    if @_geometryIsDirty
      unless @_updateGeometry()
        return
      @_geometryIsDirty = false

    requiresLink = @_vertexShaderIsDirty or @_fragmentShaderIsDirty

    if @_vertexShaderIsDirty
      unless @_compileShader(Tamarind.VERTEX_SHADER, VSHADER_HEADER + @vertexShaderSource, VSHADER_HEADER_SIZE)
        return
      @_vertexShaderIsDirty = false

    if @_fragmentShaderIsDirty
      unless @_compileShader(Tamarind.FRAGMENT_SHADER, FSHADER_HEADER + @fragmentShaderSource, FSHADER_HEADER_SIZE)
        return
      @_fragmentShaderIsDirty = false

    if requiresLink
      unless @_linkProgram()
        return

    @_render()

    return



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
  _compileShader: (shaderType, source, headerSize) ->

    gl = @gl

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
    @emit WebGLCanvas.COMPILE, new CompileStatus(shaderType, error, headerSize)

    return compiled


  # @private
  _linkProgram: () ->
    gl = @gl


    gl.bindAttribLocation @_program, VERTEX_INDEX_ATTRIBUTE_LOCATION, 'a_VertexIndex'

    gl.linkProgram @_program

    linked = gl.getProgramParameter(@_program, gl.LINK_STATUS)
    unless linked
      error = gl.getProgramInfoLog(@_program)
      @trace.log 'Failed to link program: ' + error
      return false

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
    @_doFrame()
    @_render(width, height)
    image = @canvasElement.toDataURL 'image/png'
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

  # @private
  _getFragmentShaderSource: -> @_fragmentShaderSource

  # @private
  _setFragmentShaderSource: (value) ->
    @_fragmentShaderSource = value
    @_fragmentShaderIsDirty = true
    @_scheduleFrame()

    return


  # @private
  _getVertexShaderSource: -> @_vertexShaderSource

  # @private
  _setVertexShaderSource: (value) ->
    @_vertexShaderSource = value
    @_vertexShaderIsDirty = true
    @_scheduleFrame()

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
    unless @_debugMode is value
      @_debugMode = value
      if @_debugMode
        @trace = new ConsoleTracer
        @trace.log 'Using WebGL API debugging proxy - turn off debug mode for production apps, it hurts performance'
        @gl = @debugContext
      else
        @trace = new NullTracer
        @gl = @debugContext

    return


defineClassProperty(WebGLCanvas, 'debugMode')
defineClassProperty(WebGLCanvas, 'drawingMode')
defineClassProperty(WebGLCanvas, 'vertexCount')
defineClassProperty(WebGLCanvas, 'vertexShaderSource')
defineClassProperty(WebGLCanvas, 'fragmentShaderSource')


class CompileStatus

  # @property [array] an array of error objects like {message, severity ('warning' | 'error'), line}
  errors: []

  constructor: (@shaderType, error, headerSize) ->

    @errors = []

    if error

      for line in error.split('\n')

        parts = /ERROR:\s*(\d+)\s*:\s*(\d+)\s*:\s*(.*)/.exec(line)

        if parts
          line = parseInt(parts[2])
          @errors.push(
            message: parts[3]
            line: line - headerSize
          )

  toString: ->
    return "CompileStatus('#{@shaderType}', [#{@errors.length} errors])"