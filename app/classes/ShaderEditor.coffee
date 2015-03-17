
replaceScriptTemplates = ->
  for scriptTemplate in document.querySelectorAll("script[type='application/x-tamarind-editor']")
    configJSON = scriptTemplate.text.trim()
    if configJSON.length > 0
      try
        config = JSON.parse(configJSON)
      catch e
        console.error 'Failed to parse Tamarind config: "' + e + '" in source:\n' + configJSON
        continue
    else
      config = {}

    editor = new ShaderEditor(scriptTemplate, config)


  return




class ShaderEditor extends EventEmitter

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
      <div class="tamarind-editor tamarind-editor-code">
        <div class="tamarind-program-error">
          <span class="CodeMirror-lint-marker-error"></span>
          <span class="tamarind-program-error-message"></span>
        </div>
      </div>
      <div class="tamarind-editor tamarind-editor-config">

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
    <div class="tamarind-render-panel">
      <canvas class="tamarind-render-canvas"></canvas>
    </div>
  """


  # @property [WebGLCanvas] the rendering canvas for this editor. Read-only.
  canvas: null


  # Create a new Tamarind editor
  # @param [HTMLElement] location an element in the DOM that will be removed and replaced with the Tamarind editor
  # @param [object] config, an map of values to be copied onto this object. Values are recursively merged into this
  #                         object, so e.g. {canvas: {vertexCount: 4}} will set `myShaderEditor.canvas.vertexCount = 4`
  #
  constructor: (location, config = {}) ->

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
    @_vertexCountInputElement = @_element.querySelector('[name="vertexCount"]')
    @_drawingModeInputElement = @_element.querySelector('[name="drawingMode"]')


    new ToggleBar(@_menuElement, @, MENU_ITEM_SELECT)

    @_canvas = new WebGLCanvas(@_renderCanvasElement)

    @_canvas.on WebGLCanvas.COMPILE, @_handleShaderCompile
    @_canvas.on WebGLCanvas.LINK, @_setProgramError

    @_shaderDocs = {}
    createDoc = (shaderType) =>
      doc = CodeMirror.Doc(@_canvas.getShaderSource(shaderType), 'clike')
      doc.shaderType = shaderType
      @_shaderDocs[shaderType] = doc
      return
    createDoc Tamarind.FRAGMENT_SHADER
    createDoc Tamarind.VERTEX_SHADER

    @_bindInputToCanvas(@_vertexCountInputElement, 'vertexCount', parseInt)
    @_bindInputToCanvas(@_drawingModeInputElement, 'drawingMode')


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


    @_programErrorElement = @_element.querySelector('.tamarind-program-error')
    @_setProgramError false

    # A bit hacky. This inserts out element into the start of the CodeMirror instance, which seems to be
    # the easiest way of getting the CodeMirror editing area to take up all the available height
    # minus the height used by the error notice. It's bad manners to tamper with a component's DOM, but
    # CodeMirror doesn't seem to mind.
    @_codemirror.display.wrapper.insertBefore @_programErrorElement, @_codemirror.display.wrapper.firstChild

    @on MENU_ITEM_SELECT, @_handleMenuItemSelect


    mergeObjects(config, @)


  reset: (config) ->
    mergeObjects(config, @)
    for type, doc of @_shaderDocs
      doc.setValue(@_canvas.getShaderSource(type))


  # @private
  _bindInputToCanvas: (input, propertyName, parseFunction = String) ->
    input.value = @_canvas[propertyName]

    input.addEventListener 'input', =>
      @_canvas[propertyName] = parseFunction(input.value)
      return

    return

  # @private
  # Handle CodeMirror lint events. These are fired a few hundred milliseconds after the user
  # has finished typing in an editor window, and we use them to update the shader source
  _handleCodeMirrorLint: (value, callback, options, cm) =>
    if @_codemirror
      @_canvas.setShaderSource(@_codemirror.getDoc().shaderType,  value)
    @_lintingCallback = callback
    return

  _handleShaderCompile: (compileEvent) =>
    if compileEvent.shaderType is @_activeCodeEditor
      errors = for err in compileEvent.errors
        message: err.message
        from: {line: err.line}
        to: {line: err.line}

      @_lintingCallback @_codemirror, errors
    return


  _setProgramError: (error) =>
    if error
      @_programErrorElement.style.display = ''
      msgElement = @_programErrorElement.querySelector('.tamarind-program-error-message')
      msgElement.innerHTML = ''
      msgElement.appendChild(document.createTextNode('Program error: ' + error))
    else
      @_programErrorElement.style.display = 'none'

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
  _handleMenuItemSelect: (item) ->
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


Tamarind.defineClassProperty(ShaderEditor, 'canvas')


# A set of links where at any one time, one link is highlighted with the 'is-selected' class.
class ToggleBar

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
mergeObjects = (source, dest) ->
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
      mergeObjects(sourceValue, destValue)
    else
      dest[prop] = sourceValue;
  return

