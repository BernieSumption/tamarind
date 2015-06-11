CommandType = require('./CommandType.coffee')

UNIFORM_TYPE_SIZES =
  float: 1
  vec2: 2
  vec3: 3
  vec4: 4
  sampler2D: 1


class InputCommandType extends CommandType

  isUniformSuffix: true

  # @param dataLength [Number] 1, 2, 3 or 4 for float, vec2 etc, or 'sampler2D' for textures
  # @param uiClass [Class] a subclass of InputControlBase
  constructor: (name, params, @uniformType = 'float', @uiClass) ->
    super(name, params)

    @dataLength = UNIFORM_TYPE_SIZES[@uniformType]
    unless @dataLength
      throw new Error("Invalid uniform type '#{@uniformType}'")



  # Create an appropriate InputBase subclass instance to edit the supplied input
  # @param input [object] a validated input data object
  makeEditor: (input, state) ->
    return new @uiClass(input, state)


module.exports = InputCommandType