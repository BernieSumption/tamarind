constants = require '../constants.coffee'
CommandError = require('./CommandError.coffee')


###
  Parses a GLSL program consisting of vertex and fragment shader, and provides
  information on the commands and command errors contained within.
###
class ProgramCommands

  # @param @_directives [CommandParser]
  constructor: (parser) ->
    @_shaders = {}
    @_shaders[constants.FRAGMENT_SHADER] = new ShaderCommands(parser, constants.FRAGMENT_SHADER)
    @_shaders[constants.VERTEX_SHADER] = new ShaderCommands(parser, constants.VERTEX_SHADER)
    @_combinedErrors = []
    @_combinedCommands = []

  setShaderSource: (shaderType, source) ->
    thisType = @_shaders[shaderType]
    otherType = @_shaders[otherShaderType shaderType]

    if thisType.source is source
      return

    thisType.setSource source

    thisType.validateAgainstOtherShader otherType
    otherType.validateAgainstOtherShader thisType

    return



  getCommandErrors: (shaderType) ->
    return @_shaders[shaderType].errors


  getCommands: ->
    return @_shaders.VERTEX_SHADER.commands.concat(@_shaders.FRAGMENT_SHADER.commands)



class ShaderCommands

  constructor: (@_parser, @_shaderType) ->
    @_reset ''

  _reset: (@source) ->
    @unvalidatedErrors = []
    @unvalidatedCommands = []
    @errors = []
    @commands = []
    @commandsByUniformName = {}
    @standaloneCommandsByTypeName = {}
    return


  setSource: (source) ->

    @_reset source

    for command in @_parser.parseGLSL source
      if command.isError
        @unvalidatedErrors.push(command)
      else
        @unvalidatedCommands.push(command)
        if command.uniform
          @commandsByUniformName[command.uniform.name] = command
        else
          @standaloneCommandsByTypeName[command.type.name] = command


  # Apply validation rules that depend on the other shader
  # @param other [ShaderCommands]
  validateAgainstOtherShader: (other) ->
    @errors = @unvalidatedErrors.slice()
    @commands = []

    for command in @unvalidatedCommands
      if command.uniform
        otherCommand = other.commandsByUniformName[command.uniform.name]
        if otherCommand
          prettyOtherType = otherShaderType(@_shaderType).toLowerCase().replace('_', ' ')
          @errors.push new CommandError(
            "uniform '#{otherCommand.uniform.name}' already has a '#{otherCommand.type.name}' command in the #{prettyOtherType}",
            command.line, command.start, command.end)
        else
          @commands.push command
      else
        otherCommand = other.standaloneCommandsByTypeName[command.type.name]
        if otherCommand
          prettyOtherType = otherShaderType(@_shaderType).toLowerCase().replace('_', ' ')
          @errors.push new CommandError("there is already a '#{otherCommand.type.name}' command in the #{prettyOtherType}",
            command.line, command.start, command.end)
        else
          @commands.push command
    


otherShaderType = (shaderType) ->
  if shaderType is constants.FRAGMENT_SHADER
    return constants.VERTEX_SHADER
  if shaderType is constants.VERTEX_SHADER
    return constants.FRAGMENT_SHADER
  throw new Error("invalid shader type '#{shaderType}'")

module.exports = ProgramCommands
