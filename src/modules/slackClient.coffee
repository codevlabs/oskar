Slack = require '../vendor/client'
mongoClient = require '../modules/mongoClient'
InputHelper = require '../helper/inputHelper'
timeHelper = require '../helper/timeHelper'
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
		@disabledUsers = ['***REMOVED***', '***REMOVED***', 'USLACKBOT']
		@disabledChannels = ['***REMOVED***']
		if mongo? then @mongo = mongo

	connect: () ->
		@slack = new Slack(@token, @autoReconnect, @autoMark)
		@slack.on 'presenceChange', @presenceChangeHandler
		@slack.on 'message', @messageHandler

		promise = new Promise (resolve, reject) =>

			@slack.on 'open', =>
				for user, attrs of @slack.users when attrs.is_bot is false
					@users.push attrs
				resolve(@slack)

			@slack.on 'error', (error) ->
				reject(error)

			@slack.login()

	getUsers: () ->
		# remove slackbot and disabled users
		users = @users.filter (user) =>
			return @disabledUsers.indexOf(user.id) is -1
		return users

	getUserIds: () ->
    users = @getUsers().map (user) ->
    	return user.id

	getUser: (userId) ->
		# ignore disabled users
		if @disabledUsers.indexOf(userId) isnt -1
			return null

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

	presenceChangeHandler: (data, presence) =>

		data =
			userId: data.id
			status: presence

		@emit 'presence', data

	messageHandler: (message) =>

		# if user is bot, return
		if ((@getUser message.user) is undefined)
			return false

		# disable messages from watercooler
		if (@disabledChannels.indexOf(message.channel) isnt -1)
			return false

		message.type = 'input'
		@emit 'message', message

	postMessage: (userId, message) ->

		if (userId in @channels)
			return @slack.postMessage @channels[userId].channel.id, message, () ->

		@slack.openDM userId, (res) =>
			@channels[userId] = res
			@slack.postMessage res.channel.id, message, () ->

module.exports = SlackClient