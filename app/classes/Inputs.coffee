
###
  Manager for inputs.

  An input is represented as a plain-old JavaScript object. Every input has a type e.g. 'slider', a name that must
  be a valid GLSL identifier, a value, and other properties according to the type, e.g. 'slider' inputs have a 'min'
  property.
###
class Inputs

  # default values for each input type. Tis is also used to validate the member names and types of input objects.
  @SCHEMA =
    slider:
      defaults:
        min: 0
        max: 1
        step: 0.01
        value: 0
      fieldOrder: ['min', 'max', 'step']


  # given an input object, return a valid version of it (e.g. filling in missing properties with defaults)
  # or throw an exception if it's broken beyond repair
  @validate = (input, state) ->

    unless state
      throw new Error 'Missing state argument'

    scheme = @SCHEMA[input.type]

    unless scheme and typeof input.name is 'string'
      state.logError "bad input name=#{JSON.stringify(input.name)} type=#{JSON.stringify(input.type)}"
      return null

    for key, value of input
      if scheme.defaults[key] is undefined and key isnt 'type' and key isnt 'name'
        state.logError "ignoring unrecognised property '#{key}': #{JSON.stringify(value)}"


    validName = @_validateName input.name, 'unnamed'


    sanitised = {
      name: validName
      type: input.type
    }

    for key, defaultValue of scheme.defaults
      value = input[key]
      if value is undefined
        value = defaultValue
      if typeof value isnt typeof defaultValue
        state.logError "bad value for #{key} (expected #{typeof defaultValue}, got #{typeof value} #{JSON.stringify(value)}), using default of #{JSON.stringify(defaultValue)}"
        value = defaultValue
      sanitised[key] = value

    return sanitised

  @_validateName = (name, defaultName) ->
    return String(name)
      .replace(/^\W+/, '')
      .replace(/\W+$/, '')
      .replace(/\W+/g, '_')
      .replace(/^(?=\d)/, '_') or defaultName

  # Parse a line and return an input object if the line is a valid input description,
  # null if the line doesn't represent an input but has no errors (e.g. is all white space),
  # or a Tamarind.InputDefinitionError object if the
  @parseLine = (text) ->
    if text is ''
      return null
    tokenEnd = 0
    tokenStart = 0
    scheme = null
    result = {}
    numberIndex = 0
    fieldKeyword = null
    # state machine parser. Expects type then name then a sequence of numbers that are
    # interpreted as fields according to the fieldOrder property of the scheme.
    for token in text.match /([,:\s]+|[^,:\s]+)/g
      tokenStart = tokenEnd
      tokenEnd += token.length
      if /[,:\s]/.test token
        continue
      if result.type is undefined
        result.type = token
        scheme = @SCHEMA[token]
        unless scheme
          return new Tamarind.InputDefinitionError("invalid type '#{token}'", tokenStart, tokenEnd)
        for key, value of scheme.defaults
          result[key] = value
        continue
      if not result.name
        validName = @_validateName token, false
        unless validName and validName is token
          return new Tamarind.InputDefinitionError("invalid name '#{token}', how about 'u_#{result.type}'?", tokenStart, tokenEnd)
        result.name = token
        continue

      number = parseFloat token
      if isNaN number
        fieldKeyword = token
        if scheme.defaults[token] is undefined
          return new Tamarind.InputDefinitionError("invalid property '#{token}', expected one of '#{scheme.fieldOrder.join('\', \'')}'", tokenStart, tokenEnd)
      else
        numberField = fieldKeyword or scheme.fieldOrder[numberIndex]
        if numberField is undefined
          return new Tamarind.InputDefinitionError("too many arguments, expected at most #{scheme.fieldOrder.length} ('#{scheme.fieldOrder.join('\', \'')}')", tokenStart, text.length)
        result[numberField] = number
        numberIndex++
        fieldKeyword = null

    unless result.type
      return null

    unless result.name
      return new Tamarind.InputDefinitionError("#{result.type} has no name", 0, text.length)

    return result

  # split text into lines and parse each line, applying whole-program validation
  # Return an array with one entry (as returned by Inputs.parseLine) per line in the source text
  @parseLines = (text, validLinesOnly = false) ->
    items = []
    seen = {}
    for line in text.split(/\r|\n|\r\n/)
      parsed = @parseLine line
      if parsed and parsed.name
        if seen[parsed.name]
          parsed = new Tamarind.InputDefinitionError("a previous input is already named '#{parsed.name}'", 0, line.length)
        else
          seen[parsed.name] = true
      items.push(parsed)
    if validLinesOnly
      items = items.filter((x) ->
        debugger
        return x and x not instanceof Tamarind.InputDefinitionError)
    return items


  # convert valid input objects into a text representation that would create
  # the same input objects if parsed with Inputs.parseLines.
  @unparseLines = (inputs) ->
    lines = ''
    for input, inputIndex in inputs
      if inputIndex > 0
        lines += '\n'
      scheme = @SCHEMA[input.type]
      lines += "#{input.type} #{input.name}: "
      for field, fieldIndex in scheme.fieldOrder
        if fieldIndex > 0
          lines += ', '
        lines += "#{field} #{input[field]}"
    return lines



class Tamarind.InputDefinitionError

  constructor: (@message, @start = 0, @end = undefined) ->