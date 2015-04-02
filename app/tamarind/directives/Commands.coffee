indexBy = require 'lodash/collection/indexBy'
zipObject = require 'lodash/array/zipObject'
tokenize = require 'glsl-tokenizer/string'
CommandError = require('./CommandError.coffee')

class Commands

  constructor: (@_commandTypes) ->
    @_typesByName = indexBy @_commandTypes, 'name'


  parseGLSL: (glsl) ->
    tokens = tokenize glsl
    commands = []
    for token, i in tokens
      if token.data.indexOf('//!') is 0
        command = @parseCommandComment token.data

        isOnNewLine = i is 0 or tokens[i - 1].data.indexOf('\n') > -1

        unless command.isError
          command.uniform = findUniform(tokens, i)
          if command.type.isUniformSuffix is true
            if isOnNewLine or not command.uniform
              command = new CommandError("'#{command.type.name}' command must appear directly after a uniform declaration", 0, token.data.length)


          else if command.type.isUniformSuffix is false
            unless isOnNewLine
              command = new CommandError("'#{command.type.name}' command must appear on its own line", 0, token.data.length)

        command.line = token.line - 1 # we use 0 indexed lines, glsl-tokenizer uses 1 indexed
        command.lineOffset = token.column - token.data.length
        commands.push command


    return commands


  # Parse a comment in the form //! command: arg value, arg value
  # into an object with the following properties:
  #
  # - `type`: a CommandType subclass representing the command
  # - `args`: an array of ['arg0', value] pairs representing supplied arguments
  # - `data`: argument map after applying default values for missing arguments
  parseCommandComment: (text) ->
    tokenEnd = 0
    tokenStart = 0
    dType = null
    dArgs = []
    dData = {}
    argName = null
    argNameTokenStart = null
    # state machine parser. Expects a command name then a sequence of `argument-name number` arguments
    for part in text.match /([,:!\/\s]+|[^,:!\/\s]+)/g
      tokenStart = tokenEnd
      tokenEnd += part.length
      if /[,:!\/\s]/.test part
        continue

      if dType is null
        dType = @_typesByName[part]
        unless dType
          return new CommandError("invalid command '#{part}'", tokenStart, tokenEnd)
        dData = zipObject dType.params
        for key, value of dType.defaults
          result[key] = value
        continue

      if dArgs.length >= dType.params.length
        return new CommandError("too many arguments, expected at most #{dType.params.length} ('#{dType.paramNames.join('\', \'')}')", tokenStart, text.length)

      number = parseFloat part
      if isNaN number
        if argName
          return new CommandError("invalid value for '#{argName}', expected a number", argNameTokenStart, tokenEnd)
        argName = part
        argNameTokenStart = tokenStart
        unless dType.paramsByName[part]
          return new CommandError("invalid property '#{part}', expected one of '#{dType.paramNames.join('\', \'')}'", tokenStart, tokenEnd)
      else
        unless argName
          # if no explicit name, infer name from argument position
          argName = dType.params[dArgs.length][0]
        dArgs.push [argName, number]
        dData[argName] = number
        argName = null

    unless dType
      return new CommandError('expected command', 0, text.length)

    if argName
      return new CommandError("missing value for '#{argName}'", argNameTokenStart, text.length)

    return {
      isError: false
      type: dType
      args: dArgs
      data: dData
    }


# scan backwards in the tokens array from tokens[start] to find the preceding uniform
# e.g. `uniform vec2 u_name;`
# return e.g. {name: 'u_name', type: 'vec2'} if the previous statement was a uniform,
# null otherwise
findUniform = (tokens, i) ->
  prev3 = []
  while i >= 0 and prev3.length < 3
    token = tokens[i--]
    if token.type is 'line-comment' or token.type is 'block-comment' or token.type is 'whitespace' or token.data is ';'
      continue
    unless token.type is 'ident' or token.type is 'keyword'
      return null
    prev3.unshift token.data

  unless prev3.length is 3
    return null

  unless prev3[0] is 'uniform'
    return null

  return {
    type: prev3[1]
    name: prev3[2]
  }




module.exports = Commands