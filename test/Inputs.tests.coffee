

describe 'Inputs.parseLine', ->
  
  INPUT_OVERRIDES =
    min: -10
    max: 10
    step: 1

  expectError = (line, message, start, end) ->
    expect(Inputs.parseLine line).toEqual jasmine.objectContaining({
      message: message
      start: start
      end: end
    })
    return


  it 'should parse an individual line', ->
    expect(Inputs.parseLine 'slider my_slider: min -10, max 10, step 1').toEqual mockInput(INPUT_OVERRIDES)
    return

  it 'should allow keywords between numbers to be omitted', ->
    expect(Inputs.parseLine 'slider my_slider: -10 10 1').toEqual mockInput(INPUT_OVERRIDES)
    return

  it 'should allow mixing of the order of keywords', ->
    expect(Inputs.parseLine 'slider my_slider: max 10, min -10, step 1').toEqual mockInput(INPUT_OVERRIDES)
    return

  it 'should allow mixing keyword and positional parameters', ->
    expect(Inputs.parseLine 'slider my_slider: max 10, min -10, 1').toEqual mockInput(INPUT_OVERRIDES)
    expect(Inputs.parseLine 'slider my_slider: -10, max 10, step 1').toEqual mockInput(INPUT_OVERRIDES)
    return

  it 'should ignore whitespace at start and end of lines', ->
    expect(Inputs.parseLine '  \t  slider my_slider: min -10, max 10, step 1    ').toEqual mockInput(INPUT_OVERRIDES)
    return

  it 'should fill in missing values with defaults', ->
    expect(Inputs.parseLine '  \t  slider my_slider: min -10').toEqual mockInput(min: -10)
    return

  it 'should ignore blank lines or those with only whitespace', ->
    expect(Inputs.parseLine '     ').toBeNull()
    expect(Inputs.parseLine '').toBeNull()
    return

  it 'should return an error if type is unrecognised', ->
    expectError 'badtype mybadtype', "invalid type 'badtype'", 0, 7
    return

  it 'should return an error if the input has no name', ->
    expectError 'slider', 'slider has no name', 0, 6
    return

  it 'should return an error if the name is not a valid identifier', ->
    expectError 'slider bad-name', "invalid name 'bad-name', how about 'u_slider'?", 7, 15
    return

  it 'should take whitespace into account when calculating error offsets', ->
    expectError '    badtype     mybadtype', "invalid type 'badtype'", 4, 11
    expectError '   slider    bad-name', "invalid name 'bad-name', how about 'u_slider'?", 13, 21
    return

  it 'should return an error if the number keywords are invalid', ->
    expectError 'slider my_slider: min -10, foo 10, step 1', "invalid property 'foo', expected one of 'min', 'max', 'step'", 27, 30
    return

  it 'should return an error if there are too many number arguments', ->
    # error should extend from first addition argument to end of line
    expectError 'slider my_slider: 1, 1, 1, 1, 1  ', "too many arguments, expected at most 3 ('min', 'max', 'step')", 27, 33
    return

  return



describe 'Inputs.parseLines', ->



  it 'should parse a text block', ->
    expect(Inputs.parseLines '\n\nslider slider1: min -5, max 5\n\n\nslider slider2\n').toEqual [
      null,
      null,
      mockInput(name: 'slider1', min: -5, max: 5),
      null,
      null,
      mockInput({name: 'slider2'}),
      null
    ]
    return


  it 'should produce an error if there are two lines with the same input name', ->
    [line, err] = Inputs.parseLines 'slider x\nslider x'

    expect(line).toEqual mockInput(name: 'x')

    expect(err).toEqual jasmine.objectContaining({
      message: "a previous input is already named 'x'"
      start: 0
      end: 8
    })

    return



  it 'should strip out errors and empty lines if passed the inputLinesOnly argument', ->
    expect(Inputs.parseLines '\n\nslider slider1: min -5, max 5\n\n\nderp! error!\n', true).toEqual [
      mockInput(name: 'slider1', min: -5, max: 5)
    ]
    return

  return


describe 'Inputs.unparseLines', ->


  it 'should create a text block from input objects', ->
    lines = Inputs.unparseLines([interestingInput(name: 'a'), interestingInput(name: 'b')])
    expect(lines).toEqual 'slider a: min -10, max 10, step 1\nslider b: min -10, max 10, step 1'

    return


  it 'should produce an error if there are two lines with the same input name', ->
    [line, err] = Inputs.parseLines 'slider x\nslider x'

    expect(line).toEqual mockInput(name: 'x')

    expect(err).toEqual jasmine.objectContaining({
      message: "a previous input is already named 'x'"
      start: 0
      end: 8
    })

    return

  return

describe 'Inputs.validate', ->

  normalState = new State()

  it 'should not validate an invalid input type', ->

    spyOn console, 'error'

    badInputType = mockInput(type: 'quux')

    input = Inputs.validate badInputType, normalState

    expectCallHistory console.error, ['bad input name="my_slider" type="quux"']
    expect(input).toBeNull()

    return


  it 'should complain about mismatched property types then fall back on the default value', ->

    spyOn console, 'error'

    badPropertyType = mockInput(value: null, min: 'foo')
    input = Inputs.validate badPropertyType, normalState

    expectCallHistory console.error, [
      'bad value for min (expected number, got string "foo"), using default of 0'
      'bad value for value (expected array, got null), using default of [0]'
    ]
    expect(input.min).toEqual 0

    console.error.calls.reset()

    badPropertyType = mockInput(value: [0, 0])
    input = Inputs.validate badPropertyType, normalState

    expectCallHistory console.error, [
      'bad value for value (expected array of 1, got array of 2 [0,0]), using default of [0]'
    ]
    expect(input.min).toEqual 0

    return


  it 'should complain about unrecognised property types and ignore it', ->

    spyOn console, 'error'

    unknownPropertyType = mockInput(lala: 4)
    input = Inputs.validate unknownPropertyType, normalState

    expectCallHistory console.error, ["ignoring unrecognised property 'lala': 4"]
    expect(input.lala).toBeUndefined()

    return



  it 'should transparently convert names to valid GLSL identifiers', ->

    spyOn console, 'error'

    input = Inputs.validate mockInput(name: 'valid'), normalState
    expect(input.name).toEqual 'valid'

    input = Inputs.validate mockInput(name: '1starts_with_number'), normalState
    expect(input.name).toEqual '_1starts_with_number'

    input = Inputs.validate mockInput(name: ' 1 starts with number '), normalState
    expect(input.name).toEqual '_1_starts_with_number'

    input = Inputs.validate mockInput(name: '  contains  spaces  '), normalState
    expect(input.name).toEqual 'contains_spaces'

    input = Inputs.validate mockInput(name: 'has-hyphens!'), normalState
    expect(input.name).toEqual 'has_hyphens'

    input = Inputs.validate mockInput(name: ' ~! '), normalState
    expect(input.name).toEqual 'unnamed'

    return


  return