CommandParser = require '../CommandParser.coffee'
InputCommandType = require '../InputCommandType.coffee'
StandaloneCommandType = require '../StandaloneCommandType.coffee'
{expectProperties} = require '../../tests/testutils.coffee'

myInput = new InputCommandType(
  'myInput',
  [
    ['in0', 10]
    ['in1', 11]
  ],
  3
)
myStandalone = new StandaloneCommandType(
  'myStandalone',
  [
    ['cmd0', 20]
    ['cmd1', 21]
  ]
)
parser = new CommandParser [myInput, myStandalone]


describe 'CommandParser.parseCommandComment', ->


  expectError = (command, message, start, end) ->
    parsed = parser.parseCommandComment command, 2, 1000 # add 1000 char offset so we can check that it's being correctly added to each error
    expect(parsed).not.toBeNull()
    unless parsed
      return
    expect(parsed.line).toEqual 2
    parsed.start -= 1000
    parsed.end -= 1000
    expect(parsed.message).toEqual message
    expect(parsed.start).toEqual start
    expect(parsed.end).toEqual end
    return


  it 'should parse a standalone command comment', ->

    fiveSix = {
      type: myStandalone
      args: [
        ['cmd0', -5]
        ['cmd1', 6.5]
      ]
      data:
        cmd0: -5
        cmd1: 6.5
    }

    # plain
    expectProperties parser.parseCommandComment('//! myStandalone: cmd0 -5, cmd1 6.5'), fiveSix
    # one or both names ommitted and inferred from order
    expectProperties parser.parseCommandComment('//! myStandalone: -5 6.5'), fiveSix
    expectProperties parser.parseCommandComment('//! myStandalone: cmd0 -5 6.5'), fiveSix
    expectProperties parser.parseCommandComment('//! myStandalone: -5 cmd1 6.5'), fiveSix
    # whitespace at start and end
    expectProperties parser.parseCommandComment(' \t   //!   myStandalone: -5 cmd1 6.5    '), fiveSix


    # order of args swapped
    expectProperties parser.parseCommandComment('//! myStandalone: cmd1 6.5, cmd0 -5'), {
      type: myStandalone
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

    expectProperties parser.parseCommandComment('//! myStandalone: cmd0 5'), {
      type: myStandalone
      args: [
        ['cmd0', 5]
      ]
      data:
        cmd0: 5
        cmd1: 21
    }

    expectProperties parser.parseCommandComment('//! myStandalone'), {
      type: myStandalone
      args: [
      ]
      data:
        cmd0: 20
        cmd1: 21
    }

    return

  it 'should return an error if there is no command name', ->
    expectError '//! : ', 'expected command', 0, 6
    expectError '//!', 'expected command', 0, 3
    return

  it 'should return an error if type is unrecognised', ->
    expectError '//!    badcommand', "invalid command 'badcommand'", 7, 17
    return

  it 'should return an error if there is an argument name with no value', ->
    expectError '//! myStandalone: cmd0 cmd1', "invalid value for 'cmd0', expected a number", 18, 27
    expectError '//! myStandalone: cmd0 xyz', "invalid value for 'cmd0', expected a number", 18, 26
    expectError '//! myStandalone: cmd0', "missing value for 'cmd0'", 18, 22
    expectError '//! myStandalone: cmd0 ', "missing value for 'cmd0'", 18, 23
    return

  it 'should return an error if there are too many number arguments', ->
    # error should extend from first addition argument to end of line
    expectError '//! myStandalone: 1, 1, 1, 1, 1  ', "too many arguments, expected at most 2 ('cmd0', 'cmd1')", 24, 33
    return

  it 'should return an error if there are too many number arguments', ->
    expectError '//! myStandalone: lala', "invalid property 'lala', expected one of 'cmd0', 'cmd1'", 18, 22
    return


  return





describe 'CommandParser.parseGLSL', ->

  it 'should handle source code with no commands in it', ->

    expect(parser.parseGLSL '').toEqual []

    expect(parser.parseGLSL '\nfloat foo = 1.0;\n').toEqual []


    return

  it 'should recognise an input command with attached uniform', ->

    source = '''
      float foo = 4.0; /* bumpf before */
      uniform vec3 foo; //! myInput: in0 5
      void main() {} // bumpf after
    '''
    expectProperties parser.parseGLSL(source), [
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
    expectProperties parser.parseGLSL(source), [
      {
        type: myInput
      }
    ]

    return

  it 'should return an error when an input command does not appear directly after a uniform', ->

# other code between uniform and command is not OK
    source = '\n\nuniform vec3 foo; float bar; //! myInput '
    expectProperties parser.parseGLSL(source), [
      message: "'myInput' command must appear directly after a uniform declaration"
      start: 29
      end: 41
    ]

    # uniform on previous line is not OK
    source = '\n\nuniform vec3 foo; \n //! myInput '
    expectProperties parser.parseGLSL(source), [
      message: "'myInput' command must appear directly after a uniform declaration"
    ]

    return

  it 'should have correct line property on all errors', ->

    # error picked up by parseGLSL
    source = '\n\nuniform vec3 foo; float bar; //! myInput '
    expectProperties parser.parseGLSL(source), [
      line: 2
    ]

    # error picked up by parseCommandComment
    source = '\nuniform vec3 foo; //! myInput: badArg'
    expectProperties parser.parseGLSL(source), [
      line: 1
    ]

    return

  it 'should recognise a command command without an attached uniform', ->

    expected = [
      {
        type: myStandalone
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
      //! myStandalone: cmd1 -11.4
      void main() {} // bumpf after
    '''
    expectProperties parser.parseGLSL(source), expected

    source = '//! myStandalone: cmd1 -11.4'
    expectProperties parser.parseGLSL(source), expected
    return

  it 'should parse multiple commands in one shader program', ->

    source = '''
      uniform vec3 foo; //! myInput
      uniform vec3 bar; //! myInput
      //! myStandalone
    '''

    # order of args swapped
    expectProperties parser.parseGLSL(source), [
      {
        type: myInput
        uniform:
          type: 'vec3'
          name: 'foo'
      },
      {
        type: myInput
        uniform:
          type: 'vec3'
          name: 'bar'
      },
      {
        type: myStandalone
      }
    ]

    return

  it 'should produce an error if a command command has other code before it on its line', ->

    # whitespace is OK
    source = '\n  //! myStandalone: cmd1 -11.4'
    expectProperties parser.parseGLSL(source), [
      isError: false
    ]

    # uniform on previous line is OK
    source = '''
      uniform vec2 foo;
      //! myStandalone: cmd1 -11.4
    '''
    expectProperties parser.parseGLSL(source), [
      isError: false
    ]

    source = '''
      uniform vec2 foo; //! myStandalone: cmd1 -11.4
    '''
    expectProperties parser.parseGLSL(source), [
      message: "'myStandalone' command must appear on its own line"
    ]

    source = '''
      /*  */ //! myStandalone: cmd1 -11.4
    '''
    expectProperties parser.parseGLSL(source), [
      message: "'myStandalone' command must appear on its own line"
    ]
    return

  it 'should return an error if a uniform command appears after the wrong type of uniform', ->

    source = '''
      uniform vec2 foo; //! myInput
    '''
    expectProperties parser.parseGLSL(source), [
      message: "'myInput' command can only be applied to a uniform vec3"
    ]
    return

  it 'should return an error a stnadalone command appears multiple times', ->

    source = '''
      //! myStandalone
      //! myStandalone: cmd0 2
    '''
    expectProperties parser.parseGLSL(source), [
      {
        isError: false
        type: myStandalone
      },
      {
        message: "there is already a 'myStandalone' command in the this shader"
      }
    ]
    return

  return

