

class CommandError

  isError: true

  constructor: (@message, @start, @end, @token) ->


module.exports = CommandError
