

Tamarind =
  FRAGMENT_SHADER: 'FRAGMENT_SHADER'
  VERTEX_SHADER:   'VERTEX_SHADER'
  CONFIG: 'CONFIG'


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
  Convert an HTML string representing a single element into a DOM node.
###
Tamarind.parseHTML = (html) ->
  tmp = document.createElement 'div'
  tmp.innerHTML = html.trim()
  if tmp.childNodes.length > 1
    throw new Error 'html must represent single element'
  el = tmp.childNodes[0]
  tmp.removeChild el
  return el

