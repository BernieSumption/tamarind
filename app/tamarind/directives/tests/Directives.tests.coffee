Directives = require '../Directives.coffee'
InputDirectiveType = require '../InputDirectiveType.coffee'
CommandDirectiveType = require '../CommandDirectiveType.coffee'
{expectProperties} = require '../../tests/testutils.coffee'

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


describe 'Directives.parseDirectiveComment', ->


  expectError = (directive, message, start, end) ->
    parsed = dirs.parseDirectiveComment directive
    expect(parsed).not.toBeNull()
    unless parsed
      return
    expect(parsed.message).toEqual message
    expect(parsed.start).toEqual start
    expect(parsed.end).toEqual end
    return


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
    expectProperties dirs.parseDirectiveComment('//! myCommand: cmd0 -5, cmd1 6.5'), fiveSix
    # one or both names ommitted and inferred from order
    expectProperties dirs.parseDirectiveComment('//! myCommand: -5 6.5'), fiveSix
    expectProperties dirs.parseDirectiveComment('//! myCommand: cmd0 -5 6.5'), fiveSix
    expectProperties dirs.parseDirectiveComment('//! myCommand: -5 cmd1 6.5'), fiveSix
    # whitespace at start and end
    expectProperties dirs.parseDirectiveComment(' \t   //!   myCommand: -5 cmd1 6.5    '), fiveSix


    # order of args swapped
    expectProperties dirs.parseDirectiveComment('//! myCommand: cmd1 6.5, cmd0 -5'), {
      type: myCommand
      args: [
        ['cmd1', 6.5]
        ['cmd0', -5]
      ]
      data:
        cmd0: -5
        cmd1: 6.5
    }

    return


  it 'should fill in missing parameters with default values', ->

    expectProperties dirs.parseDirectiveComment('//! myCommand: cmd0 5'), {
      type: myCommand
      args: [
        ['cmd0', 5]
      ]
      data:
        cmd0: 5
        cmd1: 21
    }

    expectProperties dirs.parseDirectiveComment('//! myCommand'), {
      type: myCommand
      args: [
      ]
      data:
        cmd0: 20
        cmd1: 21
    }

    return

  it 'should return an error if there is no directive name', ->
    expectError '//! : ', 'expected command', 0, 6
    expectError '//!', 'expected command', 0, 3
    return

  it 'should return an error if type is unrecognised', ->
    expectError '//!    badcommand', "invalid command 'badcommand'", 7, 17
    return

  it 'should return an error if there is an argument name with no value', ->
    expectError '//! myCommand: cmd0 cmd1', "invalid value for 'cmd0', expected a number", 15, 24
    expectError '//! myCommand: cmd0 xyz', "invalid value for 'cmd0', expected a number", 15, 23
    expectError '//! myCommand: cmd0', "missing value for 'cmd0'", 15, 19
    expectError '//! myCommand: cmd0 ', "missing value for 'cmd0'", 15, 20
    return

  it 'should return an error if there are too many number arguments', ->
    # error should extend from first addition argument to end of line
    expectError '//! myCommand: 1, 1, 1, 1, 1  ', "too many arguments, expected at most 2 ('cmd0', 'cmd1')", 21, 30
    return

  it 'should return an error if there are too many number arguments', ->
    expectError '//! myCommand: lala', "invalid property 'lala', expected one of 'cmd0', 'cmd1'", 15, 19
    return


  return





describe 'Directives.parseGLSL', ->

  it 'should recognise an input directive with attached uniform', ->

    source = '''
      float foo = 4.0; /* bumpf before */
      uniform vec3 foo; //! myInput: in0 5
      void main() {} // bumpf after
    '''
    expectProperties dirs.parseGLSL(source), [
      {
        type: myInput
        uniform: {
          name: 'foo',
          type: 'vec3'
        }
        args: [
          ['in0', 5]
        ]
        data:
          in0: 5
          in1: 11
      }
    ]

    return

  it 'should be resistant to extra whitespace, comments and semicolons in uniform declarations', ->

    source = '''
      // foo
      uniform /* */ vec3 // blarty
         foo ; ; //! myInput
      // lala!
      void main() {} // bumpf after
    '''
    expectProperties dirs.parseGLSL(source), [
      {
        type: myInput
      }
    ]

    return

  it 'should return an error when an input directive does not appear directly after a uniform', ->

# other code between uniform and directive is not OK
    source = '\n\nuniform vec3 foo; float bar; //! myInput '
    expectProperties dirs.parseGLSL(source), [
      message: "'myInput' command must appear directly after a uniform declaration"
      start: 0
      end: 12
    ]

    # uniform on previous line is not OK
    source = '\n\nuniform vec3 foo; \n //! myInput '
    expectProperties dirs.parseGLSL(source), [
      message: "'myInput' command must appear directly after a uniform declaration"
    ]

    return

  it 'should have correct line and lineOffset properties on all errors', ->

    # error picked up by parseGLSL
    source = '\n\nuniform vec3 foo; float bar; //! myInput '
    expectProperties dirs.parseGLSL(source), [
      line: 2
      lineOffset: 29
    ]

    # error picked up by parseDirectiveComment
    source = '\nuniform vec3 foo; //! myInput: badArg'
    expectProperties dirs.parseGLSL(source), [
      line: 1
      lineOffset: 18
    ]

    return

  it 'should recognise a command directive without an attached uniform', ->

    expected = [
      {
        type: myCommand
        uniform: null
        args: [
          ['cmd1', -11.4]
        ]
        data:
          cmd0: 20
          cmd1: -11.4
      }
    ]

    source = '''
      float foo = 4.0; /* bumpf before */
      //! myCommand: cmd1 -11.4
      void main() {} // bumpf after
    '''
    expectProperties dirs.parseGLSL(source), expected

    source = '//! myCommand: cmd1 -11.4'
    expectProperties dirs.parseGLSL(source), expected
    return

  it 'should produce an error if a command directive has other code before it on its line', ->

    # whitespace is OK
    source = '\n  //! myCommand: cmd1 -11.4'
    expectProperties dirs.parseGLSL(source), [
      isError: false
    ]

    # uniform on previous line is OK
    source = '''
      uniform vec2 foo;
      //! myCommand: cmd1 -11.4
    '''
    expectProperties dirs.parseGLSL(source), [
      isError: false
    ]

    source = '''
      uniform vec2 foo; //! myCommand: cmd1 -11.4
    '''
    expectProperties dirs.parseGLSL(source), [
      message: "'myCommand' command must appear on its own line"
    ]

    source = '''
      /*  */ //! myCommand: cmd1 -11.4
    '''
    expectProperties dirs.parseGLSL(source), [
      message: "'myCommand' command must appear on its own line"
    ]
    return

  return

