ProgramCommands = require '../ProgramCommands.coffee'
constants = require '../../constants.coffee'
InputCommandType = require '../InputCommandType.coffee'
StandaloneCommandType = require '../StandaloneCommandType.coffee'
Commands = require '../Commands.coffee'
{expectProperties} = require '../../tests/testutils.coffee'

myInput = new InputCommandType(
  'myInput',
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
dirs = new Commands [myInput, myStandalone]

fdescribe 'ProgramCommands', ->

  it 'should detect directive errors in shaders', ->

    test = (shaderType, otherType) ->
      pc = new ProgramCommands(dirs)

      pc.setShaderSource shaderType, '''
        uniform vec3 foo; //! myStandalone
      '''

      expectProperties pc.getCommandErrors(shaderType), [
        {
          message: "'myStandalone' command must appear on its own line"
        }
      ]
      expectProperties pc.getCommandErrors(otherType), []

    test constants.FRAGMENT_SHADER, constants.VERTEX_SHADER
    test constants.VERTEX_SHADER, constants.FRAGMENT_SHADER

    return

  return