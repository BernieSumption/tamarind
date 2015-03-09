
compareAgainstReferenceImage = (webglCanvas, referenceImageUrl, done) ->

  imageToDataUrl = (imageElement) ->
    canvasElement = document.createElement "canvas"
    canvasElement.width = imageElement.width
    canvasElement.height = imageElement.height
    ctx = canvasElement.getContext "2d"
    ctx.drawImage(imageElement, 0, 0)
    return canvasElement.toDataURL("image/png")

  loaded = 0

  handleLoad = =>
    ++loaded
    if loaded is 2
      expectedData = imageToDataUrl(expected)
      actualData = imageToDataUrl(actual)
      unless expectedData is actualData
        window.focus()
        console.log "EXPECTED DATA: " + expectedData
        console.log "ACTUAL DATA: " + actualData
        if document.location.href.indexOf("bad-images") != -1
          window.open expectedData
          window.open actualData
        else
          console.log "PRO TIP: append ?bad-images to the Karma runner URL and reload to view these images"
        expect(false).toBeTruthy()
      done()

  actual = new Image()
  actual.onload = handleLoad
  actual.src = webglCanvas.captureImage(100, 100)

  expected = new Image()
  expected.onload = handleLoad
  expected.onerror = -> throw new Error("Couldn't load " + referenceImageUrl)
  expected.src = referenceImageUrl


describe 'WebGLCanvas', ->

  oldError = console.error

  beforeEach ->
    console.error = (message) ->
      oldError.call(console, message)
      throw new Error(message)

  afterEach ->
    console.error = oldError

  it 'should throw an exception on console errors', ->
    expect(-> console.error("this error is expected")).toThrow(new Error("this error is expected"))

  it 'should render a test image', (done) ->


    canvas = new WebGLCanvas(document.createElement("canvas"), true)
    canvas.throwOnWebGLError = true


    canvas.vertexShaderSource = """
      void main() {
        // 4 points, one in each corner, clockwise from top left
        if (a_VertexIndex == 0.0) {
          gl_Position.xy = vec2(-1, -1);
        } else if (a_VertexIndex == 1.0) {
          gl_Position.xy = vec2(1, -1);
        } else if (a_VertexIndex == 2.0) {
          gl_Position.xy = vec2(1, 1);
        } else if (a_VertexIndex == 3.0) {
          gl_Position.xy = vec2(-1, 1);
        }
      }
    """

    canvas.fragmentShaderSource = """
      void main() {
        gl_FragColor.r = u_CanvasSize.x;
        gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);
      }
    """

    compareAgainstReferenceImage canvas, "/base/build/test/reference-images/plain-shader.png", done


  it 'should dispatch CompileStatus events', (done) ->

    canvas = new WebGLCanvas(document.createElement("canvas"), true)
    canvas.throwOnWebGLError = true

    canvas.on WebGLCanvas.COMPILE, (event) ->
      if event.type is @_activeCodeEditor
        console.log







