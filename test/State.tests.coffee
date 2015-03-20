

describe 'State', ->

  stateListener = (state) ->

    listener = {}

    for prop in ['PROPERTY_CHANGE', 'SHADER_CHANGE', 'CHANGE']
      listener[prop] = ->
      spyOn(listener, prop)
      state.on state[prop], listener[prop]

    for prop in ['vertexCount', 'debugMode', 'drawingMode', 'selectedTab']
      listener[prop] = ->
      spyOn(listener, prop)
      state.onPropertyChange prop, listener[prop]


    return listener

  it 'should dispatch events when properties change', (done) ->

    state = new Tamarind.State()
    listener = stateListener(state)

    debugger
    state.vertexCount = 111
    state.vertexCount = 222
    state.vertexCount = 222 # no change
    state.debugMode = true

    # expect one general PROPERTY_CHANGE event per change with property name as argument
    expectCallHistory listener.PROPERTY_CHANGE, ['vertexCount', 'vertexCount', 'debugMode']

    # expect one specific change event per change, with new value as argument
    expectCallHistory listener.vertexCount, [111, 222]
    expectCallHistory listener.debugMode, [true]

    # expect a single CHANGE, dispatched asynchronously
    pollUntil (-> listener.CHANGE.calls.any()), ->
      expectCallHistory listener.CHANGE, [undefined]
      done()
      return

    return



  it 'should dispatch an event when a shader changes', ->

    state = new Tamarind.State()
    listener = stateListener(state)

    state.setShaderSource Tamarind.VERTEX_SHADER, Tamarind.DEFAULT_VSHADER_SOURCE # no event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # yes event
    state.setShaderSource Tamarind.FRAGMENT_SHADER, 'frag' # no event

    expect(listener.SHADER_CHANGE).toHaveBeenCalledWith Tamarind.FRAGMENT_SHADER
    expect(listener.SHADER_CHANGE.calls.count()).toEqual 1

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


    expect(listener.PROPERTY_CHANGE).toHaveBeenCalledWith('vertexCount')
    expect(listener.PROPERTY_CHANGE).not.toHaveBeenCalledWith('debugMode')
    expect(listener.PROPERTY_CHANGE.calls.count()).toEqual(1)
    expect(listener.SHADER_CHANGE).toHaveBeenCalledWith(Tamarind.VERTEX_SHADER)
    expect(listener.SHADER_CHANGE).toHaveBeenCalledWith(Tamarind.FRAGMENT_SHADER)
    expect(listener.SHADER_CHANGE.calls.count()).toEqual(2)

    return

  it 'should delete transient state on restore', ->

    state = new Tamarind.State()
    saved = state.save()
    state.setShaderErrors Tamarind.VERTEX_SHADER, '', [new Tamarind.ShaderError('', 1)]
    state.selectedTab = 'CONFIG'

    state.restore(saved)

    expect(state.selectedTab).not.toEqual('config')
    expect(state.getShaderErrors Tamarind.VERTEX_SHADER).toEqual([])

    return

  it 'should not expose mutable state through the public API', ->

    state = new Tamarind.State()

    errors = state.getShaderErrors(Tamarind.FRAGMENT_SHADER)
    expect(errors).toEqual []

    errors.push(new Tamarind.ShaderError('Message', 0))
    errors = state.getShaderErrors(Tamarind.FRAGMENT_SHADER)
    expect(errors).toEqual []

    return

  return
