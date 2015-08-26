constants = require '../constants.coffee'
CommandError = require('./CommandError.coffee')


###
  Parses a GLSL program consisting of vertex and fragment shader, and provides
  information on the commands and command errors contained within.
###
class ProgramAnalyser

  # @param @_directives [CommandParser]
  constructor: (@_parser) ->
    @_reset()

  setShaderSource: (source) ->
    @_reset()

    for command in @_parser.parseGLSL source
      if command.isError
        @unvalidatedErrors.push(command)
      else
        @unvalidatedCommands.push(command)
        if command.isInput()
          @inputCommandsByUniformName[command.uniformName] = command
        else if command.isStandalone()
          @standaloneCommandsByTypeName[command.type.name] = command

    return


  getCommandErrors: () ->
    return @errors.slice()


  hasErrors: ->
    return @errors.length > 0


  getCommands: ->
    return @commands.slice()



  _reset: ->
    @unvalidatedErrors = []
    @unvalidatedCommands = []
    @errors = []
    @commands = []
    @inputCommandsByUniformName = {}
    @standaloneCommandsByTypeName = {}
    return




module.exports = ProgramAnalyser
