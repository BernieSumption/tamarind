utils               = require './utils.coffee'
constants           = require './constants.coffee'
WebGLDebugUtils     = require './WebGLDebugUtils.js'
ShaderCompileError  = require './ShaderCompileError.coffee'
Tamarind            = require './Tamarind.coffee'
UIComponent         = require './UIComponent.coffee'

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
class WebGLCanvas extends UIComponent
  
  TEMPLATE = '''
    <canvas class="tamarind-render-canvas"></canvas>
  '''

  VERTEX_INDEX_ATTRIBUTE_LOCATION = 0

  VALID_DRAWING_MODES = 'POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN'.split(',')


  ##
  ## PUBLIC API METHODS
  ##

  # @param [HTMLCanvasElement] @_element the canvas element to render onto
  # @param [State] @state the state object for this canvas, or null to create one
  constructor: (state) ->
    super(state, TEMPLATE)

    unless utils.browserSupportsRequiredFeatures()
      throw new Error 'This browser does not support WebGL'

    @_element.addEventListener 'webglcontextcreationerror', (event) ->
      utils.logInfo event.statusMessage
      return

    @_element.addEventListener 'webglcontextlost', @_handleContextLost
    @_element.addEventListener 'webglcontextrestored', @_handleContextRestored

    @_element.addEventListener 'mousemove', @_handleMouseMove

    @_state.on @_state.CHANGE, @_doFrame

    @_state.onPropertyChange 'inputs', @_setAllUniformsFromState
    @_state.on @_state.INPUT_VALUE_CHANGE, @_setUniformFromState

    @_shaders = {} # OpenGL shader object references

    @_createContext()

    unless @gl
      throw new Error('Could not create WebGL context for canvas')

    @_doFrame()

    return

  _handleMouseMove: (event) =>
    pos = @_element.getBoundingClientRect()
    centreX = pos.left + pos.width / 2
    centreY = pos.top + pos.height / 2
    mouseRelX = event.clientX - centreX
    mouseRelY = event.clientY - centreY
    @_state.mouseX = mouseRelX / pos.width * 2
    @_state.mouseY = -(mouseRelY / pos.height * 2)
    return


  # Simulate GL context loss for debugging
  debugLoseContext: ->
    @_loseContext = @_loseContext or @gl.getExtension('WEBGL_lose_context')
    @_loseContext.loseContext()
    return


  # Simulate GL context restoration for debugging
  debugRestoreContext: ->
    @_loseContext = @_loseContext or @gl.getExtension('WEBGL_lose_context')
    @_loseContext.restoreContext()
    return


  # Take a snapshot of the current scene and return it as a PNG encoded data url
  #
  # @param [int] width the width of the rendered image
  # @param [int] height the height of the rendered image
  captureImage: (width, height) ->
    valid = @_doFrame()
    if valid
      @_render(width, height)
    image = @_element.toDataURL 'image/png'
    if valid
      @_render() # restore previous size

    return image


  ##
  ## PRIVATE METHODS
  ##


  # @private
  _doFrame: =>

    if @_contextLost
      return false

    @_updateContextForDebugMode()

    if @_contextRequiresSetup
      unless @_setupContext()
        return false
      @_contextRequiresSetup = false
      isNewContext = true
    else
      isNewContext = false


    if isNewContext or @_vertexCount isnt @_state.vertexCount
      @_vertexCount = @_state.vertexCount
      unless @_updateGeometry(@_vertexCount)
        return false


    shadersCompiled = true
    for shaderType in [constants.VERTEX_SHADER, constants.FRAGMENT_SHADER]
      if isNewContext or @_shaders[shaderType] is undefined or @gl.getShaderSource(@_shaders[shaderType]) isnt @_state.getShaderSource(shaderType)
        unless @_compileShader(shaderType)
          shadersCompiled = false
        requiresLink = true
    unless shadersCompiled
      return false

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
    @nativeContext = @_element.getContext('webgl', opts) or @_element.getContext('experimental-webgl', opts)

    # passing undefined as an argument to any WebGL function is an
    # error, so throw an exception to catch it early
    onFunctionCall = (functionName, args) ->
      for arg in args
        if arg is undefined
          throw new Error('undefined passed to gl.' + functionName + '(' + WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ')')
      return


    @debugContext = WebGLDebugUtils.makeDebugContext @nativeContext, null, onFunctionCall, null

    @_contextRequiresSetup = true

    @_updateContextForDebugMode()

    return

  _updateContextForDebugMode: =>
    if Tamarind.debugMode
      @gl = @debugContext
    else
      @gl = @nativeContext
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

    source = @_state.getShaderSource(shaderType)

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

    if compiled
      @_state.setShaderErrors shaderType, null, []
    else
      errorText = gl.getShaderInfoLog(shader)
      errors = ShaderCompileError.fromErrorMessage(errorText)
      @_state.setShaderErrors shaderType, errorText, errors
      gl.detachShader(@_program, shader)
      gl.deleteShader(shader)
      delete @_shaders[shaderType]
      return false

    return true


  # @private
  _linkProgram: () ->
    gl = @gl

    gl.bindAttribLocation @_program, VERTEX_INDEX_ATTRIBUTE_LOCATION, 'a_VertexIndex'

    gl.linkProgram @_program

    linked = gl.getProgramParameter(@_program, gl.LINK_STATUS)
    unless linked
      errorText = gl.getProgramInfoLog(@_program).trim()
      error = new ShaderCompileError(errorText, -1)
      @_state.setShaderErrors constants.FRAGMENT_SHADER, errorText, [error]
      @_state.setShaderErrors constants.VERTEX_SHADER, errorText, [error]
      return false

    @_state.setShaderErrors constants.FRAGMENT_SHADER, null, []
    @_state.setShaderErrors constants.VERTEX_SHADER, null, []

    gl.useProgram @_program

    # get and cache a list of uniform names to locations
    numUniforms = gl.getProgramParameter(@_program, gl.ACTIVE_UNIFORMS)
    @_uniformInfoByName = {}
    for i in [0..numUniforms - 1] by 1
      uniform = gl.getActiveUniform(@_program, i)
      @_uniformInfoByName[uniform.name] =
        location: gl.getUniformLocation(@_program, uniform.name)
        type: uniform.type

    @_setAllUniformsFromState()

    return true


  # @private
  _updateGeometry: (vertexCount) ->

    gl = @gl

    # Create vertex buffer
    vertices = new Float32Array(vertexCount)
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


    width = explicitWidth or Math.round(@_element.offsetWidth * (window.devicePixelRatio or 1))
    height = explicitHeight or Math.round(@_element.offsetHeight * (window.devicePixelRatio or 1))

    unless width is @_state.canvasWidth and height is @_state.canvasHeight

      @_state.canvasWidth  = @_element.width = width
      @_state.canvasHeight = @_element.height = height

      gl.viewport 0, 0, width, height


    gl.clearColor 0, 0, 0, 0
    gl.clear gl.COLOR_BUFFER_BIT
    gl.drawArrays gl[@_state.drawingMode], 0, @_state.vertexCount

    return true


  # @private
  _setAllUniformsFromState: =>
    for input in @_state.inputs
      @_setUniformFromState(input.uniformName)

  # @private
  _setUniformFromState: (propertyName) =>
    @_setUniform(propertyName, @_state.getInputValue(propertyName))
    return


  # @private
  _setUniform: (name, values) ->
    gl = @gl

    unless @_uniformInfoByName
      return

    uniformInfo = @_uniformInfoByName[name]

    unless uniformInfo
      return

    switch values.length
      when 1
        gl.uniform1f(uniformInfo.location, values[0])
      when 2
        gl.uniform2f(uniformInfo.location, values[0], values[1])
      when 3
        gl.uniform3f(uniformInfo.location, values[0], values[1], values[2])
      when 4
        gl.uniform4f(uniformInfo.location, values[0], values[1], values[2], values[3])
      else
        throw new Error("Can't set uniform with #{values.length} values")

    return true


  # @private
  _handleContextLost: (e) =>
    utils.logInfo 'WebGL context lost, suspending all GL calls'
    @_contextLost = true
    (e or window.event).preventDefault()

    return


  # @private
  _handleContextRestored: =>
    utils.logInfo 'WebGL context restored, resuming rendering'
    @_contextLost = false
    @_contextRequiresSetup = true
    @_doFrame()

    return



module.exports = WebGLCanvas
