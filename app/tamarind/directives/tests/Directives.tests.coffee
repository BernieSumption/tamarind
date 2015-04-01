Directives = require '../Directives.coffee'
InputDirectiveType = require '../InputDirectiveType.coffee'
CommandDirectiveType = require '../CommandDirectiveType.coffee'

###
  Implementation notes:

  DirectiveType: represents a kind of directive. Subclasses StandaloneDirectiveType InputDirectiveType

  Directive: a command embedded in GLSL source code
###


#TODO recognise full directive with uniform
#TODO recognise short directive without uniform only if at start of line (allow whitepsace)
#TODO directive without uniform and not at start of line is error
#TODO uniform without directive is warning
#TODO uniform without directive is OK if there is a directive for the same uniform in the other shader
#TODO uniform directive must be on same line, not previous
#TODO validation error if slider directive exists on its own
#TODO validation error if vertexCount directive is after uniform
#TODO validation if either directive is after a statement that is not a uniform declaration
#TODO don't pick up directives inside block comments
#TODO don't pick up directives inside line comments
#
fdescribe 'Directives', ->


  expectError = (directive, message, start, end) ->
    expect(dirs._parseDirectiveComment directive).toEqual jasmine.objectContaining({
      message: message
      start: start
      end: end
    })
    return

  myInput = new InputDirectiveType(
    'myInput',
    [
      ['in0', 10]
      ['in1', 11]
    ]
  )
  myCommand = new CommandDirectiveType(
    'myCommand',
    [
      ['cmd0', 20]
      ['cmd1', 21]
    ]
  )
  dirs = new Directives [myInput, myCommand]


  # TODO //! myCommand -> {name: 'command'}
  # TODO //! myCommand: cmd0 -> {name: 'command', args: ['namedArg', null]}
  # TODO //! myCommand: namedArg number -> {name: 'command', args: [['namedArg', number]]}
  # TODO //! myCommand: number1 number2 -> {name: 'command', args: [[null, number1], [null, number2]]}
  # TODO //! myCommand: cmd0, cmd1 -> error
  # TODO //!   -> error

  it 'should parse a standalone directive comment', ->

    fiveSix = {
      type: myCommand
      args: [
        ['cmd0', -5]
        ['cmd1', 6.5]
      ]
      data:
        cmd0: -5
        cmd1: 6.5
    }

    # plain
    expect(dirs._parseDirectiveComment '//! myCommand: cmd0 -5, cmd1 6.5').toEqual fiveSix
    # one or both names ommitted and inferred from order
    expect(dirs._parseDirectiveComment '//! myCommand: -5 6.5').toEqual fiveSix
    expect(dirs._parseDirectiveComment '//! myCommand: cmd0 -5 6.5').toEqual fiveSix
    expect(dirs._parseDirectiveComment '//! myCommand: -5 cmd1 6.5').toEqual fiveSix
    # whitespace at start and end
    expect(dirs._parseDirectiveComment ' \t   //!   myCommand: -5 cmd1 6.5    ').toEqual fiveSix


    # order of args swapped
    expect(dirs._parseDirectiveComment '//! myCommand: cmd1 6.5, cmd0 -5').toEqual {
      type: myCommand
      args: [
        ['cmd1', 6.5]
        ['cmd0', -5]
      ]
      data:
        cmd0: -5
        cmd1: 6.5
    }


  it 'should fill in missing parameters with default values', ->

    expect(dirs._parseDirectiveComment '//! myCommand: cmd0 5').toEqual {
      type: myCommand
      args: [
        ['cmd0', 5]
      ]
      data:
        cmd0: 5
        cmd1: 21
    }

    expect(dirs._parseDirectiveComment '//! myCommand').toEqual {
      type: myCommand
      args: [
      ]
      data:
        cmd0: 20
        cmd1: 21
    }

    return

  it 'should return an error if type is unrecognised', ->
    expectError '//!    badcommand', "invalid command 'badcommand'", 7, 17
    return

  it 'should return an error if the input has no name', ->
    expectError '//!  ', 'expected command', 0, 5
    return


  it 'should return an error if there is a keyword with no value', ->
    expectError '//! myCommand: cmd0 cmd1', "invalid value for 'cmd0', expected a number", 20, 24
    return

  it 'should return an error if there are too many number arguments', ->
    # error should extend from first addition argument to end of line
    expectError '//! myCommand: 1, 1, 1, 1, 1  ', "too many arguments, expected at most 2 ('cmd0', 'cmd1')", 21, 30
    return


  return