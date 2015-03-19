


class Tamarind.ShaderEditor

  CONFIG = 'config'
  MENU_ITEM_SELECT = 'menu-item-select'

  NOT_SUPPORTED_HTML = '''
    <span class="tamarind-icon-unhappy tamarind-unsupported-icon" title="And lo there shall be no editor, and in that place there shall be wailing and gnashing of teeth."></span>
    Your browser doesn't support this feature. Try Internet Explorer 11+ or recent versions of Chrome, Firefox or Safari.
  '''

  TEMPLATE = """
    <div class="tamarind-menu">
      <a href="javascript:void(0)" name="#{Tamarind.FRAGMENT_SHADER}" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader"></a>
      <a href="javascript:void(0)" name="#{Tamarind.VERTEX_SHADER}" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
      <a href="javascript:void(0)" name="#{CONFIG}" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
    </div>
    <div class="tamarind-editor-panel">
      <div class="tamarind-editor tamarind-editor-code"></div>
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
    </div>
    <div class="tamarind-render-panel">
      <canvas class="tamarind-render-canvas"></canvas>
    </div>
  """


  # @property [WebGLCanvas] the rendering canvas for this editor. Read-only.
  canvas: null


  # Create a new Tamarind editor
  # @param [HTMLElement] location an element in the DOM that will be removed and replaced with the Tamarind editor
  # @param [Tamarind.State] state A state object, or null to create one
  #
  constructor: (location, state = null) ->

    @_element = document.createElement('div')
    @_element.className = 'tamarind'
    @_element.editor = @
    location.parentNode.insertBefore @_element, location
    location.parentNode.removeChild location

    unless Tamarind.browserSupportsRequiredFeatures()
      @_element.innerHTML = NOT_SUPPORTED_HTML
      @_element.className += ' tamarind-unsupported'
      return
    else
      @_element.className = 'tamarind'


    @_element.innerHTML = TEMPLATE

    @_editorCodeElement = @_element.querySelector('.tamarind-editor-code')
    @_editorConfigElement = @_element.querySelector('.tamarind-editor-config')
    @_renderCanvasElement = @_element.querySelector('.tamarind-render-canvas')
    @_menuElement = @_element.querySelector('.tamarind-menu')

    @_state = state or new Tamarind.State()

    new Tamarind.ToggleBar(@_menuElement, @_state, MENU_ITEM_SELECT)

    @_canvas = new Tamarind.WebGLCanvas(@_renderCanvasElement, @_state)

    @_state.on @_state.SHADER_ERRORS_CHANGE, @_handleShaderErrorsChange

    @_shaderDocs = {}
    createDoc = (shaderType) =>
      doc = CodeMirror.Doc(@_state.getShaderSource(shaderType), 'clike')
      doc.shaderType = shaderType
      @_shaderDocs[shaderType] = doc
      return
    createDoc Tamarind.FRAGMENT_SHADER
    createDoc Tamarind.VERTEX_SHADER

    @_bindInputToCanvas('vertexCount')
    @_bindInputToCanvas('drawingMode')
    @_bindInputToCanvas('debugMode')

    @_codemirror = CodeMirror(@_editorCodeElement,
      value: @_shaderDocs[Tamarind.FRAGMENT_SHADER]
      lineNumbers: true
      lineWrapping: true
      gutters: ['CodeMirror-lint-markers']
      lint:
        getAnnotations: @_handleCodeMirrorLint
        async: true
        delay: 200
    )

    @_codemirror.on 'renderLine', @_addLineWrapIndent
    @_codemirror.refresh()

    @_state.on MENU_ITEM_SELECT, @_handleMenuItemSelect
    @_state.on @_state.SHADER_CHANGE, @_handleShanderChange


  # TODO unit tests for each kind of input
  # @private
  _bindInputToCanvas: (propertyName) ->
    input = @_element.querySelector("[name='#{propertyName}']")

    # figure out how to bind to this kind of element
    eventName = 'input'
    inputPropertyName = 'value'
    parseFunction = (v) -> v
    if input.type is 'number'
      parseFunction = parseInt
    else if input.type is 'checkbox'
      inputPropertyName = 'checked'
      eventName = 'change'

    # take the initial value from the state
    input[inputPropertyName] = @_state[propertyName]

    # update state when element changes
    input.addEventListener eventName, =>
      @_state[propertyName] = parseFunction(input[inputPropertyName])
      return

    # update element when state changes
    state.onPropertyChange propertyName, ->
      input[inputPropertyName] = @_state[propertyName]
      return

    return


  # @private
  _bindInputToCheckbox: (propertyName) ->
    checkbox = @_element.querySelector("[name='#{propertyName}']")

    checkbox.checked = @_state[propertyName]

    checkbox.addEventListener 'change', =>
      @_state[propertyName] = checkbox.checked
      return

    return


  # @private
  _bindCheckboxToCanvas: (propertyName, parseFunction = String) ->
    input = @_element.querySelector("[name='#{propertyName}']")

    input.checked = @_state[propertyName]

    input.addEventListener 'input', =>
      @_state[propertyName] = parseFunction(input.value)
      return

    return

  # @private
  # Handle CodeMirror lint events. These are fired a few hundred milliseconds after the user
  # has finished typing in an editor window, and we use them to update the shader source
  _handleCodeMirrorLint: (value, callback, options, cm) =>
    if @_codemirror
      @_state.setShaderSource(@_codemirror.getDoc().shaderType,  value)
    @_lintingCallback = callback
    return

  # @private
  # Update the UI when the shader is changed form the model
  _handleShanderChange: (shaderType) =>
    newSource = @_state.getShaderSource(shaderType)
    oldSource = @_shaderDocs[shaderType].getValue()
    unless newSource is oldSource
      @_shaderDocs[shaderType].setValue(newSource)
    return


  _handleShaderErrorsChange: (shaderType) =>
    if shaderType is @_activeCodeEditor
      errors = for err in @_state.getShaderErrors(shaderType)
        message: err.message
        from: {line: Math.max(err.line, 0)}
        to: {line: Math.max(err.line, 0)}

      @_lintingCallback @_codemirror, errors
    return

  # @private
  # indent wrapped lines. Based on http://codemirror.net/demo/indentwrap.html but this
  # version indents the wrapped line by a further 2 characters
  _addLineWrapIndent: (cm, line, elt) =>
    unless @_codeCharWidth
      @_codeCharWidth = @_codemirror.defaultCharWidth()

    basePadding = 4
    indentChars = 2
    offset = CodeMirror.countColumn(line.text, null, cm.getOption('tabSize')) * @_codeCharWidth
    elt.style.textIndent = '-' + (offset + @_codeCharWidth * indentChars) + 'px'
    elt.style.paddingLeft = (basePadding + offset + @_codeCharWidth * indentChars) + 'px'
    return

  # @private
  _handleMenuItemSelect: (item) =>
    if item is CONFIG
      @_editorCodeElement.style.display = 'none'
      @_editorConfigElement.style.display = ''
    else
      @_editorCodeElement.style.display = ''
      @_editorConfigElement.style.display = 'none'
      @_activeCodeEditor = item
      @_codemirror.swapDoc(@_shaderDocs[item])

    return


  _getCanvas: -> @_canvas


Tamarind.defineClassProperty(Tamarind.ShaderEditor, 'canvas')


# A set of links where at any one time, one link is highlighted with the 'is-selected' class.
class Tamarind.ToggleBar

  constructor: (@_parent, @_events, @_eventName) ->
    @_parent.addEventListener 'click', (event) => @selectChild(event.target)
    @_children = @_parent.querySelectorAll 'a'
    @_selectedChild = null
    @selectChild(@_children[0])

  selectChild: (childToSelect) =>
    if childToSelect not in @_children
      return
    if @_selectedChild is childToSelect
      return
    @_selectedChild = childToSelect
    for child in @_children
      if child is childToSelect
        child.classList.add('is-selected')
      else
        child.classList.remove('is-selected')

    setTimeout (=> @_events.emit @_eventName, @_selectedChild.name), 1
    return


# merge all properties of one object onto another, so for example
#
# `mergeObjects({x: 1, y: {z: 2}}, dest)`
#
# is the same as
#
# `dest.x = 1; dest.y.z = 2`
Tamarind.mergeObjects = (source, dest) ->
  for prop of source
    destValue = dest[prop]
    destType = typeof destValue
    sourceValue = source[prop]
    sourceType = typeof sourceValue
    unless sourceType is destType
      throw new Error("Can't merge property '#{prop}': source is #{sourceType} destination is #{destType}")


    if typeof destValue is 'object'
      unless typeof sourceValue is 'object'
        throw new Error("Can't merge simple source onto complex destination for property '#{prop}'")
      Tamarind.mergeObjects(sourceValue, destValue)
    else
      dest[prop] = sourceValue;
  return

