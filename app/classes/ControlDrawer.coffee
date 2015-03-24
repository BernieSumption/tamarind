
###
  A component that shows a list of UI controls that provide input to shaders
###

class Tamarind.ControlDrawer

  TEMPLATE = '''
    <div class="tamarind-controls">
      <div class="tamarind-controls-background">
        <a href="javascript:void(0)" class="tamarind-controls-button tamarind-icon-controls"></a>
        <div class="tamarind-controls-ui">
        </div>
      </div>
    </div>
  '''

  CONTROL_TEMPLATE = '''
    <div class="tamarind-controls-control">
      <div class="tamarind-controls-control-title"></div>
      <div class="tamarind-controls-control-ui">
      </div>
    </div>
  '''


  constructor: (target, @_state) ->

    @_element = Tamarind.replaceElement target, TEMPLATE

    @_element.querySelector('.tamarind-controls-button').addEventListener 'click', @_toggleOpen

    @_state.onPropertyChange 'controlsExpanded', @_handleControlsExpandedChange
    @_handleControlsExpandedChange()

    @_state.onPropertyChange 'inputs', @_handleInputsChange
    @_handleInputsChange @_state.inputs

    @_state.on @_state.INPUT_VALUE_CHANGE, @_handleInputValueChange

    @_inputElementsByName = {}


  _toggleOpen: =>
    @_state.controlsExpanded = not @_state.controlsExpanded
    return


  # @private
  _handleControlsExpandedChange: =>
    if @_state.controlsExpanded
      @_element.classList.add 'is-selected'
    else
      @_element.classList.remove 'is-selected'
    return


  # @private
  _handleInputsChange: (inputs) =>

    if inputs.length > 0
      @_element.classList.add 'is-visible'
    else
      @_element.classList.remove 'is-visible'

    @_inputElementsByName = {}
    wrapper = @_element.querySelector '.tamarind-controls-ui'
    wrapper.innerHTML = ''

    for input in inputs
      el = Tamarind.parseHTML CONTROL_TEMPLATE
      title = el.querySelector('.tamarind-controls-control-title')
      title.innerHTML = ''
      title.appendChild document.createTextNode(input.name)
      el.querySelector('.tamarind-controls-control-ui').appendChild @_makeSliderInput input
      wrapper.appendChild el

    return



  _handleInputValueChange: (inputName) =>
    @_inputElementsByName[inputName].value = @_state.getInputValue(inputName)
    return


  _makeSliderInput: (input) ->
    el = document.createElement 'input'
    el.type = 'range'
    el.min = input.min
    el.max = input.max
    el.step = input.step
    el.value = input.value
    el.name = input.name
    @_inputElementsByName[input.name] = el
    el.addEventListener 'input', =>
      @_state.setInputValue input.name, parseFloat(el.value)
      return
    return el


