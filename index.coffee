Slack = require './src/client'

token = '***REMOVED***' # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true
autoMark = true

slack = new Slack(token, autoReconnect, autoMark)

# open slack
slack.on 'open', ->

	users = []

	for user, attrs of slack.users when attrs.is_bot is false
		users.push attrs

	console.log users

	# send a message when user wakes up





  # get user with ID (marcel)
  # user = slack.getUserByID('U0281LQK0')

  # open direct message channel
  # slack.openDM user.id, (data) ->

  	# send a direct message to user
  	# slack.postMessage data.channel.id, "Hey, how are you doing today?", (data) ->
  	#	console.log data

  # send a message in the slackbot channel
  	

slack.on 'error', (error) ->
  console.error "Error: #{error}"


slack.login()
