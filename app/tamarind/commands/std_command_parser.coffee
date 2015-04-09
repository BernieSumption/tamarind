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
    1,
    require('../controls/SliderInputControl.coffee')
  ),
  new InputCommandType(
    'mouse',
    [
      ['damping', 0]
    ],
    2,
    require('../controls/MouseInputControl.coffee')
  ),
  new InputCommandType(
    'color',
    [],
    3,
    require('../controls/ColorInputControl.coffee')
  ),
])