InputBase = require './InputBase.coffee'


class ColorInput extends InputBase

  @defaults:
    value: [0, 0, 0]

  _getDisplayDP: ->
    # minimum decimal places to show full precision of step
    return ~~Math.max(0, Math.min(18, Math.ceil(Math.log10(1 / @_data.step))))


  # Return the current value of the input
  _getValue: ->
    # parse #RRGGBB value
    parts = @_inputElement.value.match(/\w\w/g)
    unless parts?.length is 3
      parts = ['00', '00', '00']

    @_lastValidValue = parts.map((v) -> parseInt(v, 16) / 255 or 0)
    return @_lastValidValue

  _parseValue: ->


  _updateInputElement: (value) ->
    hexValue = @_valueToHex value
    unless @_inputElement.value.toLowerCase() is hexValue.toLowerCase()
      @_inputElement.value = hexValue
    return

  _formatValueForUser: (value) ->
    if @_colorInputSupported
      return @_valueToHex value
    else
      return '#RRGGBB'

  _makeInputElement: ->
    el = document.createElement 'input'
    el.type = 'color'
    @_colorInputSupported = el.type is 'color'

    el.addEventListener 'input', =>
      if @_inputElement.value.match(/^\s*#[a-zA-Z0-9]{6}\s*$/)
        @_notifyOfValueChange()
      return
    el.addEventListener 'change', =>
      unless @_colorInputSupported
        @_updateInputElement(@_getValue()) # ensure text input is nicely formatted when we've finished
      @_notifyOfValueChange()
      return

    return el

  _valueToHex: (value) ->
    color = '#'
    for part in value
      hex = Math.round(part * 255).toString(16)
      if hex.length is 1
        hex = '0' + hex
      color += hex
    return color


module.exports = ColorInput
