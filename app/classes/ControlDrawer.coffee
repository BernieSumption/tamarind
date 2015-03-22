
###
  A component that shows a list of UI controls that provide input to shaders
###

class Tamarind.ControlDrawer

  TEMPLATE = '''
    <div class="tamarind-controls">
      <div class="tamarind-controls-background">
        <a href="javascript:void(0)" class="tamarind-controls-button tamarind-icon-controls"></a>
        <div class="tamarind-controls-ui">
          <input type="range" class="tamarind-range-input">
        </div>
      </div>
    </div>
  '''


  constructor: (target, @_state) ->

    @_element = Tamarind.replaceElement target, TEMPLATE

    @_element.querySelector('.tamarind-controls-button').addEventListener 'click', @_toggleOpen

  _toggleOpen: =>
    if @_element.classList.contains('is-selected')
      @_element.classList.remove('is-selected')
    else
      @_element.classList.add('is-selected')
    return

