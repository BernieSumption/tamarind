utils               = require './utils.coffee'
constants           = require './constants.coffee'
WebGLDebugUtils     = require './WebGLDebugUtils.js'
ShaderCompileError  = require './ShaderCompileError.coffee'
Tamarind            = require './Tamarind.coffee'
UIComponent         = require './UIComponent.coffee'
TextureLoader       = require './TextureLoader.coffee'

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

    @_state.onPropertyChange 'inputs', @_handleInputsChange
    @_state.on @_state.INPUT_VALUE_CHANGE, @_handleInputValueChange

    @_shaders = {} # OpenGL shader object references

    @_textureLoader = new TextureLoader()
    @_textureLoader.on @_textureLoader.ALL_TEXTURES_LOADED, @_handleTexturesLoaded

    @_currentShaderSource = state.shaderSource

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

    isNewContext = false

    if @_contextRequiresSetup
      unless @_setupContext()
        return false
      @_contextRequiresSetup = false
      isNewContext = true


    if isNewContext or @_vertexCount isnt @_state.vertexCount
      @_vertexCount = @_state.vertexCount
      unless @_updateGeometry(@_vertexCount)
        return false

    if isNewContext or @_currentShaderSource isnt @_state.shaderSource or not (@_shaders.VERTEX_SHADER and @_shaders.FRAGMENT_SHADER)
      @_currentShaderSource isnt @_state.shaderSource

      @_state.setShaderErrors null, []
      unless @_compileShader("VERTEX_SHADER") and @_compileShader("FRAGMENT_SHADER")
        return false

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

    @_textureLoader.setWebGLContext gl

    @_shaders = {}

    unless @_vertexBuffer = gl.createBuffer()
      return false

    return true


  # @private
  _compileShader: (shaderType) ->

    gl = @gl

    source = @_state.shaderSource
    if shaderType is 'FRAGMENT_SHADER'
      source = '#define FRAGMENT\n' + source
    else if shaderType is 'VERTEX_SHADER'
      source = '#define VERTEX\n' + source

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

    unless compiled
      errorText = gl.getShaderInfoLog(shader)
      errors = ShaderCompileError.fromErrorMessage(errorText)
      @_state.setShaderErrors errorText, errors
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
      @_state.setShaderErrors errorText, [error]
      return false

    @_state.setShaderErrors null, []

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
    @_updateTextures()

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

  _handleInputsChange: =>
    @_setAllUniformsFromState()
    @_updateTextures()
    return

  _handleInputValueChange: (propertyName) =>
    @_setUniformFromState(propertyName)
    input = @_state.getInputByName(propertyName)
    if input.uniformType is 'sampler2D'
      @_updateTextures()
    return

  # @private
  _setAllUniformsFromState: =>
    for input in @_state.inputs
      @_setUniformFromState(input.uniformName)
    return

  # @private
  _setUniformFromState: (propertyName) =>
    @_setUniform(propertyName, @_state.getInputValue(propertyName))
    return

  # @private
  _updateTextures: =>
    urls = []
    for input in @_state.inputs
      if input.uniformType is 'sampler2D'
        urls.push(@_state.getInputValue(input.uniformName)[0])
    @_textureLoader.setTextureUrls urls
    return

  _handleTexturesLoaded: =>
    for input in @_state.inputs
      if input.uniformType is 'sampler2D'
        @_setUniformFromState(input.uniformName)
    @_doFrame()
    return

  # @private
  _setUniform: (name, values) ->
    gl = @gl

    unless @_uniformInfoByName
      return

    uniformInfo = @_uniformInfoByName[name]

    unless uniformInfo
      return

    switch uniformInfo.type
      when gl.FLOAT
        gl.uniform1fv(uniformInfo.location, values)
      when gl.FLOAT_VEC2
        gl.uniform2fv(uniformInfo.location, values)
      when gl.FLOAT_VEC3
        gl.uniform3fv(uniformInfo.location, values)
      when gl.FLOAT_VEC4
        gl.uniform4fv(uniformInfo.location, values)
      when gl.SAMPLER_2D
        handle = @_textureLoader.getTexture values[0]
        if handle
          gl.activeTexture(gl.TEXTURE0)
          gl.bindTexture(gl.TEXTURE_2D, handle)
          gl.uniform1i(uniformInfo.location, 0)
      else
        throw new Error("Can't set uniform of type #{uniformInfo.type}")

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
