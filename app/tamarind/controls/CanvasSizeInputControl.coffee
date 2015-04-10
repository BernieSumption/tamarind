InputControlBase = require './InputControlBase.coffee'


class CanvasSizeInputControl extends InputControlBase

  _getValue: ->
    console.log [@_canvasWidth, @_canvasHeight]
    return [@_canvasWidth, @_canvasHeight]


  onEachFrame: ->
    unless @_canvasWidth is @_state.canvasWidth and @_canvasHeight is @_state.canvasHeight
      @_canvasWidth = @_state.canvasWidth
      @_canvasHeight = @_state.canvasHeight
      @_notifyOfValueChange()
    return



module.exports = CanvasSizeInputControl