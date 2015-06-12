InputControlBase = require './InputControlBase.coffee'
TextureLoader = require '../TextureLoader.coffee'

class ImageInputControl extends InputControlBase

  _formatValueForUser: ->
    return ''

  _makeInputElement: ->
    el = document.createElement 'img'
    el.src = ''
    el.width = 50
    el.height = 50
    el.onclick = @_promptImageChange
    return el

  _updateInputElement: (value) ->
    if @_inputElement
      @_inputElement.src = TextureLoader.wrapInXOriginProxy(value[0])
    return

  # Return the current value of the input
  _getValue: ->
    return [@_inputElement.src]
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAGElEQVQYV2P8z8Dwn4EIwDiqEF8oUT94AGX8E/dUtCYYAAAAAElFTkSuQmCC'

  _promptImageChange: =>
    oldSrc = @_getValue
    newSrc = prompt('Enter an image URL', @_getValue())
    if newSrc and newSrc isnt oldSrc
      @_updateInputElement([newSrc])
      @_notifyOfValueChange()
    return


module.exports = ImageInputControl