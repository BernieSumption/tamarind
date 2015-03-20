
# Poll until a predicate function returns true then execute a callback function
pollUntil = (predicate, callback, timeoutMs = 3000, pollFrequencyMs = 10) ->
  start = Date.now()
  handler = ->
    console.log Date.now() - start, predicate()
    expired = Date.now() - start > timeoutMs
    if expired or predicate()
      if expired
        console.log 'Condition never met: ' + predicate
      clearInterval interval
      callback()
    return
  interval = setInterval handler, pollFrequencyMs
  handler()
  return

# Expect a spy to have been called a specific number of times with specific arguments
# @param spyMethod [function] a function instrumented with spyOn()
# @param calls [Array] an array of call signatures, where each signature can be an array of arguments, or a single argument
expectCallHistory = (spyMethod, calls) ->
  callTimes = spyMethod.calls.count()
  expect(callTimes).toEqual calls.length
  if callTimes is calls.length
    for arg, i in calls
      unless Array.isArray(arg)
        arg = [arg]
      expect(spyMethod.calls.argsFor(i)).toEqual(arg)
