
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

  TEMPLATE = """
    <div class="tamarind-menu">
      <a href="javascript:void(0)" name="#{Tamarind.FRAGMENT_SHADER}" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader"></a>
      <a href="javascript:void(0)" name="#{Tamarind.VERTEX_SHADER}" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
      <a href="javascript:void(0)" name="#{CONFIG}" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
    </div>
    <div class="tamarind-editor-panel">
      <div class="tamarind-editor tamarind-editor-code"></div>
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
    <span class="tamarind-logo"></span>
  """




  # Create a new Tamarind editor
  # @param [HTMLElement] location an element in the DOM that will be removed and replaced with the Tamarind editor
  # @param [object] config, an map of values to be copied onto this object. Values are recursively merged into this
  #                         object, so e.g. {canvas: {vertexCount: 4}} will set `myShaderEditor.canvas.vertexCount = 4`
  #
  constructor: (location, config = {}) ->

    @_element = document.createElement('div')
    @_element.className = 'tamarind'
    @_element.innerHTML = TEMPLATE
    @_element.editor = @

    @_editorCodeElement = @_element.querySelector('.tamarind-editor-code')
    @_editorConfigElement = @_element.querySelector('.tamarind-editor-config')
    @_renderCanvasElement = @_element.querySelector('.tamarind-render-canvas')
    @_menuElement = @_element.querySelector('.tamarind-menu')
    @_vertexCountInputElement = @_element.querySelector('[name="vertexCount"]')
    @_drawingModeInputElement = @_element.querySelector('[name="drawingMode"]')


    new ToggleBar(@_menuElement, @, MENU_ITEM_SELECT)

    @canvas = new WebGLCanvas(@_renderCanvasElement)

    @canvas.on WebGLCanvas.COMPILE, @_handleShaderCompile

    @_activeCodeEditor = Tamarind.FRAGMENT_SHADER
    @_fragmentShaderDoc = CodeMirror.Doc(@canvas.fragmentShaderSource, 'clike')
    @_vertexShaderDoc = CodeMirror.Doc(@canvas.vertexShaderSource, 'clike')
    @_bindInputToCanvas(@_vertexCountInputElement, 'vertexCount', parseInt)
    @_bindInputToCanvas(@_drawingModeInputElement, 'drawingMode')


    @_codemirror = CodeMirror(@_editorCodeElement,
      value: @_fragmentShaderDoc
      lineNumbers: true
      lineWrapping: true
      gutters: ['CodeMirror-lint-markers'],
      lint:
        getAnnotations: @_handleCodeMirrorLint
        async: true
        delay: 200
    )

    @_codemirror.on 'renderLine', @_addLineWrapIndent
    @_codemirror.refresh()

    @on MENU_ITEM_SELECT, @_handleMenuItemSelect


    mergeObjects(config, @)


    location.parentNode.insertBefore @_element, location
    location.parentNode.removeChild location



  _bindInputToCanvas: (input, propertyName, type) ->
    input.value = @canvas[propertyName]

    update = =>
      @canvas[propertyName] = if type then type(input.value) else input.value
      return

    input.addEventListener 'input', update
    return


  _handleCodeMirrorLint: (value, callback, options, cm) =>
    if @_activeCodeEditor is Tamarind.FRAGMENT_SHADER
      @canvas.fragmentShaderSource = value
    else
      @canvas.vertexShaderSource = value
    @_lintingCallback = callback
    return

  _handleShaderCompile: (compileEvent) =>
    if compileEvent.shaderType is @_activeCodeEditor
      @_lintingCallback @_codemirror, compileEvent.errors
    return



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

  _handleMenuItemSelect: (item) ->
    if item is CONFIG
      @_editorCodeElement.style.display = 'none'
      @_editorConfigElement.style.display = ''
    else
      @_editorCodeElement.style.display = ''
      @_editorConfigElement.style.display = 'none'
      @_activeCodeEditor = item

    if item is Tamarind.FRAGMENT_SHADER
      @_codemirror.swapDoc(@_fragmentShaderDoc)
    if item is Tamarind.VERTEX_SHADER
      @_codemirror.swapDoc(@_vertexShaderDoc)

    return


# A set of links where at any one time, one link is .
class ToggleBar

  constructor: (@_parent, @_events, @_eventName) ->
    @_parent.addEventListener 'click', (event) => @selectChild(event.target)
    @_children = @_parent.querySelectorAll 'a'
    @_selectedChild = null
    @selectChild(@_children[0])

  selectChild: (childToSelect) =>
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


CodeMirror.registerHelper 'lint', 'json', (text) ->
  found = []

  jsonlint.parseError = (str, hash) ->
    loc = hash.loc
    found.push
      from: CodeMirror.Pos(loc.first_line - 1, loc.first_column)
      to: CodeMirror.Pos(loc.last_line - 1, loc.last_column)
      message: str
    return

  try
    jsonlint.parse text
  catch e

  return found