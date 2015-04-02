constants = require '../constants.coffee'
filter = require 'lodash/collection/filter'


###
  Parses a GLSL program consisting of vertex and fragment shader, and provides
  information on the commands and command errors contained within.
###
class ProgramCommands

  # @param @_directives [Directives]
  constructor: (@_directives) ->
    @_shaders = {}
    @_shaders[constants.FRAGMENT_SHADER] =
      source: ''
      errors: []
    @_shaders[constants.VERTEX_SHADER] =
      source: ''
      errors: []

  setShaderSource: (shaderType, source) ->
    o = @_shaders[shaderType]

    if o.source is source
      return

    o.source = source

    ds = @_directives.parseGLSL(source)
    o.errors = filter ds, 'isError'

    return



  getCommandErrors: (shaderType) ->
    return @_shaders[shaderType].errors





module.exports = ProgramCommands
