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
    for token in tokens
      if token.data.indexOf('//!' is 0)
        directives.push @_parseDirectiveComment token.data


  _parseDirectiveComment: (text) ->
    tokenEnd = 0
    tokenStart = 0
    dType = null # DirectiveType object
    dArgs = []   # supplied arguments as [name, value] pairs
    dData = {}   # effective arguments, including default values
    argName = null
    # state machine parser. Expects a directive name then a sequence of `argument-name number` arguments
    for token in text.match /([,:!\/\s]+|[^,:!\/\s]+)/g
      tokenStart = tokenEnd
      tokenEnd += token.length
      if /[,:!\/\s]/.test token
        continue

      if dType is null
        dType = @_typesByName[token]
        unless dType
          return new DirectiveError("invalid command '#{token}'", tokenStart, tokenEnd)
        dData = zipObject dType.params
        for key, value of dType.defaults
          result[key] = value
        continue

      if dArgs.length >= dType.params.length
        return new DirectiveError("too many arguments, expected at most #{dType.params.length} ('#{dType.paramNames.join('\', \'')}')", tokenStart, text.length)

      number = parseFloat token
      if isNaN number
        if argName
          return new DirectiveError("invalid value for '#{argName}', expected a number", tokenStart, tokenEnd)
        argName = token
        unless dType.paramsByName[token]
          return new DirectiveError("invalid property '#{token}', expected one of '#{dType.fieldOrder.join('\', \'')}'", tokenStart, tokenEnd)
      else
        unless argName
          # if no explicit name, infer name from argument position
          argName = dType.params[dArgs.length][0]
        dArgs.push [argName, number]
        dData[argName] = number
        argName = null

    unless dType
      return new DirectiveError("expected command", 0, text.length)

    return {
      type: dType
      args: dArgs
      data: dData
    }




###
  A command embedded in GLSL source code with the form:

  `[uniform type name; ]//! command [: arg number [, arg value [, ...]]]`
###
class Directive

  # @property [object] if this directive suffixes a uniform declaration, this property
  # will be a {name: String, type:String} object describing the uniform
  uniform: null

  # @property [String] the directive command, e.g. "slider" to create a slider input
  command: ''

  # @property [object] a map of {arg: value} pairs
  args: {}

  # The source code of the directive from the start of the uniform to the end of the line
  source: ''

  constructor: (@source) ->



module.exports = Directives