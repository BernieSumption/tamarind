
###
  Superclass to handle event dispatch
###
class EventEmitter

  # Create a new EventEmitter
  constructor: ->
    @_events = {}


  # Register an event callback
  #
  # @param [string] eventName
  # @param [function] callback
  on: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList(eventName)
    if list.indexOf(callback) == -1
      list.push callback


  # Remove an event callback added with `on()`
  #
  # @param [string] eventName
  # @param [function] callback
  off: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList eventName
    index = list.indexOf callback
    unless index == -1
      list.splice index, 1
    return


  # Call all callback functions registered with an event
  #
  # @param [string] eventName
  # @param event the argument to be passed to the callback function
  emit: (eventName, event) ->
    @_validateEventArgs eventName
    for f in @_getEventList eventName
      f.call this, event


  # @private
  _getEventList: (eventName) ->
    unless @_events[eventName]
      @_events[eventName] = []
    @_events[eventName]


  # @private
  _validateEventArgs: (eventName, callback) ->
    if typeof eventName != "string"
      throw new Error("eventName must be a string")
    if arguments.length > 1 && typeof callback != "function"
      throw new Error("callback must be a function")