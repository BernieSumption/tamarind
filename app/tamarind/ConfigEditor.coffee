UIComponent = require './UIComponent.coffee'
Inputs      = require './Inputs.coffee'
utils       = require './utils.coffee'
CodeMirror  = require 'CodeMirror'


class ConfigEditor extends UIComponent

  TEMPLATE = '''
    <div class="tamarind-editor tamarind-editor-config">

      <div class="tamarind-fieldset">
        <span class="tamarind-fieldset-label">Geometry</span>
        <div class="tamarind-fieldset-group">
          Render
          <input type="number" name="vertexCount" min="1" class="tamarind-number-input">

          vertices as

          <select name="drawingMode">
              <option>POINTS</option>
              <option>LINES</option>
              <option>LINE_LOOP</option>
              <option>LINE_STRIP</option>
              <option>TRIANGLES</option>
              <option>TRIANGLE_STRIP</option>
              <option>TRIANGLE_FAN</option>
          </select>
        </div>

      </div>

      <div class="tamarind-fieldset">
        <span class="tamarind-fieldset-label">Inputs</span>
        <div class="tamarind-fieldset-group">
          <select name="addANew">
              <option>Add a new...</option>
          </select>
        </div>
        <div class="tamarind-fieldset-group">
          <div class="tamarind-editor-config-inputs"></div>
          <div class="tamarind-editor-config-buttons">
            <input type="button" value="cancel" class="tamarind-button" title="[Ctrl + C]">
            <input type="submit" value="apply" class="tamarind-button" title="[Ctrl + Enter]">
          </div>
        </div>
      </div>

    </div>
  '''


  constructor: (state) ->
    super(state, TEMPLATE)


    @bindInputToState('vertexCount')
    @bindInputToState('drawingMode')

    @_codemirror = CodeMirror(@css('.tamarind-editor-config-inputs'),
      value: ''
      mode: 'text'
      wrap: true
      viewportMargin: Infinity
      placeholder: 'Add inputs here e.g. "slider mySlider"'
      gutters: ['CodeMirror-lint-markers']
      lint:
        getAnnotations: @_getLintAnnotations
      extraKeys:
        'Ctrl-Enter': @_commitCurrentEdit
        'Cmd-Enter': @_commitCurrentEdit
        'Ctrl-C': @_cancelCurrentEdit
        'Cmd-.': @_cancelCurrentEdit
    )
    @_codemirror.on 'change', => @_setDirty(true)

    @_state.onPropertyChange 'inputs', @_setValueFromState
    @_setValueFromState()

    @css('.tamarind-button[value="cancel"]').addEventListener 'click', @_cancelCurrentEdit
    @css('.tamarind-button[value="apply"]').addEventListener 'click', @_commitCurrentEdit

    @_setupAddInputDropdown()



  setVisible: (value) ->
    super(value)
    if value
      @_codemirror.refresh()
    return

  _getLintAnnotations: (value) ->
    result = []
    for lineResult, i in Inputs.parseLines(value)
      if lineResult instanceof InputDefinitionError
        result.push({
          message: lineResult.message
          from:
            line: i
            ch: lineResult.start
          to:
            line: i
            ch: lineResult.end
        })
    return result

  _setDirty: (value) ->
    @setClassIf 'is-dirty', value
    return

  _setValueFromState: =>
    value = Inputs.unparseLines(@_state.inputs)
    @_valueBeforeEdit = value
    @_codemirror.setValue value
    @_setDirty false
    return


  _commitCurrentEdit: =>
    @_codemirror.getInputField().blur()
    requestAnimationFrame =>
      @_state.setInputs Inputs.parseLines(@_codemirror.getValue(), true), true # preserve existing values
      @_setDirty false
      return
    return

  _cancelCurrentEdit: =>
    @_codemirror.getInputField().blur()
    requestAnimationFrame =>
      @_codemirror.setValue @_valueBeforeEdit
      @_setDirty false
      return
    return

  _setupAddInputDropdown: ->
    dropdown = @css('select[name="addANew"]')
    for inputType in Inputs.getTypes()
      dropdown.appendChild(utils.parseHTML("<option>#{inputType}</option>"))
    dropdown.addEventListener 'change', =>
      inputs = @_state.inputs
      name = 'u_' + dropdown.value
      suffix = ''
      while @_state.hasInput(name + suffix)
        suffix = (~~suffix) + 1 # HACK!
      inputs.push {
        type: dropdown.value
        name: name + suffix
      }
      @_state.setInputs inputs
      dropdown.selectedIndex = 0
      return
    return


module.exports = ConfigEditor