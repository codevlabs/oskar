express = require 'express'
MongoClient = require './modules/mongoClient'
SlackClient = require './modules/slackClient'
TimeHelper = require './helper/timeHelper'

class Oscar

  constructor: () ->
    @app = express()
    @app.set 'view engine', 'ejs'
    @app.set 'views', 'src/views/'
    @app.use '/public', express.static(__dirname + '/public')
    @mongo = new MongoClient()
    @mongo.connect()
    @slack = new SlackClient(@mongo)
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
    user = @slack.getUser(data.userId)

    # if user doesn't exist, create new one
    @mongo.saveUser(user).then (res) =>

      @mongo.getLatestUserTimestampForProperty('feedback', data.userId).then (res) =>

        # if user doesnt exist, skip
        if res is false
          return

        @mongo.saveUserStatus data.userId, data.status

        # if user switched to anything but active or triggered, skip
        if data.status != 'active' && data.status != 'triggered'
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
          @slack.sendMessage data.userId

  inputHandler: (input) =>

    # if user is asking for feedback of user with ID
    if userId = InputHelper.isAskingForUserStatus(input.text)
      return @revealStatus(userId, input)

    # if comment is allowed, save in DB
    if @slack.isUserCommentAllowed input.user
      return @handleFeedbackMessage input

    # check last feedback timestamp and evaluate feedback
    @mongo.getLatestUserTimestampForProperty('feedback', input.user).then (timestamp) =>
      @evaluateFeedback(input, timestamp)

  evaluateFeedback: (message, latestFeedbackTimestamp) ->

    # if user has already submitted feedback in the last x hours, reject
    if res && !timeHelper.hasTimestampExpired(20, latestFeedbackTimestamp)
      return @composeMessage message.user, 'alreadySubmitted'

    # if user didn't send valid feedback
    if !InputHelper.isValidStatus message.text
      return @composeMessage message.user, 'invalidInput'

    # if feedback is lower than 5, ask user for additional feedback
    if (parseInt(message.text) < 5)
      @slack.allowUserComment message.user
      @mongo.saveUserFeedback message.user, message.text
      return @composeMessage message.user, 'lowFeedback'

    @composeMessage message.user, 'feedbackReceived'

  revealStatus: (userId, input) =>
    if user is 'channel'
      @revealStatusForChannel(input.user)
    else
      @revealStatusForUser(input.user, userId)

  revealStatusForChannel: (userId) =>
    users = @slack.getUserIds()
    @mongo.getAllUserFeedback(users).then (res) =>
      @composeMessage userId, 'channelStatus', res

  revealStatusForUser: (userId, targetUserId) =>
    userObj = @slack.getUser targetUser
    @mongo.getLatestUserFeedback(targetUserId).then (res) =>
      res.user = userObj
      @composeMessage userId, 'userStatus', res

  handleFeedbackMessage: (input) =>
    @slack.disallowUserComment input.user
    @mongo.saveUserFeedbackMessage input.user, input.text
    @composeMessage input.user, 'feedbackMessageReceived'

  composeMessage: (userId, messageType, obj) ->

    # channel info
    if messageType is 'revealChannelStatus'
      obj.forEach (user) =>
        userObj = @getUser userId
        statusMsg += "#{userObj.profile.first_name} is feeling *#{user.feedback.status}*"
        if user.feedback.message
          statusMsg += " (#{user.feedback.message})"
        statusMsg += ".\r\n"

    # user info
    if messageType is 'revealUserStatus'
      if !res
        statusMsg = "Oh, it looks like I haven\'t heard from #{userObj.profile.first_name} for a while. Sorry!"
        return
      statusMsg = "#{userObj.profile.first_name} is feeling *#{obj.status}* on a scale from 0 to 9."
      if res.message
        statusMsg += "\r\nThe last time I asked him what\'s up he replied: #{obj.message}"

    if messageType is 'alreadySubmitted'
      statusMsg = 'Oops, looks like I\'ve already received some feedback from you in the last 20 hours.'

    if messageType is 'invalidInput'
      statusMsg = 'Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 0 and 9'

    if messageType is 'lowFeedback'
      statusMsg = 'Feel free to share with me what\'s wrong. I will treat it with confidence'

    if messageType is 'feedbackMessageReceived'
      statusMsg = 'Thanks, my friend. I really appreciate your openness.'

  checkForUserStatus: (slack) =>
    userIds = slack.getUserIds()
    userIds.forEach (userId) ->
      data =
        userId: userId
        status: 'triggered'
      slack.emit 'presence', data

oscar = new Oscar()

module.exports = oscar