###################################################################
# Setup the tests
###################################################################
should = require 'should'

# Client = require '../src/client'
SlackClient = require '../src/slackClient'

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

    it 'should return the user presence', ->
      isPresent = slackClient.isUserPresent('U025P99EH')
      isPresent.should.match(/^active|away$/)

    it 'should return the user timezone', ->
      userTimezone = slackClient.getUserTimezone('U025P99EH')
      userTimezone.should.equal('Europe/Amsterdam')

    it 'should return the user timezone offset', ->
      userTimezone = slackClient.getUserTimezoneOffset('U025P99EH')
      userTimezone.should.equal(7200)

    it 'should send a presence event when user changes presence', (done) ->
      slackClient.on 'presence', (event) =>
        event.should.be.an.Object
        done()
      slackClient.setPresence 'away'

    it 'should set the user property allowComment to true', ->
      slackClient.allowUserComment('U025P99EH')
