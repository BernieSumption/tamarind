CommandParser = require './CommandParser.coffee'
InputCommandType = require './InputCommandType.coffee'
StandaloneCommandType = require './StandaloneCommandType.coffee'


# A CommandParser instance that represents Tamarind's input rules



module.exports = new CommandParser([
  new InputCommandType(
    'slider',
    [
      ['min', 0]
      ['max', 1]
      ['step', 0.01]
    ],
    'float',
    require('../controls/SliderInputControl.coffee')
  ),
  new InputCommandType(
    'mouse',
    [
      ['damping', 0]
    ],
    'vec2',
    require('../controls/MouseInputControl.coffee')
  ),
  new InputCommandType(
    'canvasSize',
    [],
    'vec2',
    require('../controls/CanvasSizeInputControl.coffee')
  ),
  new InputCommandType(
    'color',
    [],
    'vec3',
    require('../controls/ColorInputControl.coffee')
  ),
  new InputCommandType(
    'image',
    [],
    'sampler2D',
    require('../controls/ImageInputControl.coffee')
  ),
  new InputCommandType(
    'time',
    [],
    'float',
    require('../controls/TimeInputControl.coffee')
  ),
])