
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

    editor = new ShaderEditor(config)
    scriptTemplate.parentNode.insertBefore(editor.element, scriptTemplate)
    scriptTemplate.parentNode.removeChild(scriptTemplate)


  return




class ShaderEditor extends EventEmitter

  TEMPLATE = """
    <div class="tamarind-menu">
      <a href="javascript:void(0)" name="config" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
      <a href="javascript:void(0)" name="fragment-shader" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader"></a>
      <a href="javascript:void(0)" name="vertex-shader" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
    </div>
    <div class="tamarind-editor-panel">
      <div class="tamarind-editor tamarind-editor-config"></div>
      <div class="tamarind-editor tamarind-editor-fragment-shader"></div>
      <div class="tamarind-editor tamarind-editor-vertex-shader"></div>
    </div>
    <div class="tamarind-render-panel">
      <canvas class="tamarind-render-canvas"></canvas>
    </div>
    <span class="tamarind-logo"></span>
  """

  MENU_ITEM_SELECT = "menu-item-select"



  constructor: (@_config = {}) ->

    @element = document.createElement("div")
    @element.className = "tamarind"
    @element.innerHTML = TEMPLATE
    @element.editor = @

    @element.addEventListener "click", @_handleClick

    @_canvas = new WebGLCanvas(@element.querySelector(".tamarind-render-canvas"))

    new ToggleBar(@element.querySelector(".tamarind-menu"), @, MENU_ITEM_SELECT)


  _handleClick: (event) =>
    eventName = event.target.getAttribute("data-event")
    if eventName
      eventArg = event.target.getAttribute("data-arg")
      @emit eventName, eventArg


    return


# A set of links where at any one time, one link.
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



