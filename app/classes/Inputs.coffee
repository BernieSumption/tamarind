


###
  Manager for inputs.

  An input is represented as a plain-old JavaScript object. Every input has a type e.g. 'slider', a name that must
  be a valid GLSL identifier, a value, and other properties according to the type, e.g. 'slider' inputs have a 'min'
  property.
###
class Tamarind.Inputs

  @inputClasses =
    slider: Tamarind.SliderInput
    mouse: Tamarind.MouseInput
    color: Tamarind.ColorInput

  # Create an appropriate Tamarind.InputBase subclass instance to edit the supplied input
  # @param input [object] a validated input data object
  @makeEditor: (input, state) ->
    cls = @inputClasses[input.type]
    unless cls
      throw new Error("Invalid input type '#{input.type}'")
    return new cls(input, state)


  # Return an array of valid input type names
  @getTypes: ->
    return (k for k of @inputClasses)


  # given an input object, return a valid version of it (e.g. filling in missing properties with defaults)
  # or throw an exception if it's broken beyond repair
  @validate = (input, state) ->

    unless state
      throw new Error 'Missing state argument'

    inputClass = @inputClasses[input.type]

    unless inputClass and typeof input.name is 'string'
      state.logError "bad input name=#{JSON.stringify(input.name)} type=#{JSON.stringify(input.type)}"
      return null

    for key, value of input
      if inputClass.defaults[key] is undefined and key isnt 'type' and key isnt 'name'
        state.logError "ignoring unrecognised property '#{key}': #{JSON.stringify(value)}"


    validName = @_validateName input.name, 'unnamed'


    sanitised = {
      name: validName
      type: input.type
    }

    for key, defaultValue of inputClass.defaults
      value = input[key]
      if value is undefined
        value = defaultValue

      error = false
      if typeof value isnt typeof defaultValue
        error = "expected #{typeof defaultValue}, got #{typeof value}"
      else if Array.isArray(defaultValue)
        if Array.isArray(value)
          unless value.length is defaultValue.length
            error = "expected array of #{defaultValue.length}, got array of #{value.length}"
        else
          error = 'expected array, got'

      if error
        state.logError "bad value for #{key} (#{error} #{JSON.stringify(value)}), using default of #{JSON.stringify(defaultValue)}"
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
    inputClass = null
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
        inputClass = @inputClasses[token]
        unless inputClass
          return new Tamarind.InputDefinitionError("invalid type '#{token}'", tokenStart, tokenEnd)
        for key, value of inputClass.defaults
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
        if inputClass.defaults[token] is undefined
          return new Tamarind.InputDefinitionError("invalid property '#{token}', expected one of '#{inputClass.fieldOrder.join('\', \'')}'", tokenStart, tokenEnd)
      else
        numberField = fieldKeyword or inputClass.fieldOrder[numberIndex]
        if numberField is undefined
          return new Tamarind.InputDefinitionError("too many arguments, expected at most #{inputClass.fieldOrder.length} ('#{inputClass.fieldOrder.join('\', \'')}')", tokenStart, text.length)
        result[numberField] = number
        numberIndex++
        fieldKeyword = null

    unless result.type
      return null

    unless result.name
      return new Tamarind.InputDefinitionError("#{result.type} has no name", 0, text.length)

    return result

  # split text into lines and parse each line, applying whole-program validation
  # Return an array with one entry (as returned by Tamarind.Inputs.parseLine) per line in the source text
  # @param inputLinesOnly if true, don't return input and empty lines
  @parseLines = (text, inputLinesOnly = false) ->
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
    if inputLinesOnly
      items = items.filter((x) ->
        return x and x not instanceof Tamarind.InputDefinitionError)
    return items


  # convert valid input objects into a text representation that would create
  # the same input objects if parsed with Tamarind.Inputs.parseLines.
  @unparseLines = (inputs) ->
    lines = ''
    for input, inputIndex in inputs
      if inputIndex > 0
        lines += '\n'
      inputClass = @inputClasses[input.type]
      lines += "#{input.type} #{input.name}: "
      for field, fieldIndex in inputClass.fieldOrder
        if fieldIndex > 0
          lines += ', '
        lines += "#{field} #{input[field]}"
    return lines




class Tamarind.InputDefinitionError

  constructor: (@message, @start = 0, @end = undefined) ->