Slack = require './vendor/client'
mongoClient = require './mongoClient'
InputHelper = require './helper/inputHelper'
timeHelper = require './helper/timeHelper'
Promise = require 'promise'
{EventEmitter} = require 'events'

class SlackClient extends EventEmitter

	@slack = null
	@mongo = null

	constructor: (mongo = null) ->
		@token = '***REMOVED***'
		@autoReconnect = true
		@autoMark = true
		@users = []
		@channels = []
		if mongo? then @mongo = mongo

	connect: () ->
		@slack = new Slack(@token, @autoReconnect, @autoMark)
		@slack.on 'presenceChange', @onPresenceChangeHandler
		@slack.on 'message', @onMessageHandler

		promise = new Promise (resolve, reject) =>

			@slack.on 'open', =>
				for user, attrs of @slack.users when attrs.is_bot is false
					@users.push attrs
				resolve(@slack)

			@slack.on 'error', (error) ->
				reject(error)

			@slack.login()

	getUsers: () ->
		return @users

	getUser: (userId) ->
		filteredUsers = (user for user in @users when user.id is userId)
		filteredUsers[0]

	allowUserComment: (userId) ->
		user = @getUser(userId)
		user.allowComment = true

	disallowUserComment: (userId) ->
		user = @getUser(userId)
		user.allowComment = false

	isUserCommentAllowed: (userId) ->
		user = @getUser(userId)
		typeof user isnt 'undefined' && typeof user.allowComment isnt 'undefined' && user.allowComment

	setPresence: (presence, cb) ->
		@slack.setPresence presence, cb

	isUserPresent: (userId) ->
		@getUser(userId).presence

	getUserTimezone: (userId) ->
		@getUser(userId).tz

	getUserTimezoneOffset: (userId) ->
		@getUser(userId).tz_offset

	onPresenceChangeHandler: (data, presence) =>

		data =
			userId: data.id
			status: presence

		@emit 'presence', data

	onMessageHandler: (message) =>

		# if user is bot, return
		if ((@getUser message.user) is undefined)
			return false

		# if user is asking for feedback from a specific person
		if user = InputHelper.isAskingForUserStatus(message.text)
			# check if user asked for channel
			if user is 'channel'
				statusMsg = ''
				@mongo.getAllUserFeedback(['U025QPNRP', 'U025P99EH']).then (res) =>
					console.log res
					res.forEach (user) =>
						userObj = @getUser user.id
						statusMsg += "#{userObj.profile.first_name} is feeling *#{user.feedback.status}*"
						if user.feedback.message
							statusMsg += " (#{user.feedback.message})"
						statusMsg += ".\r\n"
					@askUserForStatus(message.user, statusMsg)
				return
			userObj = @getUser user
			# check if user has feedback
			@mongo.getLatestUserFeedback(user).then (res) =>
				if !res
					statusMsg = "Oh, it looks like I haven\'t heard from #{userObj.profile.first_name} for a while. Sorry!"
					@askUserForStatus(message.user, statusMsg)
					return
				statusMsg = "#{userObj.profile.first_name} is feeling *#{res.status}* on a scale from 0 to 9."
				if res.message
					statusMsg += "\r\nThe last time I asked him what\'s up he replied: #{res.message}"
				@askUserForStatus(message.user, statusMsg)
			return

		# if comment is allowed
		if @isUserCommentAllowed message.user
			# save user comment
			@emit 'feedbackMessage', message
			# set back to no comment allowed
			@disallowUserComment message.user
			@askUserForStatus(message.user, 'Thanks, my friend. I really appreciate your openness.')
			return

		# The following conditions require that user hasnt given any feedback for the last x hours
		@mongo.getLatestUserTimestampForProperty('feedback', message.user).then (res) =>

			# if user has already submitted feedback in the last x hours, reject
			if res && !timeHelper.hasTimestampExpired(20, res)
				@askUserForStatus message.user, 'Oops, looks like I\'ve already received some feedback from you in the last 20 hours.'
				return

			# if user didn't send valid feedback
			if !InputHelper.isValidStatus message.text
				@askUserForStatus(message.user, 'Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 0 and 9')
				return

			# if feedback is lower than 5, ask user for additional feedback
			if (parseInt(message.text) < 5)
				@askUserForStatus(message.user, 'Feel free to share with me what\'s wrong. I will treat it with confidence')
				@allowUserComment message.user
				@emit 'feedback', message
				return

			@emit 'feedback', message
			@askUserForStatus(message.user, 'Thanks a lot, buddy! Keep up the good work!')

	askUserForStatus: (userId, message) ->

		user = @getUser(userId)

		message = message || "Hey #{user.name}, how are you doing today? Please reply with a number between 0 and 9. I'll keep track of everything for you."

		if (userId in @channels)
			return @slack.postMessage @channels[res].channel.id, message, () ->

		@slack.openDM userId, (res) =>
			@channels[userId] = res
			@slack.postMessage res.channel.id, message, () ->


module.exports = SlackClient