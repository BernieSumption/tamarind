

describe 'replaceElement', ->

  it 'should', ->
    parent = document.createElement 'div'
    target = document.createElement 'div'
    parent.appendChild target

    multipleNodes = '<div></div><div></div>'
    expect(-> Tamarind.replaceElement target, multipleNodes).toThrow new Error('replacement must be a single element')

    multipleNodes = '<div></div> lala'
    expect(-> Tamarind.replaceElement target, multipleNodes).toThrow new Error('replacement must be a single element')

    singleNode = '  <div class="foo"><div>  '
    retval = Tamarind.replaceElement target, singleNode

    expect(retval.className).toEqual('foo')

    return

  return