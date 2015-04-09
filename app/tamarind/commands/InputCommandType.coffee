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
  # @param uiClass [Class] a subclass of InputControlBase
  constructor: (name, params, @dataLength = 1, @uiClass) ->
    super(name, params)
    @uniformType = UNIFORM_TYPE_SIZES[@dataLength]
    unless @uniformType
      throw new Error("Invalid dataLength '#{@dataLength}'")



  # Create an appropriate InputBase subclass instance to edit the supplied input
  # @param input [object] a validated input data object
  makeEditor: (input, state) ->
    return new @uiClass(input, state)


module.exports = InputCommandType