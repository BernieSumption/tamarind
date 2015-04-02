indexBy = require 'lodash/collection/indexBy'
pluck = require 'lodash/collection/pluck'


class CommandType

  # @property [boolean] whether this command must appear after a uniform
  isUniformSuffix: false

  # @param @name the command name
  # @param @params an array of [name, defaultValue] pairs representing arguments to the command
  constructor: (@name, @params) ->
    @paramsByName = indexBy(@params, 0)
    @paramNames = pluck(@params, 0)

  toString: ->
    return "{CommandType #{@name}}"




module.exports = CommandType
