# Set up express
express = require 'express'
app = express()

# Set up Mongo client
MongoClient = require './src/MongoClient'
mongo = new MongoClient()
mongo.connect()

# Set up Slack client
SlackClient = require './src/slackClient'
slack = new SlackClient(mongo)
slack.connect()

timeHelper = require './src/helper/timeHelper'

slack.on 'feedback', (data) ->
  mongo.saveUserFeedback data.user, data.text

slack.on 'feedbackMessage', (data) ->
  mongo.saveUserFeedbackMessage data.user, data.text

slack.on 'presence', (data) ->

  user = slack.getUser(data.userId)

  # if user doesn't exist, create new one
  mongo.saveUser(user).then (res) ->

    mongo.getLatestUserTimestampForProperty('feedback', data.userId).then (res) ->

      # if user doesnt exist, skip
      if res is false
        return

      mongo.saveUserStatus data.userId, data.status

      # if user switched to anything but active, skip
      if data.status != 'active'
        return

      # if it's weekend, skip
      if timeHelper.isWeekend()
        return

      # if current time is not in interval, skip
      userLocalDate = timeHelper.getLocalDate null, user.tz_offset / 3600
      if !timeHelper.isDateInsideInterval 11, 13, userLocalDate
        return

      # if last activity (res) is null or timestamp has expired, ask for status
      if (res is null || timeHelper.hasTimestampExpired 20, res)
        slack.askUserForStatus data.userId

# Set port
app.set 'port', process.env.PORT || 5000

# Routing
app.get '/', (req, res) ->

app.listen app.get('port'), ->
  console.log "Node app is running on port: #{app.get('port')}"