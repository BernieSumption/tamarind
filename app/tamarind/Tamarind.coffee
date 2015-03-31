constants    = require './constants.coffee'
UIComponent   = require './UIComponent.coffee'
State         = require './State.coffee'
utils         = require './utils.coffee'
ConfigEditor  = require './ConfigEditor.coffee'
CodeEditor    = require './CodeEditor.coffee'
ControlDrawer = require './ControlDrawer.coffee'
WebGLCanvas   = require './WebGLCanvas.coffee'


require '../styles/all.less'

###
  The main class. Create an instance `t` then use t.appendTo(el) to t.overwrite(el) to add the
  editor to the page.
###
class Tamarind extends UIComponent

  # Various aliases that define the public API
  @FRAGMENT_SHADER = constants.FRAGMENT_SHADER
  @VERTEX_SHADER = constants.VERTEX_SHADER
  @CONFIG = constants.CONFIG
  @State = State
  @WebGLCanvas = WebGLCanvas

  NOT_SUPPORTED_HTML = '''
    <span class="tamarind-icon-unhappy tamarind-unsupported-icon" title="And lo there shall be no editor, and in that place there shall be wailing and gnashing of teeth."></span>
    Your browser doesn't support this feature. Try Internet Explorer 11+ or recent versions of Chrome, Firefox or Safari.
  '''

  TEMPLATE = """
    <div class="tamarind">
      <div class="tamarind-menu">
        <a href="javascript:void(0)" name="#{constants.FRAGMENT_SHADER}" class="tamarind-menu-button tamarind-icon-fragment-shader" title="Fragment shader">
          <span class="tamarind-menu-icon-overlay" title="Fragment shader has errors"></span>
        </a>
        <a href="javascript:void(0)" name="#{constants.VERTEX_SHADER}" class="tamarind-menu-button tamarind-icon-vertex-shader" title="Vertex shader">
          <span class="tamarind-menu-icon-overlay" title="Vertex shader has errors"></span>
        </a>
        <a href="javascript:void(0)" name="#{constants.CONFIG}" class="tamarind-menu-button tamarind-icon-config" title="Scene setup"></a>
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
  # @param location [HTMLElement] an element in the DOM that will be removed and replaced with the Tamarind editor
  # @param state [State] A state object, or null to create one
  #
  constructor: (state = null) ->
    super(state or new State(), TEMPLATE)

    unless utils.browserSupportsRequiredFeatures()
      @_element.innerHTML = NOT_SUPPORTED_HTML
      @_element.className += ' tamarind-unsupported'
      return
    else
      @_element.className = 'tamarind'

    editorPanel = @css '.tamarind-editor-panel'

    new WebGLCanvas(@css('.tamarind-render-canvas'), @_state)

    controlDrawer = new ControlDrawer(@_state)
    controlDrawer.overwrite(@css('.tamarind-controls-marker'))

    @_configEditor = new ConfigEditor(@_state)
    @_configEditor.appendTo editorPanel

    @_codeEditor = new CodeEditor(@_state)
    @_codeEditor.appendTo editorPanel


    @_links = @csss '.tamarind-menu a', 3
    @_element.addEventListener 'click', @_handleMenuLinkClick


    @_state.onPropertyChange 'selectedTab', @_handleMenuItemSelect
    @_handleMenuItemSelect()

    @_state.on @_state.SHADER_ERRORS_CHANGE, @_handleShaderErrorsChange
    @_handleShaderErrorsChange()



  # @private
  _handleMenuItemSelect: =>
    item = @_state.selectedTab

    if item is constants.CONFIG
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


  _handleShaderErrorsChange: =>
    fsError = @css '.tamarind-icon-fragment-shader .tamarind-menu-icon-overlay'
    vsError = @css '.tamarind-icon-vertex-shader .tamarind-menu-icon-overlay'

    @setClassIf 'is-visible', @_state.hasShaderErrors(constants.FRAGMENT_SHADER), fsError
    @setClassIf 'is-visible', @_state.hasShaderErrors(constants.VERTEX_SHADER), vsError

    return


module.exports = Tamarind