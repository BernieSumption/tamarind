constants    = require './constants.coffee'
UIComponent   = require './UIComponent.coffee'
State         = require './State.coffee'
utils         = require './utils.coffee'
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
  @State = State
  @WebGLCanvas = WebGLCanvas

  NOT_SUPPORTED_HTML = '''
    <span class="tamarind-icon-unhappy tamarind-unsupported-icon" title="And lo there shall be no editor, and in that place there shall be wailing and gnashing of teeth."></span>
    Your browser doesn't support this feature. Try Internet Explorer 11+ or recent versions of Chrome, Firefox or Safari.
  '''

  TEMPLATE = """
    <div class="tamarind">
      <div class="tamarind-editor-panel">
      </div>
      <div class="tamarind-render-panel">
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

    @_webGLCanvas = new WebGLCanvas(@_state)
    @_webGLCanvas.appendTo(@css '.tamarind-render-panel')

    controlDrawer = new ControlDrawer(@_state)
    controlDrawer.appendTo(@css('.tamarind-render-panel'))

    @_codeEditor = new CodeEditor(@_state)
    @_codeEditor.appendTo editorPanel



module.exports = Tamarind

utils.setTamarindGlobal(Tamarind)