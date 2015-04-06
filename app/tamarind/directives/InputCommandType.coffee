CommandType = require('./CommandType.coffee')

UNIFORM_TYPE_SIZES = [
  undefined
  'float'
  'vec2'
  'vec3'
  'vec4'
]

class InputCommandType extends CommandType

  isUniformSuffix: true

  # @param dataLength [Number] 1 for float, 2 for vec2 etc
  constructor: (name, params, @dataLength = 1) ->
    super(name, params)
    @uniformType = UNIFORM_TYPE_SIZES[@dataLength]
    unless @uniformType
      throw new Error("Invalid dataLength '#{@dataLength}'")

module.exports = InputCommandType