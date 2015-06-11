InputControlBase = require './InputControlBase.coffee'


class ImageInputControl extends InputControlBase

  _formatValueForUser: ->
    return ''

  _makeInputElement: ->
    el = document.createElement 'img'
    el.src = @_command.getArg('src')
    el.width = 50
    el.height = 50
    return el


module.exports = ImageInputControl