
###
  Manager for inputs.

  An input is represented as a plain-old JavaScript object. Every input has a type e.g. 'slider', a name that must
  be a valid GLSL identifier, a value, and other properties according to the type, e.g. 'slider' inputs have a 'min'
  property.
###
class Inputs

  SCHEMA =
    slider:
      min: 0
      max: 1
      step: 0.01
      value: 0

  # given an input object, return a valid version of it (e.g. filling in missing properties with defaults)
  # or throw an exception if it's broken beyond repair
  @validate = (input, state) ->

    unless state
      throw new Error 'Missing state argument'

    scheme = SCHEMA[input.type]

    unless scheme and typeof input.name is 'string'
      state.logError "bad input name=#{JSON.stringify(input.name)} type=#{JSON.stringify(input.type)}"
      return null

    for key, value of input
      if scheme[key] is undefined and key isnt 'type' and key isnt 'name'
        state.logError "ignoring unrecognised property '#{key}': #{JSON.stringify(value)}"


    validName = String(input.name)
      .replace(/^\W+/, '')
      .replace(/\W+$/, '')
      .replace(/\W+/g, '_')
      .replace(/^(?=\d)/, '_') # if starts with number, prefix with _
      .replace(/^$/, 'unnamed')


    sanitised = {
      name: validName
      type: input.type
    }

    for key, defaultValue of scheme
      value = input[key]
      if value is undefined
        value = defaultValue
      if typeof value isnt typeof defaultValue
        state.logError "bad value for #{key} (expected #{typeof defaultValue}, got #{typeof value} #{JSON.stringify(value)}), using default of #{JSON.stringify(defaultValue)}"
        value = defaultValue
      sanitised[key] = value

    return sanitised

  class Slider
    foo = 3

