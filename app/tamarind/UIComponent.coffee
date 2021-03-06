EventEmitter = require './EventEmitter.coffee'
utils = require('./utils.coffee')

###
  Superclass for visual components
###
class UIComponent extends EventEmitter

  constructor: (@_state, html) ->
    @_element = utils.parseHTML html



  # Replace an existing DOM node with this component
  overwrite: (target) ->
    target.parentNode.insertBefore @_element, target
    target.parentNode.removeChild target
    return

  # Insert this component into an DOM node
  appendTo: (target) ->
    target.appendChild(@_element)
    return

  setVisible: (visible) ->
    @_element.style.display = if visible then '' else 'none'
    return



  # Remove an element's existing content and replace it with text
  # @param el a css selector or DOM element
  setInnerText: (el, text) ->
    el = @css el
    el.innerHTML = ''
    el.appendChild document.createTextNode text
    return


  # Return the single element matching a css selector or throw an error. If selector
  # is already an element, return it.
  css: (selector) ->
    if selector instanceof Element
      return selector
    return @csss(selector, 1, 1)[0]


  # Return all elements matching the selector. Optionally, throw an exception of the number
  # of matching elements is not between min and max values
  csss: (selector, min = 0, max = Infinity) ->
    els = @_element.querySelectorAll selector
    if els.length < min or els.length > max
      throw new Error("#{els.length} elements with selector '#{selector}' (required between #{min} and #{max})")
    return Array.prototype.slice.call(els)

  # Bind a named input to the state property of the same name, e.g. if the input is <input type=text name=foo>
  # then changing state.foo will update the inputs and vice versa.
  bindInputToState: (propertyName) ->
    input = @css("[name='#{propertyName}']")

    # figure out how to bind to this kind of element
    eventName = 'input'
    inputPropertyName = 'value'
    parseFunction = (v) -> v
    if input.type is 'number'
      parseFunction = parseInt
    else if input.type is 'checkbox'
      inputPropertyName = 'checked'
      eventName = 'change'

    # take the initial value from the state
    input[inputPropertyName] = @_state[propertyName]

    # update state when element changes
    input.addEventListener eventName, =>
      @_state[propertyName] = parseFunction(input[inputPropertyName])
      return

    # update element when state changes
    @_state.onPropertyChange propertyName, =>
      input[inputPropertyName] = @_state[propertyName]
      return

    return

  setClassIf: (className, condition, element = @_element) ->
    if condition
      element.classList.add className
    else
      element.classList.remove className
    return


module.exports = UIComponent