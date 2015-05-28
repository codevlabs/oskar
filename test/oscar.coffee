###################################################################
# Setup the tests
###################################################################
should = require 'should'

# Client = require '../src/client'
oscar = require '../src/oscar'

###################################################################
# Helper
###################################################################

describe 'oscar', ->

  before ->
    oscar = new Oscar()

  it 'should trigger presence events for each user', (done) ->
    oscar.checkForUserStatus()
