express = require 'express'
MongoClient = require './modules/mongoClient'
SlackClient = require './modules/slackClient'
TimeHelper = require './helper/timeHelper'
InputHelper = require './helper/inputHelper'

class Oscar

  constructor: (mongo, slack) ->
    @app = express()
    @app.set 'view engine', 'ejs'
    @app.set 'views', 'src/views/'
    @app.use '/public', express.static(__dirname + '/public')

    @mongo = mongo || new MongoClient()
    @mongo.connect()

    @slack = slack || new SlackClient()
    @slack.connect()

    @setupEvents()
    @setupRoutes()

    # check for user's status every hour
    setInterval ->
      @checkForUserStatus (@slack)
    , 3600 * 1000

  setupEvents: () ->
    @slack.on 'presence', @presenceHandler
    @slack.on 'message', @messageHandler

  setupRoutes: () ->
    @app.set 'port', process.env.PORT || 5000

    @app.get '/', (req, res) =>
      users = @slack.getUsers()
      userIds = users.map (user) ->
        return user.id
      @mongo.getAllUserFeedback(userIds).then (statuses) =>
        filteredStatuses = []
        statuses.forEach (status) ->
          filteredStatuses[status.id] = status.feedback
        res.render('pages/index', { users: users, statuses: filteredStatuses })

    @app.listen @app.get('port'), ->
      console.log "Node app is running on port 5000"

  presenceHandler: (data) =>

    @mongo.userExists(data.userId).then (res) =>
      if !res
        user = @slack.getUser(data.userId)
        @mongo.saveUser(user).then (res) =>
          # @presenceHandler data
      @requestUserFeedback data.userId, data.status

  messageHandler: (message) =>

    console.log message

    # if user is asking for feedback of user with ID
    if userId = InputHelper.isAskingForUserStatus(message.text)
      return @revealStatus userId, message

    # if comment is allowed, save in DB
    if @slack.isUserCommentAllowed message.user
      return @handleFeedbackMessage message

    # check last feedback timestamp and evaluate feedback
    @mongo.getLatestUserTimestampForProperty('feedback', message.user).then (timestamp) =>
      @evaluateFeedback message, timestamp

  requestUserFeedback: (userId, status) ->

    @mongo.getLatestUserTimestampForProperty('feedback', userId).then (res) =>

      # if user doesnt exist, skip
      if res is false
        return

      @mongo.saveUserStatus userId, status

      # if user switched to anything but active or triggered, skip
      if status != 'active' && status != 'triggered'
        return

      # if it's weekend, skip
      if TimeHelper.isWeekend()
        return

      # if current time is not in interval, skip
      # userLocalDate = timeHelper.getLocalDate null, user.tz_offset / 3600
      # if !timeHelper.isDateInsideInterval 8, 12, userLocalDate
      #   return
      #

      # if last activity (res) is null or timestamp has expired, ask for status
      if (res is null || TimeHelper.hasTimestampExpired 20, res)
        @composeMessage userId, 'requestFeedback'

  evaluateFeedback: (message, latestFeedbackTimestamp) ->

    # if user has already submitted feedback in the last x hours, reject
    if (latestFeedbackTimestamp && !TimeHelper.hasTimestampExpired 20, latestFeedbackTimestamp)
      return @composeMessage message.user, 'alreadySubmitted'

    # if user didn't send valid feedback
    if !InputHelper.isValidStatus message.text
      return @composeMessage message.user, 'invalidInput'

    @mongo.saveUserFeedback message.user, message.text

    # if feedback is lower than 5, ask user for additional feedback
    if (parseInt(message.text) < 5)
      @slack.allowUserComment message.user
      return @composeMessage message.user, 'lowFeedback'

    @composeMessage message.user, 'feedbackReceived'

  revealStatus: (userId, message) =>
    if userId is 'channel'
      @revealStatusForChannel(message.user)
    else
      @revealStatusForUser(message.user, userId)

  revealStatusForChannel: (userId) =>
    userIds = @slack.getUserIds()
    @mongo.getAllUserFeedback(userIds).then (res) =>
      @composeMessage userId, 'revealChannelStatus', res

  revealStatusForUser: (userId, targetUserId) =>
    userObj = @slack.getUser targetUserId
    @mongo.getLatestUserFeedback(targetUserId).then (res) =>
      if (res)
        res.user = userObj
      @composeMessage userId, 'revealUserStatus', res

  handleFeedbackMessage: (message) =>
    @slack.disallowUserComment message.user
    @mongo.saveUserFeedbackMessage message.user, message.text
    @composeMessage message.user, 'feedbackMessageReceived'

  composeMessage: (userId, messageType, obj) ->

    # request feedback
    if messageType is 'requestFeedback'
      statusMsg = ''

    # channel info
    if messageType is 'revealChannelStatus'
      obj.forEach (user) =>
        userObj = @getUser user.id
        statusMsg += "#{userObj.profile.first_name} is feeling *#{user.feedback.status}*"
        if user.feedback.message
          statusMsg += " (#{user.feedback.message})"
        statusMsg += ".\r\n"

    # user info
    if messageType is 'revealUserStatus'
      if !obj
        statusMsg = "Oh, it looks like I haven\'t heard from #{obj.user.profile.first_name} for a while. Sorry!"
      else
        statusMsg = "#{obj.user.profile.first_name} is feeling *#{obj.status}* on a scale from 0 to 9."
        if res.message
          statusMsg += "\r\nThe last time I asked him what\'s up he replied: #{obj.message}"

    # already submitted
    if messageType is 'alreadySubmitted'
      statusMsg = 'Oops, looks like I\'ve already received some feedback from you in the last 20 hours.'

    # invalid input
    if messageType is 'invalidInput'
      statusMsg = 'Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 0 and 9'

    # low feedback
    if messageType is 'lowFeedback'
      statusMsg = 'Feel free to share with me what\'s wrong. I will treat it with confidence'

    # feedback already received
    if messageType is 'feedbackReceived'
      statusMsg = ''

    # feedback received
    if messageType is 'feedbackMessageReceived'
      statusMsg = 'Thanks, my friend. I really appreciate your openness.'

    @slack.postMessage(userId, statusMsg)

  checkForUserStatus: (slack) =>
    userIds = slack.getUserIds()
    userIds.forEach (userId) ->
      data =
        userId: userId
        status: 'triggered'
      slack.emit 'presence', data

module.exports = Oscar