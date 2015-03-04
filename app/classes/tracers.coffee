
###
  Outputs trace messages to the browser console
###
class ConsoleTracer

  # print a log statement
  log: (m) ->
    if window.console
      console.log m

  # print a error statement
  error: (m) ->
    if window.console
      console.error m

# Swallows trace messages silently
class NullTracer
  # do nothing
  log: ->
  # do nothing
  error: ->