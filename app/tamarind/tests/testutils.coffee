Inputs = require('../Inputs.coffee')

module.exports =

  # Poll until a predicate function returns true then execute a callback function
  pollUntil: (predicate, callback, timeoutMs = 3000, pollFrequencyMs = 10) ->
    start = Date.now()
    handler = ->
      expired = Date.now() - start > timeoutMs
      if expired or predicate()
        if expired
          console.error 'Condition never met: ' + predicate
        clearInterval interval
        callback()
      return
    interval = setInterval handler, pollFrequencyMs
    handler()
    return

  # Expect a spy to have been called a specific number of times with specific arguments
  # @param spyMethod [function] a function instrumented with spyOn()
  # @param calls [Array] an array of call signatures, where each signature can be an array of arguments, or a single argument
  expectCallHistory: (spyMethod, calls) ->
    realCalls = for call in calls
      [ call ]
    expect(spyMethod.calls.allArgs()).toEqual(realCalls)
    return


  # return a slider input with default values, unless overridden
  mockInput: (overrides = {}) ->
    input = {
      type: 'slider'
      name: 'my_slider'
    }
    for k, v of Inputs.inputClasses.slider.defaults
      input[k] = v
    for k, v of overrides
      input[k] = v
    return input


  # return a slider input with non-default values
  interestingInput: (overrides = {}) ->
    input = module.exports.mockInput(
      min: -10
      max: 10
      step: 1
      value: [5]
    )
    for k, v of overrides
      input[k] = v
    return input

