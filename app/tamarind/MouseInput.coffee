InputBase = require './InputBase.coffee'


class MouseInput extends InputBase

  @defaults:
    damping: 0
    value: [0, 0]

  @fieldOrder: ['damping']

  _getValue: ->
    return [@_mouseX, @_mouseY]


  onEachFrame: ->
    d = +@_data.damping
    mouseX = (1 - d) * @_state.mouseX + d * (@_mouseX or 0)
    mouseY = (1 - d) * @_state.mouseY + d * (@_mouseY or 0)
    unless @_mouseX is mouseX and @_mouseY is mouseY
      @_mouseX = mouseX
      @_mouseY = mouseY
      @_notifyOfValueChange()
    return



module.exports = MouseInput