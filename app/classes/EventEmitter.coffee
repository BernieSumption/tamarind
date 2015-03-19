
###
  Superclass to handle event dispatch
###
class Tamarind.EventEmitter

  # Register an event callback
  #
  # @param [string] eventName
  # @param [function] callback
  on: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList(eventName)
    if list.indexOf(callback) is -1
      list.push callback
    return


  # Remove an event callback added with `on()`
  #
  # @param [string] eventName
  # @param [function] callback
  off: (eventName, callback) ->
    @_validateEventArgs eventName, callback
    list = @_getEventList eventName
    index = list.indexOf callback
    unless index is -1
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
    return


  # @private
  _getEventList: (eventName) ->
    unless @_events
      @_events = {}
    unless @_events[eventName]
      @_events[eventName] = []
    return @_events[eventName]


  # @private
  _validateEventArgs: (eventName, callback) ->
    unless typeof eventName is 'string'
      throw new Error('eventName must be a string')
    if arguments.length > 1 and typeof callback isnt 'function'
      throw new Error('callback must be a function')