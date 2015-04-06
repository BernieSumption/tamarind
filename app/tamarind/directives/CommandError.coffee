

class CommandError

  isError: true

  constructor: (@message, @line, @start, @end) ->
    if arguments.length < 4
      throw new Error('not enough arguments')


module.exports = CommandError
