


describe 'State', ->

  stateListener = (state) ->

    listener =
      propChange: ->
      shaderChange: ->

    spyOn(listener, 'propChange')
    spyOn(listener, 'shaderChange')

    state.on state.PROPERTY_CHANGE, listener.propChange
    state.on state.SHADER_CHANGE, listener.shaderChange

    return listener

  it 'should dispatch an event when a shader or property changes', ->
    state = new Tamarind.State()

    listener = stateListener(state)

    state.setShaderSource Tamarind.VERTEX_SHADER, Tamarind.DEFAULT_VSHADER_SOURCE # no event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # yes event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # no event

    expect(listener.shaderChange).toHaveBeenCalledWith Tamarind.FRAGMENT_SHADER
    expect(listener.shaderChange.calls.count()).toEqual 1

    state.debugMode = false # no event
    state.debugMode = true # yes event
    state.debugMode = true # no event
    state.debugMode = false # yes event
    expect(listener.propChange).toHaveBeenCalledWith 'debugMode'
    expect(listener.propChange.calls.count()).toEqual 2

    return

  it 'should allow saving and restoring of content', ->

    state = new Tamarind.State()

    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag'
    state.setShaderSource Tamarind.VERTEX_SHADER, 'vert'
    state.vertexCount = 12345

    serialized = state.save()

    state = new Tamarind.State()

    expect(state.vertexCount).not.toEqual(12345)
    expect(state.getShaderSource Tamarind.FRAGMENT_SHADER).not.toEqual('frag')
    expect(state.getShaderSource Tamarind.VERTEX_SHADER).not.toEqual('vert')

    listener = stateListener(state)

    state.restore(serialized)

    expect(state.vertexCount).toEqual(12345)
    expect(state.getShaderSource Tamarind.FRAGMENT_SHADER).toEqual('frag')
    expect(state.getShaderSource Tamarind.VERTEX_SHADER).toEqual('vert')


    expect(listener.propChange).toHaveBeenCalledWith('vertexCount')
    expect(listener.propChange).not.toHaveBeenCalledWith('debugMode')
    expect(listener.propChange.calls.count()).toEqual(1)
    expect(listener.shaderChange).toHaveBeenCalledWith(Tamarind.VERTEX_SHADER)
    expect(listener.shaderChange).toHaveBeenCalledWith(Tamarind.FRAGMENT_SHADER)
    expect(listener.shaderChange.calls.count()).toEqual(2)


#    source =
#      a: 'foo'
#      b:
#        c: 'lala'
#
#
#    dest =
#      a: '1'
#      b:
#        c: '2'
#        f: '3'
#      d: null
#
#    mergeObjects source, dest
#
#    expect(dest.a).toEqual 'foo'
#    expect(dest.b.c).toEqual 'lala'
#    expect(dest.b.f).toEqual '3'
#    expect(dest.d).toEqual null
#
#    expect(-> mergeObjects(notThere: 4, dest)).toThrow(new Error("Can't merge property 'notThere': source is number destination is undefined"))
#    expect(-> mergeObjects(b: 4, dest)).toThrow(new Error("Can't merge property 'b': source is number destination is object"))

    return

  return
