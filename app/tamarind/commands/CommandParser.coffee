CommandError = require './CommandError.coffee'
Command      = require './Command.coffee'

indexBy      = require 'lodash/collection/indexBy'
tokenize     = require 'glsl-tokenizer/string'

class CommandParser

  constructor: (@_commandTypes) ->
    @_typesByName = indexBy @_commandTypes, 'name'


  parseGLSL: (glsl) ->
    tokens = tokenize glsl
    commands = []
    seenStandalones = {}
    for token, i in tokens
      if token.data.indexOf('//!') is 0
        lineNo = token.line - 1 # we use 0 indexed lines, glsl-tokenizer uses 1 indexed
        tokenStart = token.column - token.data.length
        command = @parseCommandComment token.data, lineNo, tokenStart

        isOnNewLine = i is 0 or tokens[i - 1].data.indexOf('\n') > -1

        unless command.isError
          errorMessage = false
          uniform = findUniform(tokens, i)
          if uniform
            command.setUniform(uniform.type, uniform.name)
          if command.type.isUniformSuffix is true
            if isOnNewLine or not uniform
              errorMessage = "'#{command.type.name}' command must appear directly after a uniform declaration"
            else unless uniform.type is command.type.uniformType
              errorMessage = "'#{command.type.name}' command can only be applied to a uniform #{command.type.uniformType}"


          else if command.type.isUniformSuffix is false
            if not isOnNewLine
              errorMessage = "'#{command.type.name}' command must appear on its own line"
            else if seenStandalones[command.type.name]
              errorMessage = "there is already a '#{command.type.name}' command in the this shader"

            seenStandalones[command.type.name] = true

          if errorMessage
            command = new CommandError(errorMessage, lineNo, tokenStart, tokenStart + token.data.length)

        commands.push command


    return commands


  # Parse a comment in the form //! command: arg value, arg value
  # into an object with the following properties:
  #
  # - `type`: a CommandType subclass representing the command
  # - `args`: an array of ['arg0', value] pairs representing supplied arguments
  # - `data`: argument map after applying default values for missing arguments
  #
  parseCommandComment: (text, line = 0, lineOffset = 0) ->
    tokenEnd = lineOffset
    tokenStart = lineOffset
    lineEnd = lineOffset + text.length
    dType = null
    dArgs = []
    argName = null
    argNameTokenStart = null
    # state machine parser. Expects a command name then a sequence of `argumentName number` arguments
    for part in text.match /([,:!\/=\s]+|[^,:!\/=\s]+)/g
      tokenStart = tokenEnd
      tokenEnd += part.length
      if /[,:!\/=\s]/.test part
        continue

      if dType is null
        dType = @_typesByName[part]
        unless dType
          return new CommandError("invalid command '#{part}'", line, tokenStart, tokenEnd)
        continue

      if dArgs.length >= dType.params.length
        return new CommandError("too many arguments, expected at most #{dType.params.length} ('#{dType.paramNames.join('\', \'')}')", line, tokenStart, lineEnd)

      number = parseFloat part
      if isNaN number
        if argName
          return new CommandError("invalid value for '#{argName}', expected a number", line, argNameTokenStart, tokenEnd)
        argName = part
        argNameTokenStart = tokenStart
        unless dType.paramsByName[part]
          return new CommandError("invalid property '#{part}', expected one of '#{dType.paramNames.join('\', \'')}'", line, tokenStart, tokenEnd)
      else
        unless argName
          # if no explicit name, infer name from argument position
          argName = dType.params[dArgs.length][0]
        dArgs.push [argName, number]
        argName = null

    unless dType
      return new CommandError('expected command', line, lineOffset, lineEnd)

    if argName
      return new CommandError("missing value for '#{argName}'", line, argNameTokenStart, lineEnd)

    return new Command(dType, dArgs, line, lineOffset, lineEnd)


  reformatCommandComment: (comment) ->
    parsed = @parseCommandComment(comment)
    if parsed.isError
      return null

    result = '//! ' + parsed.type.name
    if parsed.args.length > 0
      result += ': '
      for [argName, argValue], i in parsed.args
        if i > 0
          result += ', '
        result += argName + ' ' + argValue

    return result



# scan backwards in the tokens array from tokens[i] to find the preceding uniform on
# the same line e.g. `uniform vec2 u_name;`
# return e.g. {name: 'u_name', type: 'vec2'} if the previous statement on the same line
# was a uniform, null otherwise
findUniform = (tokens, i) ->
  prev3 = []
  while i >= 0 and prev3.length < 3
    token = tokens[i--]
    unless token.data.indexOf('\n') is -1
      break
    if token.type is 'line-comment' or token.type is 'block-comment' or token.type is 'whitespace' or token.data is ';'
      continue
    unless token.type is 'ident' or token.type is 'keyword'
      break
    prev3.unshift token.data

  unless prev3.length is 3
    return null

  unless prev3[0] is 'uniform'
    return null

  return {
    type: prev3[1]
    name: prev3[2]
  }




module.exports = CommandParser