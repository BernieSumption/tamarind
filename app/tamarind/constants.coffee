

module.exports =
  FRAGMENT_SHADER: 'FRAGMENT_SHADER'
  VERTEX_SHADER:   'VERTEX_SHADER'
  CONFIG: 'CONFIG'


  DEFAULT_VSHADER_SOURCE: '''
    attribute float a_VertexIndex;
    varying vec2 v_position;

    void main() {
      // this is the default vertex shader. It positions 4 points, one in each corner clockwise from top left, creating a rectangle that fills the whole canvas.
      if (a_VertexIndex == 0.0) {
        v_position = vec2(-1, -1);
      } else if (a_VertexIndex == 1.0) {
        v_position = vec2(1, -1);
      } else if (a_VertexIndex == 2.0) {
        v_position = vec2(1, 1);
      } else if (a_VertexIndex == 3.0) {
        v_position = vec2(-1, 1);
      } else {
        v_position = vec2(0);
      }
      gl_Position.xy = v_position;
    }
  '''


  DEFAULT_FSHADER_SOURCE: '''
    precision mediump float;
    uniform vec2 u_CanvasSize;
    varying vec2 v_position;

    void main() {
      gl_FragColor = vec4(v_position, 1, 1);
    }
  '''


