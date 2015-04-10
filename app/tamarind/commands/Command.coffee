utils        = require '../utils.coffee'
CommandType  = require './CommandType.coffee'
zipObject    = require 'lodash/array/zipObject'

# Represents a command directive parsed from GLSL source code, e.g.
# `uniform float foo; //! slider`
class Command

  isError: false

  # @property [CommandType]
  type: null

  # an array of [name, value] pairs representing arguments supplied in source code,
  # before application of default values
  args: []

  # @property [int] the source code line on which this command was found
  line: 0

  # @property [int] the column index of the command comment (`//!`) start
  start: 0

  # @property [int] the column index of the command comment (`//!`) end
  end: 0

  constructor: (@type, @args, @line, @start, @end) ->
    utils.validateType(@type, CommandType, 'type')
    utils.validateType(@args, Array, 'args')
    utils.validateType(@line, 'number', 'line')
    utils.validateType(@start, 'number', 'start')
    utils.validateType(@end, 'number', 'end')
    @data = zipObject @type.params
    for [name, value] in @args
      utils.validateType(name, 'string', 'arg name')
      utils.validateType(value, 'number', 'arg value')
      @data[name] = value


  setUniform: (@uniformType, @uniformName) ->
    utils.validateType(@uniformType, 'string')
    utils.validateType(@uniformName, 'string')
    return

  isInput: ->
    return @type.isUniformSuffix

  isStandalone: ->
    return not @type.isUniformSuffix

  getArg: (name) ->
    value = @data[name]
    if value is undefined
      throw new Error("invalid arg name '#{name}'")
    return value


module.exports = Command