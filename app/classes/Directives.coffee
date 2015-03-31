

class Tamarind.Directives

  #pragma slider: step: 0.1

  # Update the directives array
  #
  # @param sources [array] a number of shader sources, typically the fragment and vertex shaders
  # @return [boolean] true if the directives have changed.
  update: (sources) ->



###
  A command embedded in GLSL source code with the form:

  `[uniform type name; ]//! command [: arg number [, arg value [, ...]]]`
###
class Tamarind.Directive

  # @property [object] if this directive suffixes a uniform declaration, this property
  # will be a {name: String, type:String} object describing the uniform
  uniform: null

  # @property [String] the directive command, e.g. "slider" to create a slider input
  command: ''

  # @property [object] a map of {arg: value} pairs
  args: []

  # The source code of the directive from the start of the uniform to the end of the line
  source: ''

  constructor: (@source) ->