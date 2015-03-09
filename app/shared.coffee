



###
  Return false if the browser can't handle the awesome.
###
browserSupportsRequiredFeatures = ->
  if browserSupportsRequiredFeatures.__cache is undefined

    try
      canvas = document.createElement 'canvas'
      ctx = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')

    browserSupportsRequiredFeatures.__cache = !!(ctx and Object.defineProperty)

  return browserSupportsRequiredFeatures.__cache


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
defineClassProperty = (cls, propertyName) ->
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
