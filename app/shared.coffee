

Tamarind =
  FRAGMENT_SHADER: 'FRAGMENT_SHADER'
  VERTEX_SHADER:   'VERTEX_SHADER'


  DEFAULT_VSHADER_SOURCE: '''
    attribute float a_VertexIndex;
    varying vec2 v_position;

    void main() {
      // this is the default vertex shader. It positions 4 points, one in each corner clockwise from top left, creating a rectangle that fills the whole canvas.
      if (a_VertexIndex == 0.0) {
        v_position = vec2(-1, -1);
      } else if (a_VertexIndex == 1.0) {
        v_position = vec2(1, -1);
      } else if (a_VertexIndex == 2.0) {
        v_position = vec2(1, 1);
      } else if (a_VertexIndex == 3.0) {
        v_position = vec2(-1, 1);
      } else {
        v_position = vec2(0);
      }
      gl_Position.xy = v_position;
    }
  '''


  DEFAULT_FSHADER_SOURCE: '''
    precision mediump float;
    uniform vec2 u_CanvasSize;
    varying vec2 v_position;

    void main() {
      gl_FragColor = vec4(v_position, 1, 1);
    }
  '''


###
  Return false if the browser can't handle the awesome.
###
Tamarind.browserSupportsRequiredFeatures = ->
  if Tamarind.browserSupportsRequiredFeatures.__cache is undefined

    try
      canvas = document.createElement 'canvas'
      ctx = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')

    Tamarind.browserSupportsRequiredFeatures.__cache = !!(ctx and Object.defineProperty)

  return Tamarind.browserSupportsRequiredFeatures.__cache


###
  Define a property on a class.

  If the property is `"fooBar"` then this method will require one or both of
  `_getFooBar()` or `_setFooBar(value)` to exist on the class and create a
  read-write, read-only or write-only property as appropriate.

  Additionally, a default value for the property can be provided in the class
  definition alongside the method declarations.

  @example
    class Foo
      prop: 4 # default value, will be set as prototype._prop = 4
      _getProp: -> @_prop
      _setProp: (val) -> @_prop = val

    defineClassProperty Foo, "prop"
###
Tamarind.defineClassProperty = (cls, propertyName) ->
  PropertyName = propertyName[0].toUpperCase() + propertyName.slice(1)
  getter = cls.prototype['_get' + PropertyName]
  setter = cls.prototype['_set' + PropertyName]

  unless getter or setter
    throw new Error(propertyName + ' must name a getter or a setter')

  initialValue = cls.prototype[propertyName]
  unless initialValue is undefined
    cls.prototype['_' + propertyName] = initialValue

  config =
    enumerable: true
    get: getter or -> throw new Error(propertyName + ' is write-only')
    set: setter or -> throw new Error(propertyName + ' is read-only')

  Object.defineProperty cls.prototype, propertyName, config

  return


###
  Superclass to handle event dispatch
###
class Tamarind.EventEmitter

  # Register an event callback
  #
  # @param [string] eventName
  # @param [function] callback
  on: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList(eventName)
    if list.indexOf(callback) is -1
      list.push callback
    return


  # Remove an event callback added with `on()`
  #
  # @param [string] eventName
  # @param [function] callback
  off: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList eventName
    index = list.indexOf callback
    unless index is -1
      list.splice index, 1
    return


  # Call all callback functions registered with an event
  #
  # @param [string] eventName
  # @param event the argument to be passed to the callback function
  emit: (eventName, event) ->
    @_validateEventArgs eventName
    for f in @_getEventList eventName
      f.call this, event
    return


  # @private
  _getEventList: (eventName) ->
    unless @_events
      @_events = {}
    unless @_events[eventName]
      @_events[eventName] = []
    return @_events[eventName]


  # @private
  _validateEventArgs: (eventName, callback) ->
    unless typeof eventName is 'string'
      throw new Error('eventName must be a string, not ' + JSON.stringify(eventName))
    if arguments.length > 1 and typeof callback isnt 'function'
      throw new Error('callback must be a function, not ' + JSON.stringify(callback))