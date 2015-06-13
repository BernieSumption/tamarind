InputControlBase = require './InputControlBase.coffee'
TextureLoader = require '../TextureLoader.coffee'

class ImageInputControl extends InputControlBase

  _formatValueForUser: ->
    return ''

  _makeInputElement: ->
    el = document.createElement 'img'
    el.width = 50
    el.height = 50
    el.onclick = @_promptImageChange
    return el

  _updateInputElement: (value) ->
    @_src = value[0]
    console.log 'setting', value
    if @_inputElement
      @_inputElement.src = TextureLoader.wrapInXOriginProxy(value[0])
    return

  # Return the current value of the input
  _getValue: ->
    return [@_src || ""]

  _promptImageChange: =>
    oldSrc = @_src
    newSrc = prompt('Enter an image URL', @_src || "")
    if newSrc and newSrc isnt oldSrc
      @_src = newSrc
      @_notifyOfValueChange()
    return


module.exports = ImageInputControl