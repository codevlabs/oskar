express = require 'express'
MongoClient = require './src/mongoClient'
SlackClient = require './src/slackClient'
TimeHelper = require './src/helper/timeHelper'

class Oscar

  constructor: () ->
    @app = express()
    @mongo = new MongoClient()
    @mongo.connect()
    @slack = new SlackClient(@mongo)
    @slack.connect()

    @setupEvents()
    @setupRoutes()

    # check for user's status every hour
    setInterval @checkForUserStatus, 3600 * 1000

  setupEvents: () ->
    @slack.on 'feedback', (data) ->
      @mongo.saveUserFeedback data.user, data.text

    @slack.on 'feedbackMessage', (data) ->
      @mongo.saveUserFeedbackMessage data.user, data.text

    @slack.on 'presence', @presenceHandler

  setupRoutes: () ->
    @app.set 'port', process.env.PORT || 5000
    @app.get '/', (req, res) ->
      res.send 'i am awake'
    @app.listen @app.get('port'), ->
      console.log "Node app is running on port 5000"

  presenceHandler: (data) =>
    user = @slack.getUser(data.userId)

    # if user doesn't exist, create new one
    @mongo.saveUser(user).then (res) ->

      @mongo.getLatestUserTimestampForProperty('feedback', data.userId).then (res) ->

        # if user doesnt exist, skip
        if res is false
          return

        @mongo.saveUserStatus data.userId, data.status

        # if user switched to anything but active, skip
        if data.status != 'active'
          return

        # if it's weekend, skip
        if TimeHelper.isWeekend()
          return

        # if current time is not in interval, skip
        # userLocalDate = timeHelper.getLocalDate null, user.tz_offset / 3600
        # if !timeHelper.isDateInsideInterval 8, 12, userLocalDate
        #   return

        # if last activity (res) is null or timestamp has expired, ask for status
        if (res is null || TimeHelper.hasTimestampExpired 20, res)
          @slack.askUserForStatus data.userId

  checkForUserStatus: () ->
    userIds = @slack.getUserIds()
    userIds.forEach (userId) ->
      data =
        userId: userId
        status: 'triggered'
      @slack.emit 'presence', data

oscar = new Oscar()