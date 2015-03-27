

class Tamarind.ConfigEditor extends Tamarind.UIComponent

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
    @_codemirror.on 'change', => return @_setDirty(true)

    @_state.onPropertyChange 'inputs', @_setValueFromState
    @_setValueFromState()

    @css('.tamarind-button[value="cancel"]').addEventListener 'click', @_cancelCurrentEdit
    @css('.tamarind-button[value="apply"]').addEventListener 'click', @_commitCurrentEdit

    @_setupAddInputDropdown()



  setVisible: (value) ->
    super(value)
    if value
      @_codemirror.refresh()

  _getLintAnnotations: (value) ->
    result = []
    for lineResult, i in Tamarind.Inputs.parseLines(value)
      if lineResult instanceof Tamarind.InputDefinitionError
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

  _setValueFromState: =>
    value = Tamarind.Inputs.unparseLines(@_state.inputs)
    @_valueBeforeEdit = value
    @_codemirror.setValue value
    @_setDirty false

  _commitCurrentEdit: =>
    @_codemirror.getInputField().blur()
    requestAnimationFrame =>
      @_state.inputs = Tamarind.Inputs.parseLines(@_codemirror.getValue(), true)
      @_setDirty false

  _cancelCurrentEdit: =>
    @_codemirror.getInputField().blur()
    requestAnimationFrame =>
      @_codemirror.setValue @_valueBeforeEdit
      @_setDirty false

  _setupAddInputDropdown: ->
    dropdown = @css('select[name="addANew"]')
    for inputType of Tamarind.Inputs.getTypes()
      dropdown.appendChild(Tamarind.parseHTML("<option>#{inputType}</option>"))
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
      @_state.inputs = inputs
      dropdown.selectedIndex = 0


