InputControlBase = require './InputControlBase.coffee'


class SliderInputControl extends InputControlBase


  _getDisplayDP: ->
    # minimum decimal places to show full precision of step
    return ~~Math.max(0, Math.min(18, Math.ceil(Math.log10(1 / @_command.getArg('step')))))

  _makeInputElement: ->
    el = document.createElement 'input'
    el.type = 'range'
    el.min = @_command.getArg('min')
    el.max = @_command.getArg('max')
    el.step = @_command.getArg('step')
    el.addEventListener 'input', @_notifyOfValueChange
    return el


module.exports = SliderInputControl