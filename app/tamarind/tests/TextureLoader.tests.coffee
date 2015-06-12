TextureLoader         = require '../TextureLoader.coffee'

{expectCallHistory, eventHandlerChain} = require('./testutils.coffee')

# A 10 x 10 100% red image data URL
RED_IMAGE   = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYV2P8z8Dwn4EIwDiqEF8oUT94AGX8E/dUtCYYAAAAAElFTkSuQmCC'
GREEN_IMAGE = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYV2Nk+M/wn4EIwDiqEF8oUT94AFwGE/dlgCp/AAAAAElFTkSuQmCC'
BLUE_IMAGE  = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYV2NkYPj/n4EIwDiqEF8oUT94AFIQE/cCn90IAAAAAElFTkSuQmCC'
INTERNET_IMAGE_50x60 = 'http://placehold.it/50x60'

describe 'TextureLoader', ->

  makeTextureLoader = ->
    tl = new TextureLoader()
    mtf = new MockTextureFactory()
    spyOn(mtf, 'createTexture').and.callThrough()
    spyOn(mtf, 'destroyTexture').and.callThrough()
    tl._setFactory mtf
    return [tl, mtf]


  it 'should load images and register them with the factory', (done) ->
    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, BLUE_IMAGE, RED_IMAGE] # duplicates in input should be removed

    expect(factory._current).toEqual []

    tl.on tl.ALL_TEXTURES_LOADED, ->
      expect(factory.createTexture.calls.count()).toEqual 2
      expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(BLUE_IMAGE)]

      done()
      return

    return

  it 'should dispatch an ALL_TEXTURES_LOADED event on any setTextureUrls, even if no textures had to be loaded', (done) ->
    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls []

    tl.on tl.ALL_TEXTURES_LOADED, ->
      done()
      return

    return

  it 'should only register an image the first time it is required', (done) ->

    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE]
    eventHandlerChain tl, tl.ALL_TEXTURES_LOADED, [
      ->
        expect(factory.createTexture.calls.count()).toEqual 1
        expect(factory._current).toEqual [handleTo(RED_IMAGE)]
        tl.setTextureUrls [RED_IMAGE]
        return

      ->
        expect(factory._current).toEqual [handleTo(RED_IMAGE)]
        expect(factory.createTexture.calls.count()).toEqual 1 # not called again

        done()
        return
    ]

    return


  it 'should destroy a loaded texture when no longer required', (done) ->
    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, BLUE_IMAGE]


    eventHandlerChain tl, tl.ALL_TEXTURES_LOADED, [
      ->
        expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(BLUE_IMAGE)]
        tl.setTextureUrls [RED_IMAGE, GREEN_IMAGE]
        return

      ->
        expectCallHistory factory.destroyTexture, [handleTo(BLUE_IMAGE)]
        expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(GREEN_IMAGE)]
        done()
        return
    ]

    return


  it 'should cancel the loading of a texture if removed before it loads', (done) ->
    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, BLUE_IMAGE]
    tl.setTextureUrls [RED_IMAGE]


    tl.on tl.ALL_TEXTURES_LOADED, ->
      expect(factory.destroyTexture.calls.count()).toEqual 0
      expect(factory._current).toEqual [handleTo(RED_IMAGE)]
      done()
      return

    return



  it 'should correctly report the texture for a given image', (done) ->
    [tl, factory] = makeTextureLoader()

    expect(tl.getTexture RED_IMAGE).toBeNull() # null before request

    tl.setTextureUrls [RED_IMAGE]

    expect(tl.getTexture RED_IMAGE).toBeNull() # null while loading

    tl.on tl.ALL_TEXTURES_LOADED, ->

      expect(tl.getTexture RED_IMAGE).toEqual handleTo(RED_IMAGE) # image handle after

      done()
      return

    return



  it 'should recreate all textures when the factory is changed', (done) ->
    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, BLUE_IMAGE]

    tl.on tl.ALL_TEXTURES_LOADED, ->
      expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(BLUE_IMAGE)]
      factory = new MockTextureFactory()
      expect(factory._current).toEqual []
      tl._setFactory factory
      expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(BLUE_IMAGE)]
      done()
      return

    return

  it 'should allow textures to be loaded with no factory set, and then applied to the first factory', (done) ->
    tl = new TextureLoader()

    tl.setTextureUrls [RED_IMAGE, BLUE_IMAGE]

    tl.on tl.ALL_TEXTURES_LOADED, ->
      factory = new MockTextureFactory()
      tl._setFactory factory
      expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(BLUE_IMAGE)]
      done()
      return

    return


  it 'should silently reject images that fail due to X-Origin limitations', (done) ->

    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, INTERNET_IMAGE_50x60], false

    tl.on tl.ALL_TEXTURES_LOADED, ->
      expect(factory._current).toEqual [handleTo(RED_IMAGE)]
      done()
      return

    return


  it 'should load arbitrary images, even across X-Origin boundaries', (done) ->

    [tl, factory] = makeTextureLoader()

    tl.setTextureUrls [RED_IMAGE, INTERNET_IMAGE_50x60]

    tl.on tl.ALL_TEXTURES_LOADED, ->
      expect(factory._current).toEqual [handleTo(RED_IMAGE), handleTo(INTERNET_IMAGE_50x60)]
      expect(factory._sizes[handleTo(INTERNET_IMAGE_50x60)]).toEqual [50, 60]
      done()
      return

    return



  return




# Validating mock
class MockTextureFactory

  constructor: ->
    @_current = []
    @_sizes = {}

  createTexture: (image) ->
    unless image.naturalWidth > 0
      throw new Error("argument is either not an image, or not loaded: #{image}")

    # Check that the image is usable
    try
      textContext = document.createElement('canvas').getContext('2d')
      textContext.drawImage(image, 0, 0)
      textContext.getImageData(0, 0, 1, 1)
    catch SecurityError
      return false

    handle = handleTo image.src
    unless @_current.indexOf(handle) is -1
      throw new Error("image is already loaded: '#{image.src}'")
    @_current.push handle
    @_sizes[handle] = [image.naturalWidth, image.naturalHeight]
    return handle

  destroyTexture: (handle) ->
    index = @_current.indexOf handle
    if index is -1
      throw new Error("Not a current texture: '#{handle}'")
    @_current.splice(index, 1)
    return


handleTo = (url) ->
  return 'handleTo:' + TextureLoader.wrapInXOriginProxy(url)

