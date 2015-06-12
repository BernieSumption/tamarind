EventEmitter = require './EventEmitter.coffee'

utils = require './utils.coffee'

X_ORIGIN_PROXY_PREFIX = 'http://crossorigin.me/'


# A class that manages the loading an unloading of textures on demand
class TextureLoader extends EventEmitter

  # Event name dispatched when a new texture image has finished loading
  TEXTURE_LOADED: 'textureLoaded'

  # Event name dispatched when the last texture in a batch finishes loading
  ALL_TEXTURES_LOADED: 'allTexturesLoaded'

  constructor: ->
    # map of URL to state. Value is an HTMLImageElement if loading, or an texture handle if loaded
    @_current = {}
    @_factory = new NullFactory()


  # Set the current list of textures. Any new textures not in the previous list will
  # be loaded and created. Any previously loaded textures not in the new list will
  # be destroyed. An ALL_TEXTURES_LOADED event will be dispatched when all activity
  # is complete.
  setTextureUrls: (urls, xOriginProxy = true) ->
    newUrls = []
    for url in urls
      newUrls[url] = url
      unless @_current[url]
        img = document.createElement('img')
        if xOriginProxy
          img.setAttribute('crossorigin', 'anonymous')
          img.src = TextureLoader.wrapInXOriginProxy(url)
        else
          img.src = url
        img.addEventListener 'load', @_handleImageLoad
        img.originalUrl = url
        @_current[url] = {
          img: img,
          handle: null
        }
        unless @_isLoading(url)
          utils.logError('Sanity check failed while loading ' + url)
    for url, state of @_current
      unless newUrls[url]
        if @_isLoading(url)
          state.img.removeEventListener 'load', @_handleImageLoad
        else
          @_factory.destroyTexture state.handle
        delete @_current[url]
    @_scheduleLoadCheck()
    return


  # return the handle associated with a specific texture URL
  getTexture: (url) ->
    return @_current[url]?.handle or null


  # Set the WebGL context on which this TextureLoader will create textures
  # Any existing textures will be recreated on this context
  setWebGLContext: (gl) ->
    @_setFactory new WebGLContextTextureFactory(gl)
    return

  # Given a URL, return a version safe to load in a CORS request
  @wrapInXOriginProxy: (url) ->
    if /^https?:/.test(url) and url.indexOf(X_ORIGIN_PROXY_PREFIX) is -1
      return X_ORIGIN_PROXY_PREFIX + url
    return url


  ##
  ## PRIVATE IMPLEMENTATION DETAILS
  ##


  _handleImageLoad: (event) =>
    url = event.target.originalUrl
    unless @_isLoading(url)
      utils.logError("Expected url to be in loading state: #{url}")
    @_createTexture(url, event.target)
    @emit @TEXTURE_LOADED, url
    @_scheduleLoadCheck()
    return

  _createTexture: (url, imageElement) ->
    @_current[url].handle = @_factory.createTexture(imageElement)
    return

  _scheduleLoadCheck: =>
    if @_loadCheckScheduled
      return
    @_loadCheckScheduled = true
    requestAnimationFrame =>
      @_loadCheckScheduled = false
      if @_allImagesLoaded()
        @emit @ALL_TEXTURES_LOADED
      return
    return

  _allImagesLoaded: =>
    for k of @_current
      if @_isLoading(k)
        return false
    return true

  _isLoading: (url) ->
    return @_current[url]?.handle is null



  _setFactory: (factory) ->
    @_factory = factory
    for url, state of @_current
      unless @_isLoading(url)
        @_createTexture(url, state.img)

    return


module.exports = TextureLoader


# Prevent null pointer errors before the first real factory is set
class NullFactory

  createTexture: (image) ->
    return 'dummy-handle'

  destroyTexture: (handle) ->
    return



# Create and destroy textures in a WebGL context
class WebGLContextTextureFactory

  constructor: (@gl) ->

# Create a texture and return a handle that can be used later to destroy it
# @param image [HTMLImageElement] the image data. It must have loaded.
  createTexture: (image) ->
    gl = @gl
    texture = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, texture
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
    gl.bindTexture gl.TEXTURE_2D, null
    return texture

# Destroy a previously created texture
# @param texture [object] a texture as returned by
  destroyTexture: (handle) ->
    return