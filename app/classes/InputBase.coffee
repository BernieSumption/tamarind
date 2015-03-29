
###
  Base class for input editors. Instances of these classes encapsulate the controls used
  to edit the values of inputs, and the classes themselves contain metadata e.g. default values
###
class Tamarind.InputBase extends Tamarind.UIComponent

  TEMPLATE = '''
    <div class="tamarind-controls-control">
      <div class="tamarind-controls-control-title">
        <span class="tamarind-controls-control-name"></span>
        <span class="tamarind-controls-control-value"></span>
      </div>
      <div class="tamarind-controls-control-ui">
      </div>
    </div>
  '''


  @defaults:
    value: [0]

  @fieldOrder: []

  ##
  ## NOTE!
  ##
  ## It is important that this class and its subclasses don't have any references to
  ## their instances except through ControlDrawer. This includes registering for
  ## event listeners on the State.
  ##



  constructor: (@_data, _state) ->
    super(_state, TEMPLATE)
    @_inputElement = @_makeInputElement()
    if @_inputElement
      @css('.tamarind-controls-control-ui').appendChild @_inputElement
    @setInnerText '.tamarind-controls-control-name', @_data.name.replace(/^u_/, '').replace('_', ' ')
    @_valueDisplay = @css '.tamarind-controls-control-value'
    @_displayDP = @_getDisplayDP()
    @setValue(@_data.value)


  # Called by the ControlDrawer when this input's value in the state has been changed
  setValue: (value) ->
    @_updateInputElement value
    @setInnerText @_valueDisplay, @_formatValueForUser value
    return


  # called each frame unconditionally
  onEachFrame: () ->


    # return a DOM element for the user to interact with, or null of this kind of input doesn't have a DOM component
  _makeInputElement: ->
    return null


  _updateInputElement: (value) ->
    if @_inputElement
      @_inputElement.value = value[0]
    return


  _formatValueForUser: (value) ->
    return value.map((item) => item.toFixed(@_displayDP)).join(', ')


  # return the number of decimal places that values should be displayed to
  _getDisplayDP: ->
    return 2


  # Subclasses just arrange for this to be called when the input value changes
  _notifyOfValueChange: =>
    @_state.setInputValue(@_data.name, @_getValue())
    return


  # Return the current value of the input
  _getValue: ->
    if @_inputElement
      return [parseFloat(@_inputElement.value) or 0]
    return 0


  # Format a value for display to users
  _getPrettyValue: ->
    return String(@_getValue())
