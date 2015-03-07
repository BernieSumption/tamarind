
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
      <input type='checkbox' data-event="menu-click" data-arg="config" class="tamarind-menu-button tamarind-icon-config" title="Scene setup">
      <a href="javascript:void(0)" data-event="menu-click" data-arg="fragment-shader" class="tamarind-menu-button is-selected tamarind-icon-fragment-shader" title="Fragment shader"></a>
      <a href="javascript:void(0)" data-event="menu-click" data-arg="vertex-shader" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
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



  constructor: (@_config = {}) ->

    @element = document.createElement("div")
    @element.className = "tamarind"
    @element.innerHTML = TEMPLATE
    @element.editor = @

    @element.addEventListener "click", @_handleClick

    @_canvas = new WebGLCanvas(@element.querySelector(".tamarind-render-canvas"))

    for panel in ["config", "fragment-shader", "vertex-shader"]
      @element.querySelector("tamarind-icon-" + panel)


  _handleClick: (event) =>
    eventName = event.target.getAttribute("data-event")
    if eventName
      eventArg = event.target.getAttribute("data-arg")
      @emit eventName, eventArg


    return


