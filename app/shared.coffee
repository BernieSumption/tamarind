
class ConsoleTracer

  log: (m) ->
    if window.console
      console.log m

  error: (m) ->
    if window.console
      console.error m

class NullTracer
  log: ->
  error: ->


browserSupportsRequiredFeatures = ->
  unless Object.defineProperty
    return false

  try
    canvas = createElement('canvas');
    ctx = canvas.getContext('webgl') || canvas.getContext('experimental-webgl')

  return !!ctx


# Define a property on a class. If the property is "fooBar" then this
# method will require one or both of "getFooBar()" or "setFooBar(value)"
# to exist on the class and create a read-write, read-only or write-only
# property as appropiriate.
defineClassProperty = (cls, propertyName) ->
  PropertyName = propertyName[0].toUpperCase() + propertyName.slice(1);
  getter = cls.prototype["get" + PropertyName]
  setter = cls.prototype["set" + PropertyName]

  unless getter or setter
    throw new Error(propertyName + " must name a getter or a setter")

  config =
    enumerable: true
    get: getter || -> throw new Error(propertyName + " is write-only")
    set: setter || -> throw new Error(propertyName + " is read-only")

  Object.defineProperty cls.prototype, propertyName, config
