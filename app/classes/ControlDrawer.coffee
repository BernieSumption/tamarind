
###
  A component that shows a list of UI controls that provide input to shaders
###

class Tamarind.ControlDrawer

  TEMPLATE = '''
    <div class="tamarind-controls">
      <div class="tamarind-controls-background">
        <a href="javascript:void(0)" class="tamarind-controls-button tamarind-icon-controls"></a>
        <div class="tamarind-controls-ui">
          <input type="range" class="tamarind-range-input">
        </div>
      </div>
    </div>
  '''


  constructor: (target, @_state) ->

    @_element = Tamarind.replaceElement target, TEMPLATE

    @_element.querySelector('.tamarind-controls-button').addEventListener 'click', @_toggleOpen

    @_state.onPropertyChange 'controlsExpanded', @_handleControlsExpandedChange
    @_handleControlsExpandedChange()

    @_state.onPropertyChange 'inputs', @_handleInputsChange
    @_handleInputsChange()


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
  _handleInputsChange: =>
    inputs = @_state.inputs
    if inputs.length > 0
      @_element.classList.add 'is-visible'
    else
      @_element.classList.remove 'is-visible'
    return

