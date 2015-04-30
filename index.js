var SlackClient, app, cool, express, slack;

cool = require('cool-ascii-faces');

express = require('express');

app = express();

SlackClient = require('./src/slackClient');

slack = new SlackClient();

app.set('port', process.env.PORT || 5000);

app.get('/', function(req, res) {
  return res.send(cool());
});

app.get('/test', function(req, res) {
  return res.send('testing');
});

app.listen(app.get('port'), function() {
  return console.log("Node app is running on port: " + (app.get('port')));
});
