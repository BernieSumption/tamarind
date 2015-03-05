'use strict';

class Call
  @spy = ->
    call = new Call
    spyOn(call, "back")
    call
  back: ->


describe 'EventEmitter', ->

  it 'should register callbacks with the off() method', ->
    ee = new EventEmitter
    call1 = Call.spy()
    call2 = Call.spy()
    call3 = Call.spy()
    ee.on "foo", call1.back
    ee.on "foo", call2.back
    ee.on "bar", call3.back
    ee.emit "foo", 100
    expect(call1.back).toHaveBeenCalledWith 100
    expect(call2.back).toHaveBeenCalledWith 100
    expect(call3.back).not.toHaveBeenCalledWith 100

  it 'should deregister callbacks with the off() method', ->
    ee = new EventEmitter
    call1 = Call.spy()
    call2 = Call.spy()
    ee.on "foo", call1.back
    ee.on "foo", call2.back
    ee.off "foo", call2.back
    ee.emit "foo"

    expect(call1.back).toHaveBeenCalled()
    expect(call2.back).not.toHaveBeenCalled()

  it 'should a callback to be registered multiple times without multiple calls', ->
    ee = new EventEmitter
    call1 = Call.spy()
    ee.on "foo", call1.back
    ee.on "foo", call1.back
    ee.emit "foo"

    expect(call1.back.calls.count()).toEqual 1


  it 'should throw an error when passed arguments of the wrong type', ->
    ee = new EventEmitter
    callback = ->
    ee.on "foo", callback
    expect(-> ee.on 3, callback).toThrowError()
    expect(-> ee.on null, callback).toThrowError()
    expect(-> ee.on "foo").toThrowError()
    expect(-> ee.on "foo", null).toThrowError()
    expect(-> ee.on "foo", 5).toThrowError()

    ee.emit "foo"
    ee.emit "foo", 4
    expect(-> ee.emit null).toThrowError()
    expect(-> ee.emit 4).toThrowError()

    ee.off "foo", callback
    ee.off "bar", callback
    expect(-> ee.off 4, callback).toThrowError()
    expect(-> ee.off "bar", null).toThrowError()

