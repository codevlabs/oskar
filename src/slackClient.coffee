Slack = require './client'

class SlackClient
	constructor: () ->
		@token = '***REMOVED***'
		@autoReconnect = true
		@autoMark = true

	connect: () ->
		console.log 'trying to connect...'
		# slack = new Slack(@token, @autoReconnect, @autoMark)

		# slack.on 'open', ->
		# 	users = []
		# 	for user, attrs of slack.users when attrs.is_bot is false
		# 		users.push attrs
		# 		console.log users

		# slack.on 'error', (error) ->
	# 		console.error "Error: #{error}"

		# slack.login()

module.exports = SlackClient