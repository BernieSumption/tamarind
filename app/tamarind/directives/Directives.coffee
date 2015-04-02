indexBy = require 'lodash/collection/indexBy'
zipObject = require 'lodash/array/zipObject'
tokenize = require 'glsl-tokenizer/string'
DirectiveError = require('./DirectiveError.coffee')

class Directives

  constructor: (@_directiveTypes) ->
    @_typesByName = indexBy @_directiveTypes, 'name'


  parseGLSL: (glsl) ->
    tokens = tokenize glsl
    directives = []
    for token, i in tokens
      if token.data.indexOf('//!') is 0
        directive = @parseDirectiveComment token.data

        isOnNewLine = i is 0 or tokens[i - 1].data.indexOf('\n') > -1

        unless directive.isError
          directive.uniform = findUniform(tokens, i)
          if directive.type.isUniformSuffix is true
            if isOnNewLine or not directive.uniform
              directive = new DirectiveError("'#{directive.type.name}' command must appear directly after a uniform declaration", 0, token.data.length)


          else if directive.type.isUniformSuffix is false
            unless isOnNewLine
              directive = new DirectiveError("'#{directive.type.name}' command must appear on its own line", 0, token.data.length)

        directive.line = token.line - 1 # we use 0 indexed lines, glsl-tokenizer uses 1 indexed
        directive.lineOffset = token.column - token.data.length
        directives.push directive


    return directives


  # Parse a comment in the form //! directive: arg value, arg value
  # into an object with the following properties:
  #
  # - `type`: a DirectiveType subclass representing the directive
  # - `args`: an array of ['arg0', value] pairs representing supplied arguments
  # - `data`: argument map after applying default values for missing arguments
  parseDirectiveComment: (text) ->
    tokenEnd = 0
    tokenStart = 0
    dType = null
    dArgs = []
    dData = {}
    argName = null
    argNameTokenStart = null
    # state machine parser. Expects a directive name then a sequence of `argument-name number` arguments
    for part in text.match /([,:!\/\s]+|[^,:!\/\s]+)/g
      tokenStart = tokenEnd
      tokenEnd += part.length
      if /[,:!\/\s]/.test part
        continue

      if dType is null
        dType = @_typesByName[part]
        unless dType
          return new DirectiveError("invalid command '#{part}'", tokenStart, tokenEnd)
        dData = zipObject dType.params
        for key, value of dType.defaults
          result[key] = value
        continue

      if dArgs.length >= dType.params.length
        return new DirectiveError("too many arguments, expected at most #{dType.params.length} ('#{dType.paramNames.join('\', \'')}')", tokenStart, text.length)

      number = parseFloat part
      if isNaN number
        if argName
          return new DirectiveError("invalid value for '#{argName}', expected a number", argNameTokenStart, tokenEnd)
        argName = part
        argNameTokenStart = tokenStart
        unless dType.paramsByName[part]
          return new DirectiveError("invalid property '#{part}', expected one of '#{dType.paramNames.join('\', \'')}'", tokenStart, tokenEnd)
      else
        unless argName
          # if no explicit name, infer name from argument position
          argName = dType.params[dArgs.length][0]
        dArgs.push [argName, number]
        dData[argName] = number
        argName = null

    unless dType
      return new DirectiveError('expected command', 0, text.length)

    if argName
      return new DirectiveError("missing value for '#{argName}'", argNameTokenStart, text.length)

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




module.exports = Directives