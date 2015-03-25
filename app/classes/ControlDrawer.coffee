
###
  A component that shows a list of UI controls that provide input to shaders
###

class Tamarind.ControlDrawer extends Tamarind.UIComponent

  TEMPLATE = '''
    <div class="tamarind-controls">
      <div class="tamarind-controls-background">
        <a href="javascript:void(0)" class="tamarind-controls-button tamarind-icon-controls"></a>
        <div class="tamarind-controls-ui">
        </div>
      </div>
    </div>
  '''


  constructor: (state) ->
    super(state, TEMPLATE)

    @css('.tamarind-controls-button').addEventListener 'click', @_toggleOpen

    @_state.onPropertyChange 'controlsExpanded', @_handleControlsExpandedChange
    @_handleControlsExpandedChange()

    @_state.onPropertyChange 'inputs', @_handleInputsChange
    @_handleInputsChange @_state.inputs

    @_state.on @_state.INPUT_VALUE_CHANGE, @_handleInputValueChange

    @_controlsByName = {}


  _toggleOpen: =>
    @_state.controlsExpanded = not @_state.controlsExpanded
    return


  # @private
  _handleControlsExpandedChange: =>
    @setClassIf('is-expanded', @_state.controlsExpanded)
    return


  # @private
  _handleInputsChange: (inputs) =>

    @setClassIf('is-visible', inputs.length > 0)

    @_controlsByName = {}
    wrapper = @css '.tamarind-controls-ui'
    wrapper.innerHTML = ''

    for input in inputs
      control = new Tamarind.Control(input, @_state)
      control.appendTo wrapper
      @_controlsByName[input.name] = control

    return



  _handleInputValueChange: (inputName) =>
    @_controlsByName[inputName].setValue @_state.getInputValue(inputName)
    return


class Tamarind.Control extends Tamarind.UIComponent

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

  constructor: (@input, state) ->
    super(state, TEMPLATE)
    @inputElement = @_makeSliderInput()
    @css('.tamarind-controls-control-ui').appendChild @inputElement
    @setInnerText '.tamarind-controls-control-name', @input.name
    @setValue(@input.value)


  setValue: (value) ->
    @inputElement.value = value
    # minimum decimal places to show full precision of step
    dp = Math.max(0, Math.min(18, Math.ceil(Math.log10(1 / @input.step))))
    @setInnerText '.tamarind-controls-control-value', value.toFixed(dp)
    return


  _makeSliderInput: ->
    el = document.createElement 'input'
    el.type = 'range'
    el.min = @input.min
    el.max = @input.max
    el.step = @input.step
    el.value = @input.value
    el.name = @input.name
    el.addEventListener 'input', =>
      @_state.setInputValue @input.name, parseFloat(el.value)
      return
    return el