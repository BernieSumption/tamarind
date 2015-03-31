# Tamarind library entry point
#
# Support AMD or CommonJS if we're in that kind of environment, else define a global window.Tamarind class.
#
((factory) ->
  if typeof define is 'function' and define.amd
    define factory
  if typeof module is 'object' and module.exports
    module.exports = factory
  else
    window.Tamarind = factory()
  return
)(-> return require './tamarind/Tamarind.coffee')
