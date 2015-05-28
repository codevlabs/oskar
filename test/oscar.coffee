###################################################################
# Setup the tests
###################################################################
should = require 'should'
sinon = require 'sinon'
{EventEmitter} = require 'events'

# Client = require '../src/client'
oscar = require '../src/oscar'

###################################################################
# Helper
###################################################################

describe 'oscar', ->

  it 'should trigger presence events for each user', ->
    spy = sinon.spy()
    emitter = new EventEmitter;
    emitter.on('presence', spy);

    emitter.getUserIds = () ->
      ['123', '456']

    oscar.checkForUserStatus(emitter)
    sinon.assert.calledOnce(spy);
