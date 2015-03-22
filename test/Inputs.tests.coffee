

describe 'Inputs', ->

  normalState = new Tamarind.State()

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
      'bad value for value (expected number, got object null), using default of 0'
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