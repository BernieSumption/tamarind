

VSHADER_SOURCE = """

attribute vec4 a_Position;
uniform float u_PointSize;
uniform sampler2D u_TextureSampler;
varying vec4 v_PointColor;

void main() {
  gl_Position = a_Position;
  gl_PointSize = u_PointSize;

  // v_PointColor = vec4(1.0-abs(a_Position[1]), abs(a_Position[0]), 1.0, 1.0);
  vec2 imageCoords = vec2(a_Position) * .5 + .5; // convert -1..1 to 0..1
  v_PointColor = texture2D(u_TextureSampler, imageCoords);
}

"""

FSHADER_SOURCE = """

precision mediump float;

varying vec4 v_PointColor;

void main() {
  gl_FragColor = v_PointColor;
}

"""





error = (msg) ->
  console.error(msg)
  alert msg



# An object associated wtih a canvas element that manages the WebGL context
# and associated resources
#
class WebGLCanvas

  constructor: (@canvas, @debugMode=false) ->


    @canvas.addEventListener "webglcontextcreationerror", (event) =>
      @trace.error event.statusMessage

    @_createContext()

  _createContext: ->

    @nativeContext = @debugContext = null
    @nativeContext = @canvas.getContext("webgl") || @canvas.getContext("experimental-webgl");
    if @nativeContext
      @debugContext = WebGLDebugUtils.makeDebugContext @nativeContext

    @gl = if @_debugMode then @debugContext else @nativeContext

  setDebugMode: (value) ->
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

  getDebugMode: -> @_debugMode



defineClassProperty(WebGLCanvas, "debugMode")
