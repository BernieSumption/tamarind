InputControlBase = require './InputControlBase.coffee'


class TimeInputControl extends InputControlBase

  _getValue: ->
    return [@_value]


  onEachFrame: (timer) ->
    @_value = timer / 1000
    @_notifyOfValueChange()
    return



module.exports = TimeInputControl