
VSHADER_HEADER = '''
attribute float a_VertexIndex;
'''

FSHADER_HEADER = '''
precision mediump float;
uniform vec2 u_CanvasSize;
'''

compareAgainstReferenceImage = (webglCanvas, referenceImageUrl, done) ->

  imageToDataUrl = (imageElement) ->
    canvasElement = document.createElement 'canvas'
    canvasElement.width = imageElement.width
    canvasElement.height = imageElement.height
    ctx = canvasElement.getContext '2d'
    ctx.drawImage(imageElement, 0, 0)
    return canvasElement.toDataURL('image/png')

  loaded = 0

  handleLoad = ->
    ++loaded
    if loaded is 2
      expectedData = imageToDataUrl(expected)
      actualData = imageToDataUrl(actual)
      unless expectedData is actualData
        window.focus()
        console.log 'EXPECTED DATA: ' + expectedData
        console.log 'ACTUAL DATA: ' + actualData
        unless document.location.href.indexOf('bad-images') is -1
          window.open expectedData
          window.open actualData
        else
          console.log 'PRO TIP: append ?bad-images to the Karma runner URL and reload to view these images'
        expect(false).toBeTruthy()
      done()
    return

  actual = new Image()
  actual.onload = handleLoad
  actual.src = webglCanvas.captureImage(100, 100)

  expected = new Image()
  expected.onload = handleLoad
  expected.onerror = -> throw new Error("Couldn't load " + referenceImageUrl)
  expected.src = referenceImageUrl

  return


describe 'WebGLCanvas', ->

  oldError = console.error

  beforeEach ->
    console.error = (message) ->
      unless message is 'this error is expected'
        oldError.call(console, message)
      throw new Error(message)

    return

  afterEach ->
    console.error = oldError
    return

  it 'should throw an exception on console errors', ->
    expect(-> console.error('this error is expected')).toThrow(new Error('this error is expected'))
    return

  createCanvasAndState = (debugMode = true) ->
    state = new Tamarind.State()
    state.debugMode = debugMode
    canvas = new Tamarind.WebGLCanvas(document.createElement('canvas'), state)
    return [canvas, state]

  it 'should render a test image', (done) ->

    [canvas, state] = createCanvasAndState()

    state.setShaderSource Tamarind.VERTEX_SHADER, VSHADER_HEADER + '''
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
    '''

    state.setShaderSource Tamarind.FRAGMENT_SHADER, FSHADER_HEADER + '''
      void main() {
        gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);
      }
    '''

    compareAgainstReferenceImage canvas, '/base/build/test/reference-images/plain-shader.png', done

    return

  it 'test image rendering should work even if the scene is invalid', ->

    [canvas, state] = createCanvasAndState()

    state.setShaderSource Tamarind.VERTEX_SHADER, VSHADER_HEADER + '''
      void main() {
        blarty foo
      }
    '''

    state.setShaderSource Tamarind.FRAGMENT_SHADER, FSHADER_HEADER + '''
      void main() {
        gl_FragColor = nark;
      }
    '''


    image = canvas.captureImage(100, 100)
    expect(image).toContain('image/png')

    return

  expectErrorCountFromSource = (done, expectedErrorLines, fragmentShaderSource) ->

    [canvas, state] = createCanvasAndState(false)

    state.setShaderSource Tamarind.FRAGMENT_SHADER, fragmentShaderSource

    state.on state.SHADER_ERRORS_CHANGE, (shaderType) ->
      if shaderType is Tamarind.FRAGMENT_SHADER
        actualErrorLines = (err.line for err in state.getShaderErrors(Tamarind.FRAGMENT_SHADER))
        expect(actualErrorLines).toEqual(expectedErrorLines)
        done()

      return

    return

  it 'should dispatch CompileStatus events on sucessful compilation', (done) ->

    expectErrorCountFromSource done, [], FSHADER_HEADER + '''
      void main() {
        gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);
      }
    '''

    return

  it 'should have one error if there is a syntax problem', (done) ->

    expectErrorCountFromSource done, [2],  FSHADER_HEADER + '''
      void main() {
        gl_FragColor vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1); // error: missing equals
      }
    '''

    return

  it 'should have multiple errors if there are multiple validation problems', (done) ->

    expectErrorCountFromSource done, [2, 4],  FSHADER_HEADER + '''
      void main() {
        foo = 1.0; // first error
        gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);
        bar = 2.0; // second error
      }
    '''

    return

  it 'should interpret a failed linking as a line -1 error on both shaders', (done) ->

    [canvas, state] = createCanvasAndState()

    state.setShaderSource Tamarind.FRAGMENT_SHADER, FSHADER_HEADER + '''
      varying vec4 doesntExist; // not present in vertex shader, that's a link error
      void main() {
        gl_FragColor = doesntExist;
      }
    '''
    state.setShaderSource Tamarind.VERTEX_SHADER, VSHADER_HEADER + '''
      void main() {
        gl_Position = vec4(0);
      }
    '''

    eventCount = 0
    state.on state.SHADER_ERRORS_CHANGE, (error) ->

      ++eventCount

      if eventCount is 4 # two successful compiles, two failures during link
        fragErrors = state.getShaderErrors(Tamarind.FRAGMENT_SHADER)
        expect(fragErrors.length).toEqual 1
        expect(fragErrors[0].line).toEqual -1


        vertErrors = state.getShaderErrors(Tamarind.VERTEX_SHADER)
        expect(vertErrors.length).toEqual 1
        expect(vertErrors[0].line).toEqual -1

        done()

      return

    return


  return







