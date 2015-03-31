

class ShaderCompileError

  # return an array of ShaderCompileError objects representing all the errors
  # in the supplied error string
  @fromErrorMessage = (error) ->

    errors = []

    if error

      for line in error.split('\n')

        parts = /^ERROR:\s*\d+\s*:\s*(\d+|\?)\s*:\s*(.*)/.exec(line) or /^\((\d+),\s*\d+\):\s*(.*)/.exec(line)

        if parts
          line = parseInt(parts[1]) or 0
          errors.push( new ShaderCompileError(parts[2], line - 1) )

    return errors

  # @param message [String] the error message
  # @param the line number on which the error happened
  constructor: (@message, @line) ->



module.exports = ShaderCompileError