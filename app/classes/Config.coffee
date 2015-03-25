

class Tamarind.ConfigEditor extends Tamarind.UIComponent

  TEMPLATE = '''
    <div class="tamarind-editor tamarind-editor-config">

      <p>
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

      </p>

      <p><label><input type="checkbox" name="debugMode"> debug mode (logs extra information to console)</label></p>

    </div>
  '''

  constructor: (state) ->
    super(state, TEMPLATE)


    @bindInputToState('vertexCount')
    @bindInputToState('drawingMode')
    @bindInputToState('debugMode')