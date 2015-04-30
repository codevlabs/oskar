cool = require 'cool-ascii-faces'

# Set up express
express = require 'express'
app = express()

# Set up Slack client
SlackClient = require './src/slackClient'
slack = new SlackClient()
# slack.connect()

# Set port
app.set 'port', process.env.PORT || 3000

# Routing
app.get '/', (req, res) ->
  res.send(cool())

app.get '/test', (req, res)->
  res.send 'testing'

app.listen app.get('port'), ->
  console.log "Node app is running on port: #{app.get('port')}"