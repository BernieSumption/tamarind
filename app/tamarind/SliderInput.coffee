InputBase = require './InputBase.coffee'


class SliderInput extends InputBase

  @defaults:
    min: 0
    max: 1
    step: 0.01
    value: [0]

  @fieldOrder: ['min', 'max', 'step']

  _getDisplayDP: ->
    # minimum decimal places to show full precision of step
    return ~~Math.max(0, Math.min(18, Math.ceil(Math.log10(1 / @_data.step))))

  _makeInputElement: ->
    el = document.createElement 'input'
    el.type = 'range'
    el.min = @_data.min
    el.max = @_data.max
    el.step = @_data.step
    el.addEventListener 'input', @_notifyOfValueChange
    return el


module.exports = SliderInput