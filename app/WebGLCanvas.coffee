

DEFAULT_VSHADER_SOURCE = """
attribute float a_VertexIndex;

void main() {
  gl_Position = vec4(a_VertexIndex * .1, 0, 0, 1);
  gl_PointSize = 10.0;
}
"""

DEFAULT_FSHADER_SOURCE = """
precision mediump float;

void main() {
  gl_FragColor = vec4(gl_PointCoord, 1, 1);
}
"""

VERTEX_INDEX_ATTRIBUTE_LOCATION = 0

VALID_DRAWING_MODES = "POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN".split(",")


# An object associated with a canvas element that manages the WebGL context
# and associated resources.
#
# THE RESOURCE MANAGEMENT GRAPH
#
#
#           -- VERT
#         /         \
#  CONTEXT -- FRAG -- LINK -- RENDER
#         \                 /
#           -- GEOM --------
#
#
# CONTEXT:  set up WebGL context
# VERT:     compile vertex shader
# FRAG:     compile fragment shader
# LINK:     link program, look up and cache attribute and uniform locations
# GEOM:     generate vertex buffer with geometry
# RENDER:   set values for uniforms, update viewport dimensions, render scene
#
# When the object is first created, each step is performed in dependency order from context creation
# to rendering. Various API methods will invalidate a specific step, requiring that it and all dependent steps
# are cleaned up and done again. For example, changing vertexCount will invalidate the GEOM step which
# requires uniforms to be set again.
#
class WebGLCanvas

  constructor: (@canvas, @debugMode=false) ->

    unless browserSupportsRequiredFeatures()
      throw new Error "This browser does not support WebGL"

    @_contextRequiresSetup = true
    @_fragmentShaderIsDirty = false
    @_vertexShaderIsDirty = false
    @_geometryIsDirty = false
    @_renderIsDirty = false

    # The number of vertices drawn
    @vertexCount = 4

    # GLSL source code for the fragment shader
    @fragmentShaderSource = DEFAULT_FSHADER_SOURCE

    # GLSL source code for the vertex shader
    @vertexShaderSource = DEFAULT_VSHADER_SOURCE

    @canvas.addEventListener "webglcontextcreationerror", (event) =>
      @trace.error event.statusMessage

    @_createContext()

    unless @gl
      throw new Error("Could not create WebGL context for canvas")

    # A string mode anme as used by WebGL's drawArrays method, i.e. one of:
    # POINTS, LINES, LINE_LOOP, LINE_STRIP, TRIANGLES, TRIANGLE_STRIP or TRIANGLE_FAN
    @drawingMode = "POINTS"

    @_scheduleFrame()

  _scheduleFrame: ->
    unless @_frameScheduled
      @_frameScheduled = true
      requestAnimationFrame(@_doFrame)

  _doFrame: =>

    @_frameScheduled = false

    if @_contextRequiresSetup
      @_setupContext()
      @_contextRequiresSetup = false

    if @_geometryIsDirty
      @_updateGeometry()
      @_geometryIsDirty = false

    requiresLink = @_vertexShaderIsDirty or @_fragmentShaderIsDirty

    if @_vertexShaderIsDirty
      @_compileShader(@_vertexShader, @vertexShaderSource)
      @_vertexShaderIsDirty = false

    if @_fragmentShaderIsDirty
      @_compileShader(@_fragmentShader, @fragmentShaderSource)
      @_fragmentShaderIsDirty = false

    if requiresLink
      @_linkProgram()

    @_render()



  ##
  ## Functions for each step in the resource management graph (see diagram on class comment)
  ##

  _createContext: ->

    @nativeContext = @canvas.getContext("webgl") || @canvas.getContext("experimental-webgl");

    # passing undefined as an argument to any WebGL function is an
    # error, so throw an exception to catch it early
    throwErrorOnUndefinedArgument = (functionName, args) ->
      for arg in args
        if arg == undefined
          throw new Error('undefined passed to gl.' + functionName + '(' + WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ')')
      return

    @debugContext = WebGLDebugUtils.makeDebugContext @nativeContext, null, throwErrorOnUndefinedArgument, null


    @gl = if @_debugMode then @debugContext else @nativeContext


    @_drawingModeNames = {}
    for mode in VALID_DRAWING_MODES
      intMode = @gl[mode]
      if intMode == undefined
        throw new Error(mode + " is not a valid drawing mode")
      @_drawingModeNames[mode] = intMode
      @_drawingModeNames[intMode] = mode

  _setupContext: ->
    gl = @gl

    # create all the object
    @_vertexBuffer = gl.createBuffer()
    @_program = gl.createProgram()
    @_vertexShader = gl.createShader(gl.VERTEX_SHADER)
    @_fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
    gl.attachShader @_program, @_vertexShader
    gl.attachShader @_program, @_fragmentShader


  _compileShader: (shader, source) ->
    gl = @gl
    gl.shaderSource shader, source
    gl.compileShader shader
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    unless compiled
      error = gl.getShaderInfoLog(shader)
      @trace.log 'Failed to compile shader: ' + error


  _linkProgram: () ->
    gl = @gl
    # Attach the shader objects

    gl.bindAttribLocation(@_program, VERTEX_INDEX_ATTRIBUTE_LOCATION, "a_VertexIndex")
    # Link the program object
    gl.linkProgram @_program
    # Check the result of linking
    linked = gl.getProgramParameter(@_program, gl.LINK_STATUS)
    if linked
      @gl.useProgram @_program
    else
      error = gl.getProgramInfoLog(@_program)
      @trace.log 'Failed to link program: ' + error

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


  _render: ->
    gl = @gl


    width = @canvas.offsetWidth * (window.devicePixelRatio || 1)
    height = @canvas.offsetHeight * (window.devicePixelRatio || 1)

    u_CanvasSize = gl.getUniformLocation(@_program, "u_CanvasSize")
    gl.uniform2f(u_CanvasSize, width, height)


    unless width is @_width and height is @_height

      @_width = @canvas.width = width
      @_height = @canvas.height = height

      gl.viewport 0, 0, width, height



    gl.clearColor 0, 0, 0, 1
    gl.clear gl.COLOR_BUFFER_BIT
    gl.drawArrays @_drawingMode, 0, @vertexCount





  ##
  ## GETTERS AND SETTERS
  ##

  _getFragmentShaderSource: -> @_fragmentShaderSource

  _setFragmentShaderSource: (value) ->
    @_fragmentShaderSource = value
    @_fragmentShaderIsDirty = true
    @_scheduleFrame()


  _getVertexShaderSource: ->
    @_vertexShaderSource

  _setVertexShaderSource: (value) ->
    @_vertexShaderSource = value
    @_vertexShaderIsDirty = true
    @_scheduleFrame()


  _getVertexCount: -> @_vertexCount

  _setVertexCount: (value) ->
    @_vertexCount = value
    @_geometryIsDirty = true
    @_scheduleFrame()


  _getDrawingMode: -> @_drawingModeNames[@_drawingMode]

  _setDrawingMode: (value) ->
    intValue = @gl[value]
    if intValue == undefined
      throw new Error(value + " is not a valid drawing mode.")
    @_drawingMode = intValue
    @_scheduleFrame()


  _getDebugMode: -> @_debugMode

  _setDebugMode: (value) ->
    value = !!value
    if @_debugMode != value
      @_debugMode = value
      if @_debugMode
        @trace = new ConsoleTracer
        @trace.log "Using WebGL API debugging proxy - turn off debug mode for production apps, it hurts performance"
        @gl = @debugContext
      else
        @trace = new NullTracer
        @gl = @debugContext



defineClassProperty(WebGLCanvas, "debugMode")
defineClassProperty(WebGLCanvas, "drawingMode")
defineClassProperty(WebGLCanvas, "vertexCount")
defineClassProperty(WebGLCanvas, "vertexShaderSource")
defineClassProperty(WebGLCanvas, "fragmentShaderSource")
