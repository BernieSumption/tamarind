


class Tamarind.ShaderEditor extends Tamarind.UIComponent

  NOT_SUPPORTED_HTML = '''
    <span class="tamarind-icon-unhappy tamarind-unsupported-icon" title="And lo there shall be no editor, and in that place there shall be wailing and gnashing of teeth."></span>
    Your browser doesn't support this feature. Try Internet Explorer 11+ or recent versions of Chrome, Firefox or Safari.
  '''

  TEMPLATE = """
    <div class="tamarind">
      <div class="tamarind-menu">
        <a href="javascript:void(0)" name="#{Tamarind.FRAGMENT_SHADER}" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader"></a>
        <a href="javascript:void(0)" name="#{Tamarind.VERTEX_SHADER}" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader"></a>
        <a href="javascript:void(0)" name="#{Tamarind.CONFIG}" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
      </div>
      <div class="tamarind-editor-panel">
      </div>
      <div class="tamarind-render-panel">
        <canvas class="tamarind-render-canvas"></canvas>
        <div class="tamarind-controls-marker"></div>
      </div>
    </div>
  """


  # @property [WebGLCanvas] the rendering canvas for this editor. Read-only.
  canvas: null


  # Create a new Tamarind editor
  # @param [HTMLElement] location an element in the DOM that will be removed and replaced with the Tamarind editor
  # @param [Tamarind.State] state A state object, or null to create one
  #
  constructor: (state = null) ->
    super(state or new Tamarind.State(), TEMPLATE)

    unless Tamarind.browserSupportsRequiredFeatures()
      @_element.innerHTML = NOT_SUPPORTED_HTML
      @_element.className += ' tamarind-unsupported'
      return
    else
      @_element.className = 'tamarind'

    editorPanel = @css '.tamarind-editor-panel'

    new Tamarind.WebGLCanvas(@css('.tamarind-render-canvas'), @_state)

    controlDrawer = new Tamarind.ControlDrawer(@_state)
    controlDrawer.overwrite(@css('.tamarind-controls-marker'))

    @_configEditor = new Tamarind.ConfigEditor(@_state)
    @_configEditor.appendTo editorPanel

    @_codeEditor = new Tamarind.CodeEditor(@_state)
    @_codeEditor.appendTo editorPanel


    @_links = @csss '.tamarind-menu a', 3
    @_element.addEventListener 'click', @_handleMenuLinkClick


    @_state.onPropertyChange 'selectedTab', @_handleMenuItemSelect
    @_handleMenuItemSelect()



  # @private
  _handleMenuItemSelect: =>
    item = @_state.selectedTab

    if item is Tamarind.CONFIG
      @_codeEditor.setVisible false
      @_configEditor.setVisible true
    else
      @_codeEditor.setVisible true
      @_configEditor.setVisible false
      @_codeEditor.swapShaderType item

    for link in @_links
      if link.name is item
        link.classList.add('is-selected')
      else
        link.classList.remove('is-selected')

    return


  _handleMenuLinkClick: (event) =>
    if event.target not in @_links
      return
    @_state.selectedTab = event.target.name
    return
