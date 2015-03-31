UIComponent = require './UIComponent.coffee'
Inputs      = require './Inputs.coffee'


###
  A component that shows a list of UI controls that provide input to shaders
###
class ControlDrawer extends UIComponent

  TEMPLATE = '''
    <div class="tamarind-controls">
      <div class="tamarind-controls-background">
        <a href="javascript:void(0)" class="tamarind-controls-button tamarind-icon-controls"></a>
        <div class="tamarind-controls-ui">
        </div>
      </div>
    </div>
  '''


  constructor: (_state) ->
    super(_state, TEMPLATE)

    @_editorsByName = {}

    @css('.tamarind-controls-button').addEventListener 'click', @_toggleOpen

    @_state.onPropertyChange 'controlsExpanded', @_handleControlsExpandedChange
    @_handleControlsExpandedChange()

    @_state.onPropertyChange 'inputs', @_handleInputsChange
    @_handleInputsChange @_state.inputs

    @_state.on @_state.INPUT_VALUE_CHANGE, @_handleInputValueChange
    requestAnimationFrame @_handleAnimationFrame



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

    @_editorsByName = {}
    wrapper = @css '.tamarind-controls-ui'
    wrapper.innerHTML = ''

    for input in inputs
      editor = Inputs.makeEditor(input, @_state)
      editor.appendTo wrapper
      @_editorsByName[input.name] = editor

    return


  _handleInputValueChange: (inputName) =>
    @_editorsByName[inputName].setValue @_state.getInputValue(inputName)
    return

  _handleAnimationFrame: =>
    requestAnimationFrame @_handleAnimationFrame
    for name, editor of @_editorsByName
      editor.onEachFrame()


module.exports = ControlDrawer