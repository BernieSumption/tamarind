

DEFAULT_VSHADER_SOURCE = """

attribute float a_VertexIndex;

void main() {
  gl_Position = vec4(a_VertexIndex, 0, 0, 1);
  gl_PointSize = 10.0;
}

"""

DEFAULT_FSHADER_SOURCE = """

precision mediump float;

void main() {
  gl_FragColor = vec4(gl_PointCoord, 1, 1);
}

"""

VERTEX_INDEX_LOCATION = 0


# An object associated with a canvas element that manages the WebGL context
# and associated resources.
#
# THE RESOURCE MANAGEMENT GRAPH
#
#
#           -- VERT
#         /         \
#  CONTEXT -- FRAG -- LINK -- DATA -- RENDER
#         \                         /
#           -- GEOM ---------------
#
#
# CONTEXT:  create WebGL context
# VERT:     compile vertex shader
# FRAG:     compile fragment shader
# LINK:     link program, look up and cache attribute and uniform locations
# GEOM:     generate vertex buffer with geometry
# DATA:     set values for uniforms and update viewport dimensions if required
# RENDER:   render scene
#
# When the object is first created, each step is performed in dependency order from context creation
# to rendering. Various API methods will invalidate a specific step, requiring that it and all dependent steps
# are cleaned up and done again. For example, changing vertexCount will invalidate the GEOM step which
# requires uniforms to be set again.
#
class WebGLCanvas

  constructor: (@canvas, @debugMode=false, @vertexCount=4) ->

    unless browserSupportsRequiredFeatures()
      throw new Error "This browser does not support WebGL"

    @canvas.addEventListener "webglcontextcreationerror", (event) =>
      @trace.error event.statusMessage

    # @type WebGLRenderingContext
    @gl = null

    @_createContext()

    @_createGeometry()

    @_compileShader(@_vertexShader, DEFAULT_VSHADER_SOURCE)
    @_compileShader(@_fragmentShader, DEFAULT_FSHADER_SOURCE)


    @_linkProgram()

    @_render()

  _render: ->



    @gl.clearColor 0, 0, 0, 1
    @gl.clear @gl.COLOR_BUFFER_BIT
    @gl.drawArrays @gl.POINTS, 0, @vertexCount



  ##
  ## Scene construction functions that implement the resource management graph (see
  ## diagram on class comment)
  ##

  _createContext: ->
    # create the WebGL context
    @nativeContext = @canvas.getContext("webgl") || @canvas.getContext("experimental-webgl");

    # passing undefined as an argument to any WebGL function is an
    # error, so throw an exception to catch it early
    throwErrorOnUndefinedArgument = (functionName, args) ->
      for arg in args
        if arg == undefined
          throw new Error('undefined passed to gl.' + functionName + '(' + WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ')')
      return

    @debugContext = WebGLDebugUtils.makeDebugContext @nativeContext, null, throwErrorOnUndefinedArgument, null

    @gl = gl = if @_debugMode then @debugContext else @nativeContext

    # create all the object
    @_vertexBuffer = gl.createBuffer()
    @_program = gl.createProgram()
    @_vertexShader = gl.createShader(gl.VERTEX_SHADER)
    @_fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)


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
    gl.attachShader @_program, @_vertexShader
    gl.attachShader @_program, @_fragmentShader

    gl.bindAttribLocation(@_program, VERTEX_INDEX_LOCATION, "a_VertexIndex")
    # Link the program object
    gl.linkProgram @_program
    # Check the result of linking
    linked = gl.getProgramParameter(@_program, gl.LINK_STATUS)
    if linked
      @gl.useProgram @_program
    else
      error = gl.getProgramInfoLog(@_program)
      @trace.log 'Failed to link program: ' + error




  _createGeometry: =>

    gl = @gl


    #gl.viewport 0, 0, width, height

    # Create vertex buffer
    vertices = new Float32Array(@vertexCount)
    for i of vertices
      vertices[i] = 0.1 * i

    gl.bindBuffer gl.ARRAY_BUFFER, @_vertexBuffer
    gl.bufferData gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW

    gl.vertexAttribPointer VERTEX_INDEX_LOCATION, 1, gl.FLOAT, false, 0, 0
    gl.enableVertexAttribArray VERTEX_INDEX_LOCATION



  ##
  ## GETTERS AND SETTERS
  ##

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

  _getDebugMode: -> @_debugMode



defineClassProperty(WebGLCanvas, "debugMode")
