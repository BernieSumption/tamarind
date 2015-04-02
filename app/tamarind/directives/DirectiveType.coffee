indexBy = require 'lodash/collection/indexBy'
pluck = require 'lodash/collection/pluck'


class DirectiveType

  # @property [boolean] whether this directive must appear after a uniform
  isUniformSuffix: false

  # @param @name the directive name
  # @param @params an array of [name, defaultValue] pairs representing arguments to the directive
  constructor: (@name, @params) ->
    @paramsByName = indexBy(@params, 0)
    @paramNames = pluck(@params, 0)

  toString: ->
    return "{DirectiveType #{@name}}"




module.exports = DirectiveType
