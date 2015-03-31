utils = require('../utils.coffee')

describe 'parseHTML', ->

  it 'should', ->

    multipleNodes = '<div></div><div></div>'
    expect(-> utils.parseHTML multipleNodes).toThrow new Error('html must represent single element')

    multipleNodes = '<div></div> lala'
    expect(-> utils.parseHTML multipleNodes).toThrow new Error('html must represent single element')

    singleNode = '  <div class="foo"><div>  '
    retval = utils.parseHTML singleNode

    expect(retval.className).toEqual('foo')

    return

  return