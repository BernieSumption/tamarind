UIComponent = require './UIComponent.coffee'
constants    = require './constants.coffee'
CodeMirror  = require 'codemirror'


# NOTE: if you remove addons from here, also remove the CSS imports from all.less
require 'codemirror/lib/codemirror.js'
require 'codemirror/mode/clike/clike.js'
require 'codemirror/addon/dialog/dialog.js'
require 'codemirror/addon/display/placeholder.js'
require 'codemirror/addon/lint/lint.js'
require 'codemirror/addon/search/search.js'
require 'codemirror/addon/search/searchcursor.js'


class CodeEditor extends UIComponent

  TEMPLATE = '''
    <div class="tamarind-editor tamarind-editor-code"></div>
  '''

  constructor: (state) ->
    super(state, TEMPLATE)

    @_state.on @_state.SHADER_ERRORS_CHANGE, @_handleShaderErrorsChange
    @_state.on @_state.SHADER_CHANGE, @_handleShanderChange

    @_shaderDocs = {}
    createDoc = (shaderType) =>
      doc = CodeMirror.Doc(@_state.getShaderSource(shaderType), 'x-shader/x-fragment')
      doc.shaderType = shaderType
      @_shaderDocs[shaderType] = doc
      return
    createDoc constants.FRAGMENT_SHADER
    createDoc constants.VERTEX_SHADER

    @_codemirror = CodeMirror(@_element,
      value: @_shaderDocs[constants.FRAGMENT_SHADER]
      lineNumbers: true
      lineWrapping: true
      gutters: ['CodeMirror-lint-markers']
      lint:
        getAnnotations: @_handleCodeMirrorLint
        async: true
        delay: 200
    )

    @_codemirror.on 'renderLine', @_addLineWrapIndent

    # we're not attached to the window's DOM at time of creation, so we need to
    # re-measure the editor when we are
    requestAnimationFrame => @_codemirror.refresh()



  swapShaderType: (shaderType) ->
    @_activeCodeEditor = shaderType
    @_codemirror.swapDoc(@_shaderDocs[shaderType])
    @_handleShaderErrorsChange(shaderType)
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



module.exports = CodeEditor