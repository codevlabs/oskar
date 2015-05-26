###################################################################
# Setup the tests
###################################################################
should = require 'should'

# Client = require '../src/client'
InputHelper = require '../src/helper/inputHelper'

###################################################################
# Helper
###################################################################

describe 'InputHelper', ->

  it 'should return false if status string is not a number', ->
    response = InputHelper.isValidStatus 'a random string'
    response.should.be.equal(false)

  it 'should return true if status string is a valid number', ->
    response = InputHelper.isValidStatus '3'
    response.should.be.equal(true)

  it 'should return the username if using user status command', ->
    text = 'How is <@U025P95MR>?'
    response = InputHelper.isAskingForUserStatus(text)
    response.should.be.equal('U025P95MR')

    text = 'How is <@***REMOVED***> ?'
    response = InputHelper.isAskingForUserStatus(text)
    response.should.be.equal('***REMOVED***')

  it 'should return false if the user status command isnt recognized', ->
    text = 'How do you think is matt'
    response = InputHelper.isAskingForUserStatus(text)
    should(response).be.equal(null)

  it 'should return "channel" if user is asking for channel status', ->
    text = 'How is <!channel>?'
    response = InputHelper.isAskingForUserStatus(text)
    should(response).be.equal('channel')