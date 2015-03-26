'use strict'

class Call
  @spy = ->
    call = new Call
    spyOn(call, 'back')
    return call
  back: ->


describe 'EventEmitter', ->

  it 'should register callbacks with the off() method', ->
    ee = new Tamarind.EventEmitter()
    call1 = Call.spy()
    call2 = Call.spy()
    call3 = Call.spy()
    ee.on 'foo', call1.back
    ee.on 'foo', call2.back
    ee.on 'bar', call3.back
    ee.emit 'foo', 100
    expectCallHistory call1.back, [100]
    expectCallHistory call2.back, [100]
    expectCallHistory call3.back, []

    return

  it 'should deregister callbacks with the off() method', ->
    ee = new Tamarind.EventEmitter()
    call1 = Call.spy()
    call2 = Call.spy()
    ee.on 'foo', call1.back
    ee.on 'foo', call2.back
    ee.off 'foo', call2.back
    ee.emit 'foo'

    expectCallHistory call1.back, [undefined]
    expectCallHistory call2.back, []

    return

  it 'should a callback to be registered multiple times without multiple calls', ->
    ee = new Tamarind.EventEmitter()
    call1 = Call.spy()
    ee.on 'foo', call1.back
    ee.on 'foo', call1.back
    ee.emit 'foo'

    expect(call1.back.calls.count()).toEqual 1

    return


  it 'should throw an error when passed arguments of the wrong type', ->
    ee = new Tamarind.EventEmitter()
    callback = ->
    ee.on 'foo', callback
    expect(-> ee.on 3, callback).toThrowError()
    expect(-> ee.on null, callback).toThrowError()
    expect(-> ee.on 'foo').toThrowError()
    expect(-> ee.on 'foo', null).toThrowError()
    expect(-> ee.on 'foo', 5).toThrowError()

    ee.emit 'foo'
    ee.emit 'foo', 4
    expect(-> ee.emit null).toThrowError()
    expect(-> ee.emit 4).toThrowError()

    ee.off 'foo', callback
    ee.off 'bar', callback
    expect(-> ee.off 4, callback).toThrowError()
    expect(-> ee.off 'bar', null).toThrowError()

    return


  it 'should not get confused if an event handler removes itself while being called', ->
    ee = new Tamarind.EventEmitter()
    a = ->
      ee.off 'foo', a
      return

    b = ->
      return

    c = ->
      ee.off 'foo', c
      return

    d = ->
      ee.off 'foo', d
      return

    ee.on 'foo', a
    ee.on 'foo', b
    ee.on 'foo', c
    ee.on 'foo', d

    expect(ee._getEventList('foo').length).toEqual 4
    ee.emit('foo')
    expect(ee._getEventList('foo').length).toEqual 1

    return

  return
