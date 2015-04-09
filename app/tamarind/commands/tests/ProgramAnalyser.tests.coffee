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
      pc = new ProgramAnalyser(parser)

      pc.setShaderSource shaderType, '''
        uniform vec3 foo; //! myStandalone
      '''

      expectProperties pc.getCommandErrors(shaderType), [
        {
          message: "'myStandalone' command must appear on its own line"
        }
      ]
      expectProperties pc.getCommandErrors(otherType), []

      return

    test constants.FRAGMENT_SHADER, constants.VERTEX_SHADER
    test constants.VERTEX_SHADER, constants.FRAGMENT_SHADER

    return

  it 'should produce an error if the same uniform has a directive in both shaders', ->

    correctCommands = [
      {
        type: myInput,
        uniform: {name: 'foo', type: 'float'}
      },
      {
        type: otherInput,
        uniform: {name: 'bar', type: 'float'}
      }
    ]

    # set up with no errors

    pc = new ProgramAnalyser(parser)
    pc.setShaderSource constants.VERTEX_SHADER, 'uniform float foo; //! myInput'
    pc.setShaderSource constants.FRAGMENT_SHADER, 'uniform float bar; //! otherInput'

    expect(pc.getCommandErrors constants.VERTEX_SHADER).toEqual []
    expect(pc.getCommandErrors constants.FRAGMENT_SHADER).toEqual []
    expectProperties pc.getCommands(), correctCommands

    # introduce error

    pc.setShaderSource constants.FRAGMENT_SHADER, 'uniform float foo; //! otherInput'

    expect(pc.getCommands()).toEqual []
    expectProperties pc.getCommandErrors(constants.VERTEX_SHADER), [
      {
        message: "uniform 'foo' already has a 'otherInput' command in the fragment shader"
      }
    ]
    expectProperties pc.getCommandErrors(constants.FRAGMENT_SHADER), [
      {
        message: "uniform 'foo' already has a 'myInput' command in the vertex shader"
      }
    ]

    # clear error

    pc.setShaderSource constants.FRAGMENT_SHADER, 'uniform float bar; //! otherInput'

    expect(pc.getCommandErrors constants.VERTEX_SHADER).toEqual []
    expect(pc.getCommandErrors constants.FRAGMENT_SHADER).toEqual []
    expectProperties pc.getCommands(), correctCommands


    return


  it 'should produce an error if the same standalone command exists multiple times between shaders', ->

    pc = new ProgramAnalyser(parser)

    pc.setShaderSource constants.FRAGMENT_SHADER, '\n\n//! myStandalone: cmd0 1'
    pc.setShaderSource constants.VERTEX_SHADER, '\n  //! myStandalone: cmd1 2'

    expectProperties pc.getCommandErrors(constants.FRAGMENT_SHADER), [
      {
        message: "there is already a 'myStandalone' command in the vertex shader"
        line: 2
        start: 0
        end: 24
      }
    ]
    expectProperties pc.getCommandErrors(constants.VERTEX_SHADER), [
      {
        message: "there is already a 'myStandalone' command in the fragment shader"
        line: 1
        start: 2
        end: 26
      }
    ]
    expect(pc.getCommands()).toEqual []


    return

  return