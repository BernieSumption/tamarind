

class Tamarind.ConfigEditor extends Tamarind.UIComponent

  TEMPLATE = '''
    <div class="tamarind-editor tamarind-editor-config">

      <fieldset>
        <legend>Geometry</legend>
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

      </fieldset>

      <div class="tamarind-editor-config-inputs">
      </div>

      <fieldset>
        <legend>Inputs</legend>
        <p>Enter one input per line <a href="javascript:void(0)">describe format</a></p>
        <textarea>lala</textarea>
      </fieldset>

    </div>
  '''

  constructor: (state) ->
    super(state, TEMPLATE)


    @bindInputToState('vertexCount')
    @bindInputToState('drawingMode')

  _handleInputsChange: ->


    @_controlsByName = {}
    wrapper = @css '.tamarind-editor-config-inputs'
    wrapper.innerHTML = ''

    for input in inputs
      control = new Tamarind.InputEditor(input, @_state)
      control.appendTo wrapper
      @_controlsByName[input.name] = control

    return