InputControlBase = require './InputControlBase.coffee'


class MouseInputControl extends InputControlBase

  _getValue: ->
    return [@_mouseX, @_mouseY]


  onEachFrame: ->
    d = +@_command.getArg('damping')
    mouseX = (1 - d) * @_state.mouseX + d * (@_mouseX or 0)
    mouseY = (1 - d) * @_state.mouseY + d * (@_mouseY or 0)
    unless @_mouseX is mouseX and @_mouseY is mouseY
      @_mouseX = mouseX
      @_mouseY = mouseY
      @_notifyOfValueChange()
    return



module.exports = MouseInputControl