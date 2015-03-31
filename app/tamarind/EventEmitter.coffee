###
  Superclass to handle event dispatch
###
class EventEmitter

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
    callbacks = @_getEventList eventName
    @_isEmitting = eventName
    for f in callbacks
      f.call this, event
    @_isEmitting = false
    return


  # @private
  _getEventList: (eventName) ->
    unless @_events
      @_events = {}
    unless @_events[eventName]
      @_events[eventName] = []
    # if, somewhere further down the stack, we're currently emitting an
    # event of this type (e.g. an event handler is trying to remove itself)
    # then lazily clone the callback list to prevent from modifying the array
    # that emit() is looping over
    if @_isEmitting is eventName
      @_events[eventName] = @_events[eventName].slice()
      @_isEmitting = false
    return @_events[eventName]


  # @private
  _validateEventArgs: (eventName, callback) ->
    unless typeof eventName is 'string'
      throw new Error('eventName must be a string, not ' + JSON.stringify(eventName))
    if arguments.length > 1 and typeof callback isnt 'function'
      throw new Error('callback must be a function, not ' + JSON.stringify(callback))


module.exports = EventEmitter