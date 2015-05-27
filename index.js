var MongoClient, SlackClient, app, express, mongo, presenceHandler, slack, timeHelper;

express = require('express');

app = express();

MongoClient = require('./src/mongoClient');

mongo = new MongoClient();

mongo.connect();

SlackClient = require('./src/slackClient');

slack = new SlackClient(mongo);

slack.connect();

timeHelper = require('./src/helper/timeHelper');

slack.on('feedback', function(data) {
  return mongo.saveUserFeedback(data.user, data.text);
});

slack.on('feedbackMessage', function(data) {
  return mongo.saveUserFeedbackMessage(data.user, data.text);
});

presenceHandler = function(data) {
  var user;
  user = slack.getUser(data.userId);
  return mongo.saveUser(user).then(function(res) {
    return mongo.getLatestUserTimestampForProperty('feedback', data.userId).then(function(res) {
      if (res === false) {
        return;
      }
      mongo.saveUserStatus(data.userId, data.status);
      if (data.status !== 'active') {
        return;
      }
      if (timeHelper.isWeekend()) {
        return;
      }
      if (res === null || timeHelper.hasTimestampExpired(20, res)) {
        return slack.askUserForStatus(data.userId);
      }
    });
  });
};

slack.on('presence', presenceHandler);

app.set('port', process.env.PORT || 5000);

app.get('/', function(req, res) {
  return res.send('i am awake');
});

app.get('/checkUsers', function(req, res) {
  var userIds;
  userIds = slack.getUserIds();
  userIds.forEach(function(userId) {
    var data;
    data = {
      userId: userId,
      status: 'triggered'
    };
    return slack.emit('presence', data);
  });
  return res.send(userIds);
});

app.listen(app.get('port'), function() {
  return console.log("Node app is running on port: " + (app.get('port')));
});
