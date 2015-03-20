


###
  Return false if the browser can't handle the awesome.
###
Tamarind.browserSupportsRequiredFeatures = ->
  if Tamarind.browserSupportsRequiredFeatures.__cache is undefined

    try
      canvas = document.createElement 'canvas'
      ctx = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')

    Tamarind.browserSupportsRequiredFeatures.__cache = !!(ctx and Object.defineProperty)

  return Tamarind.browserSupportsRequiredFeatures.__cache



###
  Replace an existing DOM node with another node.
  @param replacement [mixed] either a DOM node, or a string to be converted into HTML.
###
Tamarind.replaceElement = (target, replacement) ->
  if typeof replacement is 'string'
    tmp = document.createElement 'div'
    tmp.innerHTML = replacement.trim()
    if tmp.childNodes.length > 1
      throw new Error 'replacement must be a single element'
    replacement = tmp.childNodes[0]
    tmp.removeChild replacement


  target.parentNode.insertBefore replacement, target
  target.parentNode.removeChild target
  return replacement