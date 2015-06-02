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

    describe 'methods', ->

      it 'should return a list of users', ->
        users.length.should.be.greaterThan(0)

      it 'should get the IDs of all users', ->
        users = slackClient.getUserIds()
        users[0].should.match(/^U\w+$/)

      it 'should not contain IDs of disabled users', ->
        users = slackClient.getUserIds()
        users.indexOf('***REMOVED***').should.be.equal(-1)
        users.indexOf('***REMOVED***').should.be.equal(-1)

      it 'should get a user', ->
        user = slackClient.getUser('U025P99EH')
        user.name.should.be.equal('zsolt')
        user.profile.first_name.should.be.equal('Zsolt')
        user.profile.last_name.should.be.equal('Kocsmarszky')

      it 'should allow a user comment for a user', ->
        userId = 'U025P99EH'
        slackClient.allowUserComment(userId)
        user = slackClient.getUser(userId)
        user.allowComment.should.be.equal(true)

      it 'should allow a user comment for a user', ->
        userId = 'U025P99EH'
        slackClient.disallowUserComment(userId)
        user = slackClient.getUser(userId)
        user.allowComment.should.be.equal(false)

      it 'should return false if user comment is not yet allowed', ->
        userId = 'U025P99EH'
        allowed = slackClient.isUserCommentAllowed(userId)
        allowed.should.be.equal(false)

      it 'should return true if user comment is allowed after setting it', ->
        userId = 'U025P99EH'
        slackClient.allowUserComment(userId)
        allowed = slackClient.isUserCommentAllowed(userId)
        allowed.should.be.equal(true)

    describe 'handlers', ->

      it 'should send a presence event when user changes presence', ->

        data =
          id: '***REMOVED***'

        spy = sinon.spy()
        slackClient.on('presence', spy);
        slackClient.presenceChangeHandler data, 'away'

        spy.called.should.be.equal(true);
        spy.args[0][0].userId.should.be.equal('***REMOVED***')
        spy.args[0][0].status.should.be.equal('away')

      it 'should return false when message handler is called with no user', ->
        message =
          user: undefined

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should return false when message handler is called for a disabled channel', ->
        message =
          channel = '***REMOVED***'

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should return false when message handler if user is slackbot', ->

        message =
          userId: 'USLACKBOT'

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should return false when message handler is called with a disabled channel', ->

        message =
          channel = '***REMOVED***'

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should trigger a message event when message handler is called with a user and valid text is passed', ->

        message =
          userId: '***REMOVED***'
          text: 'How is <@***REMOVED***>?'

        spy = sinon.spy()
        slackClient.on 'message', spy

        slackClient.messageHandler message
        spy.called.should.be.equal true
        spy.args[0][0].type.should.be.equal 'input'
        spy.args[0][0].userId.should.be.equal '***REMOVED***'
        spy.args[0][0].text.should.be.equal 'How is <@***REMOVED***>?'