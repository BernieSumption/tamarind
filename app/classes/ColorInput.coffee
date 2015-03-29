

class Tamarind.ColorInput extends Tamarind.InputBase

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
      return @_lastValidValue or @defaults.value

    @_lastValidValue = parts.map((v) -> parseInt(v, 16) / 255 or 0)
    return @_lastValidValue


  _updateInputElement: (value) ->
    @_inputElement.value = @_formatValueForUser value
    return

  _formatValueForUser: (value) ->
    color = '#'
    for part in value
      hex = Math.round(part * 255).toString(16)
      if hex.length is 1
        hex = '0' + hex
      color += hex
    return color

  _makeInputElement: ->
    el = document.createElement 'input'
    el.type = 'color'
    el.addEventListener 'input', @_notifyOfValueChange
    return el


