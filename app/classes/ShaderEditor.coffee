
replaceScriptTemplates = ->
  for scriptTemplate in document.querySelectorAll("script[type='application/x-tamarind-editor']")
    configJSON = scriptTemplate.text.trim()
    if configJSON.length > 0
      try
        config = JSON.parse(configJSON)
      catch e
        console.error "Failed to parse Tamarind config: \"" + e + "\" in source:\n" + configJSON
        continue
    else
      config = {}

    editor = new ShaderEditor(scriptTemplate, config)


  return




class ShaderEditor extends EventEmitter

  FRAGMENT_SHADER = 'fragment-shader'
  VERTEX_SHADER = 'vertex-shader'
  CONFIG = 'config'
  MENU_ITEM_SELECT = 'menu-item-select'

  TEMPLATE = """
    <div class="tamarind-menu">
      <a href="javascript:void(0)" name="#{FRAGMENT_SHADER}" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader"></a>
      <a href="javascript:void(0)" name="#{VERTEX_SHADER}" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
      <a href="javascript:void(0)" name="#{CONFIG}" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
    </div>
    <div class="tamarind-editor-panel">
      <div class="tamarind-editor tamarind-editor-code"></div>
      <!--<div class="tamarind-editor tamarind-editor-config"></div>-->
    </div>
    <div class="tamarind-render-panel">
      <canvas class="tamarind-render-canvas"></canvas>
    </div>
    <span class="tamarind-logo"></span>
  """




  # Create a new Tamarind editor
  # @param [HTMLElement] location an element in the DOM that will be removed and replaced with the Tamarind editor
  constructor: (location, @_config = {}) ->

    @element = document.createElement("div")
    @element.className = "tamarind"
    @element.innerHTML = TEMPLATE
    @element.editor = @

    location.parentNode.insertBefore @element, location
    location.parentNode.removeChild location


    new ToggleBar(@element.querySelector(".tamarind-menu"), @, MENU_ITEM_SELECT)

    @_canvas = new WebGLCanvas(@element.querySelector(".tamarind-render-canvas"))


    @_fragmentShaderDoc = @_bindDocumentToCanvas('fragmentShaderSource')
    @_vertexShaderDoc = @_bindDocumentToCanvas('vertexShaderSource')

    @_codemirror = CodeMirror(@element.querySelector(".tamarind-editor-code"),
      value: @_fragmentShaderDoc
      lineNumbers: true
      lineWrapping: true
    )
    @_codemirror.on "renderLine", @_addLineWrapIndent
    @_codemirror.refresh()

    @on MENU_ITEM_SELECT, @_handleMenuItemSelect



  _bindDocumentToCanvas: (propertyName) ->
    doc = CodeMirror.Doc(@_canvas[propertyName], 'clike')
    doc.on 'change', =>
      @_canvas[propertyName] = doc.getValue()
      return
    return doc


  # indent wrapped lines. Based on http://codemirror.net/demo/indentwrap.html but this
  # version indents the wrapped line by a further 2 characters
  _addLineWrapIndent: (cm, line, elt) =>
    unless @_codeCharWidth
      @_codeCharWidth = @_codemirror.defaultCharWidth()

    basePadding = 4
    indentChars = 2
    offset = CodeMirror.countColumn(line.text, null, cm.getOption("tabSize")) * @_codeCharWidth
    elt.style.textIndent = "-" + (offset + @_codeCharWidth * indentChars) + "px"
    elt.style.paddingLeft = (basePadding + offset + @_codeCharWidth * indentChars) + "px"
    return

  _handleMenuItemSelect: (item) ->
    if item is FRAGMENT_SHADER
      @_codemirror.swapDoc(@_fragmentShaderDoc)
    if item is VERTEX_SHADER
      @_codemirror.swapDoc(@_vertexShaderDoc)

    return


# A set of links where at any one time, one link is .
class ToggleBar

  constructor: (@_parent, @_events, @_eventName) ->
    @_parent.addEventListener "click", (event) => @selectChild(event.target)
    @_children = @_parent.querySelectorAll "a"
    @_selectedChild = null
    @selectChild(@_children[0])

  selectChild: (childToSelect) =>
    if @_selectedChild == childToSelect
      return
    @_selectedChild = childToSelect
    for child in @_children
      if child == childToSelect
        child.classList.add("is-selected")
      else
        child.classList.remove("is-selected")

    setTimeout (=> @_events.emit @_eventName, @_selectedChild.name), 1
    return


