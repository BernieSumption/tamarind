

class DirectiveError

  isError: true

  constructor: (@message, @start, @end, @token) ->


module.exports = DirectiveError
