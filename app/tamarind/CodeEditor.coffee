UIComponent = require './UIComponent.coffee'
constants   = require './constants.coffee'
CodeMirror  = require 'codemirror'
isEqual     = require 'lodash/lang/isEqual'
parser      = require './commands/std_command_parser.coffee'


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
    @_state.on @_state.SHADER_SOURCE_CHANGE, @_handleShanderSourceChange

    @_doc = CodeMirror.Doc(@_state.shaderSource, 'x-shader/x-fragment')

    @_codemirror = CodeMirror(@_element,
      value: @_doc
      lineNumbers: true
      lineWrapping: true
      gutters: ['CodeMirror-lint-markers']
      lint:
        getAnnotations: @_handleCodeMirrorLint
        async: true
        delay: 200
    )

    @_codemirror.on 'renderLine', @_addLineWrapIndent
    @_codemirror.on 'cursorActivity', @_handleCursorActivity

    # we're not attached to the window's DOM at time of creation, so we need to
    # re-measure the editor when we are
    requestAnimationFrame => @_codemirror.refresh()


  # @private
  # Handle CodeMirror lint events. These are fired a few hundred milliseconds after the user
  # has finished typing in an editor window, and we use them to update the shader source
  _handleCodeMirrorLint: (value, callback, options, cm) =>
    if @_codemirror
      @_state.shaderSource = value
    @_lintingCallback = callback
    return

  # @private
  # Update the UI when the shader is changed form the model
  _handleShanderSourceChange: =>
    newSource = @_state.shaderSource
    oldSource = @_doc.getValue()
    unless newSource is oldSource
      @_doc.setValue newSource
    return


  _handleShaderErrorsChange: =>
    errors = []
    for err in @_state.shaderErrors
      line = Math.max(err.line, 0)
      errors.push(
        message: err.message
        from:
          line: line
          ch: err.start
        to:
          line: line
          ch: err.end
      )

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

  _handleCursorActivity: =>

    currentCursor = @_codemirror.getCursor()

    if @_prevCursor
      currentToken = @_codemirror.getTokenAt(currentCursor)
      prevToken = @_codemirror.getTokenAt(@_prevCursor)
      tokenHasChanged = not isEqual(prevToken, currentToken)
      prevTokenIsDirective = prevToken.string.indexOf('//!') is 0

      if prevTokenIsDirective and tokenHasChanged
        replaced = parser.reformatCommandComment(prevToken.string)
        if replaced
          @_codemirror.replaceRange(
            replaced
            {line: @_prevCursor.line, ch: prevToken.start},
            {line: @_prevCursor.line, ch: prevToken.end}
          )

    @_prevCursor = currentCursor

    return



module.exports = CodeEditor