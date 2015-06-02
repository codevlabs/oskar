###################################################################
# Setup the tests
###################################################################
should = require 'should'

# Client = require '../src/client'
MongoClient = require '../src/modules/mongoClient'

# Generate a new instance for each test.
mongoClient = null
connect = null

db = null
collection = null

zsolt =
  id: "U025P99EH",
  name: "zsolt",
  real_name: "Zsolt Kocsmarszky",
  tz: "Europe/Amsterdam",
  tz_offet: 7200,
  profile:
    image_48: "https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2015-02-11/3686875247_e13558702f7cf8fc2382_48.jpg"

arnas =
  id: "U025QPNRP",
  name: "goldmountain",
  real_name: "Arnas Goldberg",
  tz: "Europe/Brussels",
  tz_offet: 7200,
  profile:
    image_48: "https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2015-01-23/3494335709_69bc62614666a96eb580_48.jpg"

users = [zsolt, arnas]

###################################################################
# Mongo client
###################################################################

describe 'MongoClient', ->

  before ->
    mongoClient = new MongoClient('mongodb://127.0.0.1:27017')
    connect = mongoClient.connect()

  this.timeout(10000);

  it 'should connect to the mongo client', (done) ->
    connect.then (res) ->
      should.exist(res)
      done()

###################################################################
# Mongo client users
###################################################################

  describe 'MongoClientUsers', ->

    before ->
      connect.then (res) ->
        db = res
        collection = db.collection('users')

        # empty database
        collection.remove({})

    it 'should save a new user to the db', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs.length.should.be.equal(1)
          done()

    it 'should not save a user twice', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        mongoClient.saveUser(users[0]).then (res) ->
          collection.find({ id: users[0].id }).toArray (err, docs) ->
            docs.length.should.be.equal(1)
            done()

    it 'should retain users', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        mongoClient.saveUser(users[1]).then (res) ->
          collection.find({ id: users[0].id }).toArray (err, docs) ->
            docs.length.should.be.equal(1)
            done()

    it 'should save user status in user object', (done) ->
      mongoClient.saveUserStatus(users[0].id, 'away').then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs[0].should.have.property('activity')
          done()

    it 'should save multiple user statuses in user object', (done) ->
      mongoClient.saveUserStatus(users[0].id, 'away').then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs[0].activity.length.should.be.equal(2)
          done()

    it 'should get the last status for a user', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', users[0].id).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->

          timestamp = 0

          # get highest timestamp
          for activity in docs[0].activity
            timestamp = activity.timestamp if activity.timestamp > timestamp

          res.should.be.equal(timestamp)
          done()

    it 'should return null if user has no activity', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'U025QPNRP').then (res) ->
        should(res).be.exactly(null)
        done()

    it 'should return null if user doesnt exist yet', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'U0281LQKQ').then (res) ->
        should(res).be.exactly(false)
        done()

    it 'should save user feedback', (done) ->
      userId = 'U025QPNRP'
      feedback = 4

      mongoClient.saveUserFeedback(userId, feedback).then (res) ->
        collection.find({ id: userId }).toArray (err, docs) ->
          should(docs[0].feedback[0].status).be.equal(feedback)
          done()

    it 'should save a user feedback for the last feedback entry', (done) ->
      userId = 'U025QPNRP'
      feedbackMessage = 'This is my user feedback message'

      mongoClient.saveUserFeedbackMessage(userId, feedbackMessage).then (res) ->
        collection.find({ id: userId }).toArray (err, docs) ->
          should(docs[0].feedback[0].message).be.equal(feedbackMessage)
          done()

    it 'should get the latest user feedback', (done) ->
      userId = 'U025QPNRP'
      feedback = 5
      feedbackMessage = 'Another feedback message'

      mongoClient.saveUserFeedback(userId, feedback).then (res) ->
        mongoClient.saveUserFeedbackMessage(userId, feedbackMessage).then (res) ->
          mongoClient.getLatestUserFeedback(userId).then (res) ->
            res.status.should.be.equal(5)
            res.message.should.be.equal('Another feedback message')
            done()

    it 'should return feedback for all users', (done) ->
      userId = 'U025P99EH'
      feedback = 6

      userIds = ['U025QPNRP', 'U025P99EH']
      mongoClient.saveUserFeedback(userId, feedback).then (res) =>
        mongoClient.getAllUserFeedback(userIds).then (res) =>
          res[0].id.should.be.equal('U025P99EH')
          res[1].id.should.be.equal('U025QPNRP')
          res[0].should.have.property('feedback')
          res[1].should.have.property('feedback')
          res[1].feedback.should.have.property('status')
          res[1].feedback.should.have.property('timestamp')
          res[1].feedback.should.have.property('message')
          res[1].feedback.status.should.be.equal(5)
          console.log done
          done()

