std_command_parser = require '../commands/std_command_parser.coffee'

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


  # return a slider input with non-default values
  mockSliderInput: (overrides = {}) ->

    name = overrides.name or 'my_slider'
    min  = overrides.min or -10
    max  = overrides.max or 10
    step = overrides.step or 1

    return std_command_parser.parseGLSL("uniform float #{name}; //! slider min #{min} max #{max} step #{step}")[0]

  mockColorInput: (overrides = {}) ->

    name = overrides.name or 'my_color'

    return std_command_parser.parseGLSL("uniform vec3 #{name}; //! color")[0]


  # similar to expect(test).toEqual(jasmine.objectContaining(properties)) but with more
  # readable error messages and optionally both test and properties can be an array
  expectProperties: (test, properties) ->
    expect(test).toBeTruthy()
    if test
      if Array.isArray(properties)
        if test.length is properties.length
          for testItem, index in test
            module.exports.expectProperties testItem, properties[index]
        else
          expect(test).toEqual properties
      else
        for k, v of properties
          if v instanceof RegExp
            expect(test[k]).toMatch(v)
          else
            expect(test[k]).toEqual v


  stateListener: (state) ->

    listener = {}

    for prop in ['SHADER_CHANGE', 'SHADER_ERRORS_CHANGE', 'CHANGE', 'INPUT_VALUE_CHANGE']
      listener[prop] = ->
      spyOn(listener, prop)
      state.on state[prop], listener[prop]

    for prop in ['vertexCount', 'drawingMode', 'selectedTab', 'controlsExpanded', 'inputs']
      listener[prop] = ->
      spyOn(listener, prop)
      state.onPropertyChange prop, listener[prop]


    return listener

  eventHandlerChain: (emitter, eventName, handlers) ->
    handlerIndex = 0
    emitter.on eventName, (arg) ->
      handler = handlers[handlerIndex++]
      if handler
        handler(arg)
      return

    return

