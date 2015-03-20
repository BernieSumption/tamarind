

class Inputs

  SCHEMA =
    slider:
      min: 0
      max: 10
      step: 0.1
      value: 0

  # given an object representing an input, return
  @validate = (input, state) ->

    scheme = SCHEMA[input.type]

    unless scheme and typeof input.name is 'string'
      state.logError "bad input name=#{JSON.stringify(input.name)} type=#{JSON.stringify(input.type)}"
      return null

    for key, value of input
      if scheme[key] is undefined and key isnt 'type' and key isnt 'name'
        state.logError "ignoring unrecognised property '#{key}': #{JSON.stringify(value)}"


    sanitised = {
      name: input.name
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

