

###
  Base class for input editors. Instances of these classes encapsulate the controls used
  to edit the values of inputs, and the classes themselves contain metadata e.g. default values
###
class Tamarind.InputEditorBase extends Tamarind.UIComponent

  TEMPLATE = '''
    <div class="tamarind-controls-control">
      <div class="tamarind-controls-control-title">
        <span class="tamarind-controls-control-name"></span>
        <span class="tamarind-controls-control-value"></span>
      </div>
      <div class="tamarind-controls-control-ui">
      </div>
    </div>
  '''

  ##
  ## NOTE!
  ##
  ## It is important that this class and its subclasses don't have any references to
  ## their instances except through ControlDrawer. This includes registering for
  ## event listeners on the State.
  ##


  constructor: (@_input, _state) ->
    super(_state, TEMPLATE)
    @_inputElement = @makeInputElement()
    if @_inputElement
      @css('.tamarind-controls-control-ui').appendChild @_inputElement
    @setInnerText '.tamarind-controls-control-name', @_input.name.replace(/^u_/, '').replace('_', ' ')


  @defaults:
    value: 0


  @fieldOrder: []


  handleInput: =>
    @_state.setInputValue(@_input.name, @getValue())
    return


  # Return the current value of this control
  getValue: ->
    return parseFloat(@_inputElement.value) or 0


  # Format a value for display to users
  getPrettyValue: ->
    return String(@getValue())


  # return a DOM element for the user to interact with, or null of this kind of input doesn't have a DOM component
  makeInputElement: ->
    return null


  # Given an input element returned by makeInputElement, set its value
  setValue: (value) ->
    @_inputElement.value = value
    return


class Tamarind.SliderInputEditor extends Tamarind.InputEditorBase

  @defaults:
    min: 0
    max: 1
    step: 0.01
    value: 0

  @fieldOrder: ['min', 'max', 'step']


  valueToString: (value) ->
    # minimum decimal places to show full precision of step
    dp = ~~Math.max(0, Math.min(18, Math.ceil(Math.log10(1 / @input.step))))
    return value.toFixed(dp)

  makeInputElement: ->
    el = document.createElement 'input'
    el.type = 'range'
    el.min = @_input.min
    el.max = @_input.max
    el.step = @_input.step
    el.value = @_input.value
    el.addEventListener 'input', @handleInput
    return el



class Tamarind.MouseInputEditor extends Tamarind.InputEditorBase

  @defaults:
    delay: 0
    average: 0
    value: 0

  @fieldOrder: ['delay', 'average']


###
  Manager for inputs.

  An input is represented as a plain-old JavaScript object. Every input has a type e.g. 'slider', a name that must
  be a valid GLSL identifier, a value, and other properties according to the type, e.g. 'slider' inputs have a 'min'
  property.
###
class Tamarind.Inputs

  @editorClasses =
    slider: Tamarind.SliderInputEditor
    mouse: Tamarind.MouseInputEditor

  # Create an appropriate Tamarind.InputEditorBase subclass instance to edit the supplied input
  # @param input [object] a validated input data object
  @makeEditor: (input, state) ->
    cls = @editorClasses[input.type]
    unless cls
      throw new Error("Invalid input type '#{input.type}'")
    return new cls(input, state)


  # Return an array of valid input type names
  @getTypes: ->
    return (k for k of @editorClasses)


  # given an input object, return a valid version of it (e.g. filling in missing properties with defaults)
  # or throw an exception if it's broken beyond repair
  @validate = (input, state) ->

    unless state
      debugger
      throw new Error 'Missing state argument'

    editorClass = @editorClasses[input.type]

    unless editorClass and typeof input.name is 'string'
      state.logError "bad input name=#{JSON.stringify(input.name)} type=#{JSON.stringify(input.type)}"
      return null

    for key, value of input
      if editorClass.defaults[key] is undefined and key isnt 'type' and key isnt 'name'
        state.logError "ignoring unrecognised property '#{key}': #{JSON.stringify(value)}"


    validName = @_validateName input.name, 'unnamed'


    sanitised = {
      name: validName
      type: input.type
    }

    for key, defaultValue of editorClass.defaults
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
    editorClass = null
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
        editorClass = @editorClasses[token]
        unless editorClass
          return new Tamarind.InputDefinitionError("invalid type '#{token}'", tokenStart, tokenEnd)
        for key, value of editorClass.defaults
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
        if editorClass.defaults[token] is undefined
          return new Tamarind.InputDefinitionError("invalid property '#{token}', expected one of '#{editorClass.fieldOrder.join('\', \'')}'", tokenStart, tokenEnd)
      else
        numberField = fieldKeyword or editorClass.fieldOrder[numberIndex]
        if numberField is undefined
          return new Tamarind.InputDefinitionError("too many arguments, expected at most #{editorClass.fieldOrder.length} ('#{editorClass.fieldOrder.join('\', \'')}')", tokenStart, text.length)
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
      editorClass = @editorClasses[input.type]
      lines += "#{input.type} #{input.name}: "
      for field, fieldIndex in editorClass.fieldOrder
        if fieldIndex > 0
          lines += ', '
        lines += "#{field} #{input[field]}"
    return lines



class Tamarind.InputDefinitionError

  constructor: (@message, @start = 0, @end = undefined) ->