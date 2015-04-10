ProgramAnalyser = require '../ProgramAnalyser.coffee'
constants = require '../../constants.coffee'
InputCommandType = require '../InputCommandType.coffee'
StandaloneCommandType = require '../StandaloneCommandType.coffee'
CommandParser = require '../CommandParser.coffee'
{expectProperties} = require '../../tests/testutils.coffee'

myInput = new InputCommandType(
  'myInput',
  [
    ['in0', 10]
    ['in1', 11]
  ]
)
otherInput = new InputCommandType(
  'otherInput',
  [
    ['in0', 10]
    ['in1', 11]
  ]
)
myStandalone = new StandaloneCommandType(
  'myStandalone',
  [
    ['cmd0', 20]
    ['cmd1', 21]
  ]
)
parser = new CommandParser [myInput, myStandalone, otherInput]

describe 'ProgramAnalyser', ->

  it 'should detect directive errors in shaders', ->

    test = (shaderType, otherType) ->
      pa = new ProgramAnalyser(parser)

      pa.setShaderSource shaderType, '''
        uniform vec3 foo; //! myStandalone
      '''

      expectProperties pa.getCommandErrors(shaderType), [
        {
          message: "'myStandalone' command must appear on its own line"
        }
      ]
      expectProperties pa.getCommandErrors(otherType), []

      return

    test constants.FRAGMENT_SHADER, constants.VERTEX_SHADER
    test constants.VERTEX_SHADER, constants.FRAGMENT_SHADER

    return

  it 'should produce an error if the same uniform has a directive in both shaders', ->

    correctCommands = [
      {
        type: myInput,
        uniformType: 'float'
        uniformName: 'foo'
      },
      {
        type: otherInput,
        uniformType: 'float'
        uniformName: 'bar'
      }
    ]

    # set up with no errors

    pa = new ProgramAnalyser(parser)
    pa.setShaderSource constants.VERTEX_SHADER, 'uniform float foo; //! myInput'
    pa.setShaderSource constants.FRAGMENT_SHADER, 'uniform float bar; //! otherInput'

    expect(pa.getCommandErrors constants.VERTEX_SHADER).toEqual []
    expect(pa.getCommandErrors constants.FRAGMENT_SHADER).toEqual []
    expectProperties pa.getCommands(), correctCommands

    # introduce error

    pa.setShaderSource constants.FRAGMENT_SHADER, 'uniform float foo; //! otherInput'

    expect(pa.getCommands()).toEqual []
    expectProperties pa.getCommandErrors(constants.VERTEX_SHADER), [
      {
        message: "uniform 'foo' already has a 'otherInput' command in the fragment shader"
      }
    ]
    expectProperties pa.getCommandErrors(constants.FRAGMENT_SHADER), [
      {
        message: "uniform 'foo' already has a 'myInput' command in the vertex shader"
      }
    ]

    # clear error

    pa.setShaderSource constants.FRAGMENT_SHADER, 'uniform float bar; //! otherInput'

    expect(pa.getCommandErrors constants.VERTEX_SHADER).toEqual []
    expect(pa.getCommandErrors constants.FRAGMENT_SHADER).toEqual []
    expectProperties pa.getCommands(), correctCommands


    return


  it 'should produce an error if the same standalone command exists multiple times between shaders', ->

    pa = new ProgramAnalyser(parser)

    pa.setShaderSource constants.FRAGMENT_SHADER, '\n\n//! myStandalone: cmd0 1'
    pa.setShaderSource constants.VERTEX_SHADER, '\n  //! myStandalone: cmd1 2'

    expectProperties pa.getCommandErrors(constants.FRAGMENT_SHADER), [
      {
        message: "there is already a 'myStandalone' command in the vertex shader"
        line: 2
        start: 0
        end: 24
      }
    ]
    expectProperties pa.getCommandErrors(constants.VERTEX_SHADER), [
      {
        message: "there is already a 'myStandalone' command in the fragment shader"
        line: 1
        start: 2
        end: 26
      }
    ]
    expect(pa.getCommands()).toEqual []


    return

  return