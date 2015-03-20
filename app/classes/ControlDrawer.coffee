
###
  A component that shows a list of UI controls that provide input to shaders
###

class Tamarind.ControlDrawer

  TEMPLATE = '''
    <div class="tamarind-control-drawer">

    </div>
  '''


  constructor: (target, @_state) ->

    @_element = Tamarind.replaceElement target, TEMPLATE

