

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



  return