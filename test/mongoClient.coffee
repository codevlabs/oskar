###################################################################
# Setup the tests
###################################################################
should      = require 'should'
MongoClient = require '../src/modules/mongoClient'

# Generate a new instance for each test.
mongoClient = null
connect     = null
db          = null
collection  = null

paul =
  id        : "user1",
  name      : "paul",
  real_name : "Paul Miller",
  tz        : "Europe/Amsterdam",
  tz_offet  : 7200,
  profile   :
    image_48  : "paul.jpg"

phil =
  id        : "user2",
  name      : "phil",
  real_name : "Phil Meyer",
  tz        : "Europe/Brussels",
  tz_offet  : 7200,
  profile   :
    image_48  : "phil.jpg"

users = [paul, phil]

###################################################################
# Mongo client
###################################################################

describe 'MongoClient', ->

  before ->
    # connect to local test database
    mongoClient = new MongoClient('mongodb://127.0.0.1:27017')
    connect     = mongoClient.connect()

  this.timeout(10000);

  it 'should connect to the mongo client', (done) ->
    connect.then (res) ->
      should.exist res
      done()

###################################################################
# Mongo client users
###################################################################

  describe 'MongoClientUsers', ->

    before ->
      connect.then (res) ->
        db = res
        collection = db.collection 'users'

        # empty database
        collection.remove({})

    it 'should save a new user to the db', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs.length.should.be.equal 1
          done()

    it 'should not save a user twice', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        mongoClient.saveUser(users[0]).then (res) ->
          collection.find({ id: users[0].id }).toArray (err, docs) ->
            docs.length.should.be.equal 1
            done()

    it 'should retain users', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        mongoClient.saveUser(users[1]).then (res) ->
          collection.find({ id: users[0].id }).toArray (err, docs) ->
            docs.length.should.be.equal 1
            done()

  describe 'MongoClientStatus', ->

    it 'should save user status in user object', (done) ->
      mongoClient.saveUserStatus(users[0].id, 'away').then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs[0].should.have.property 'activity'
          done()

    it 'should save multiple user statuses in user object', (done) ->
      mongoClient.saveUserStatus(users[0].id, 'away').then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs[0].activity.length.should.be.equal 2
          done()

    it 'should get the last status for a user', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', users[0].id).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->

          timestamp = 0

          # get highest timestamp
          for activity in docs[0].activity
            timestamp = activity.timestamp if activity.timestamp > timestamp

          res.should.be.equal timestamp
          done()

  describe 'MongoClientActivity', ->

    it 'should return null if user has no activity', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'user2').then (res) ->
        should(res).be.exactly null
        done()

    it 'should return null if user doesnt exist yet', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'U0281LQKQ').then (res) ->
        should(res).be.exactly false
        done()

  describe 'MongoClientFeedback', ->

    it 'should save user feedback', (done) ->
      userId   = 'user2'
      feedback = 4

      mongoClient.saveUserFeedback(userId, feedback).then (res) ->
        collection.find({ id: userId }).toArray (err, docs) ->
          should(docs[0].feedback[0].status).be.equal feedback
          done()

    it 'should save a user feedback for the last feedback entry', (done) ->
      userId          = 'user2'
      feedbackMessage = 'This is my user feedback message'

      mongoClient.saveUserFeedbackMessage(userId, feedbackMessage).then (res) ->
        collection.find({ id: userId }).toArray (err, docs) ->
          should(docs[0].feedback[0].message).be.equal feedbackMessage
          done()

    it 'should get the latest user feedback', (done) ->
      userId          = 'user2'
      feedback        = 5
      feedbackMessage = 'Another feedback message'

      mongoClient.saveUserFeedback(userId, feedback).then (res) ->
        mongoClient.saveUserFeedbackMessage(userId, feedbackMessage).then (res) ->
          mongoClient.getLatestUserFeedback(userId).then (res) ->
            res.status.should.be.equal 5
            res.message.should.be.equal 'Another feedback message'
            done()

    it 'should return feedback for all users', (done) ->
      userId   = 'user1'
      feedback = 6

      userIds = ['user1', 'user2']
      mongoClient.saveUserFeedback(userId, feedback).then (res) =>
        mongoClient.getAllUserFeedback(userIds).then (res) =>

          res[0].should.have.property 'id'
          res[1].should.have.property 'id'

          res[0].should.have.property 'feedback'
          res[1].should.have.property 'feedback'

          res[0].feedback.should.have.property 'status'
          res[1].feedback.should.have.property 'status'

          res[0].feedback.should.have.property 'timestamp'
          res[1].feedback.should.have.property 'timestamp'

          done()

    it 'should return how many times user has given feedback', (done) ->
      userId   = 'user1'
      feedback = 4

      today = new Date()
      mongoClient.saveUserFeedback(userId, feedback).then (res) =>
        mongoClient.getUserFeedbackCount(userId, today).then (res) =>
          res.should.be.equal 2
          done()

  describe 'MongoClientOnboardingStatus', ->

    it 'should return the current onboarding status 0 for the user if no status has been saved before', (done) ->

      userId = 'user1'
      mongoClient.getOnboardingStatus(userId).then (res) ->
        res.should.be.equal 0
        done()

    it 'should save the onboarding status for the user', (done) ->

      userId = 'user1'
      mongoClient.setOnboardingStatus(userId).then (res) =>

        res.should.have.property 'result'
        done()

    it 'should return the saved value', (done) ->

      userId = 'user1'
      mongoClient.setOnboardingStatus(userId, 1).then (res) =>
        mongoClient.getOnboardingStatus(userId).then (res) =>
          res.should.be.equal 1
          done()
