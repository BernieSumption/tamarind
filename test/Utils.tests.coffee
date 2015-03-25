

describe 'parseHTML', ->

  it 'should', ->

    multipleNodes = '<div></div><div></div>'
    expect(-> Tamarind.parseHTML multipleNodes).toThrow new Error('html must represent single element')

    multipleNodes = '<div></div> lala'
    expect(-> Tamarind.parseHTML multipleNodes).toThrow new Error('html must represent single element')

    singleNode = '  <div class="foo"><div>  '
    retval = Tamarind.parseHTML singleNode

    expect(retval.className).toEqual('foo')

    return

  return