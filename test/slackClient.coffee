###################################################################
# Setup the tests
###################################################################
should = require 'should'
sinon = require 'sinon'

# Client = require '../src/client'
SlackClient = require '../src/modules/slackClient'

# Generate a new instance for each test.
slackClient = null
connect = null

###################################################################
# Slack client
###################################################################

describe 'SlackClient', ->

  before ->
    slackClient = new SlackClient()
    connect = slackClient.connect()

  this.timeout(10000);

  it 'should connect to the slack client', (done) ->
    connect.then (res) ->
      res.should.have.property 'autoReconnect'
      res.should.have.property 'autoMark'
      done()

###################################################################
# Slack client users
###################################################################

  describe 'SlackClientUsers', ->

    users = null

    before ->
      connect.then ->
        users = slackClient.getUsers()

    it 'should return a list of users', ->
      users.length.should.be.greaterThan(0)

    it 'should get the IDs of all users', ->
      users = slackClient.getUserIds()
      users[0].should.match(/^U\w+$/)

    it 'should not contain IDs of disabled users', ->
      users = slackClient.getUserIds()
      users.indexOf('***REMOVED***').should.be.equal(-1)
      users.indexOf('***REMOVED***').should.be.equal(-1)

    it 'should send a presence event when user changes presence', ->

        data =
          userId: '***REMOVED***'

        spy = sinon.spy()
        slackClient.on('presence', spy);
        slackClient.onPresenceChangeHandler data, 'away'

        spy.called.should.be.equal(true);

      describe 'onMessageHandler', ->

        it 'should return false when called with no user', ->
          message =
            user: undefined

          response = slackClient.onMessageHandler(message)
          response.should.be.equal(false)

        it 'should return false for a disabled channel', ->
          message =
            channel = '***REMOVED***'

          response = slackClient.onMessageHandler(message)
          response.should.be.equal(false)

        it 'should trigger a sendMessage event when a user ID is passed', ->

          message =
            user: '***REMOVED***'
            text: 'How is <@***REMOVED***>?'

          spy = sinon.spy()
          slackClient.on('sendMessage', spy)

          slackClient.onMessageHandler(message)
          spy.called.should.be.equal(true)
          # userStatus
