var InputHelper, MongoClient, Oskar, SlackClient, TimeHelper, express,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

express = require('express');

MongoClient = require('./modules/mongoClient');

SlackClient = require('./modules/slackClient');

TimeHelper = require('./helper/timeHelper');

InputHelper = require('./helper/inputHelper');

Oskar = (function() {
  function Oskar(mongo, slack) {
    this.checkForUserStatus = __bind(this.checkForUserStatus, this);
    this.handleFeedbackMessage = __bind(this.handleFeedbackMessage, this);
    this.revealStatusForUser = __bind(this.revealStatusForUser, this);
    this.revealStatusForChannel = __bind(this.revealStatusForChannel, this);
    this.revealStatus = __bind(this.revealStatus, this);
    this.messageHandler = __bind(this.messageHandler, this);
    this.presenceHandler = __bind(this.presenceHandler, this);
    this.app = express();
    this.app.set('view engine', 'ejs');
    this.app.set('views', 'src/views/');
    this.app.use('/public', express["static"](__dirname + '/public'));
    this.mongo = mongo || new MongoClient();
    this.mongo.connect();
    this.slack = slack || new SlackClient();
    this.slack.connect();
    this.setupEvents();
    this.setupRoutes();
    setInterval((function(_this) {
      return function() {
        return _this.checkForUserStatus(_this.slack);
      };
    })(this), 3600 * 1000);
  }

  Oskar.prototype.setupEvents = function() {
    this.slack.on('presence', this.presenceHandler);
    return this.slack.on('message', this.messageHandler);
  };

  Oskar.prototype.setupRoutes = function() {
    this.app.set('port', process.env.PORT || 5000);
    this.app.get('/', (function(_this) {
      return function(req, res) {
        var userIds, users;
        users = _this.slack.getUsers();
        userIds = users.map(function(user) {
          return user.id;
        });
        return _this.mongo.getAllUserFeedback(userIds).then(function(statuses) {
          var filteredStatuses;
          filteredStatuses = [];
          statuses.forEach(function(status) {
            return filteredStatuses[status.id] = status.feedback;
          });
          return res.render('pages/index', {
            users: users,
            statuses: filteredStatuses
          });
        });
      };
    })(this));
    return this.app.listen(this.app.get('port'), function() {
      return console.log("Node app is running on port 5000");
    });
  };

  Oskar.prototype.presenceHandler = function(data) {
    var user;
    user = this.slack.getUser(data.userId);
    if (user === null) {
      return false;
    }
    return this.mongo.userExists(data.userId).then((function(_this) {
      return function(res) {
        if (!res) {
          _this.mongo.saveUser(user).then(function(res) {
            return _this.requestUserFeedback(data.userId, data.status);
          });
        }
        return _this.requestUserFeedback(data.userId, data.status);
      };
    })(this));
  };

  Oskar.prototype.messageHandler = function(message) {
    var userId;
    if (userId = InputHelper.isAskingForUserStatus(message.text)) {
      return this.revealStatus(userId, message);
    }
    if (this.slack.isUserCommentAllowed(message.user)) {
      return this.handleFeedbackMessage(message);
    }
    return this.mongo.getLatestUserTimestampForProperty('feedback', message.user).then((function(_this) {
      return function(timestamp) {
        return _this.evaluateFeedback(message, timestamp);
      };
    })(this));
  };

  Oskar.prototype.requestUserFeedback = function(userId, status) {
    return this.mongo.getLatestUserTimestampForProperty('feedback', userId).then((function(_this) {
      return function(res) {
        if (res === false) {
          return;
        }
        _this.mongo.saveUserStatus(userId, status);
        if (status !== 'active' && status !== 'triggered') {
          return;
        }
        if (TimeHelper.isWeekend()) {
          return;
        }
        if (res === null || TimeHelper.hasTimestampExpired(20, res)) {
          return _this.composeMessage(userId, 'requestFeedback');
        }
      };
    })(this));
  };

  Oskar.prototype.evaluateFeedback = function(message, latestFeedbackTimestamp) {
    if (latestFeedbackTimestamp && !TimeHelper.hasTimestampExpired(20, latestFeedbackTimestamp)) {
      return this.composeMessage(message.user, 'alreadySubmitted');
    }
    if (!InputHelper.isValidStatus(message.text)) {
      return this.composeMessage(message.user, 'invalidInput');
    }
    this.mongo.saveUserFeedback(message.user, message.text);
    if (parseInt(message.text) < 5) {
      this.slack.allowUserComment(message.user);
      return this.composeMessage(message.user, 'lowFeedback');
    }
    return this.composeMessage(message.user, 'feedbackReceived');
  };

  Oskar.prototype.revealStatus = function(userId, message) {
    if (userId === 'channel') {
      return this.revealStatusForChannel(message.user);
    } else {
      return this.revealStatusForUser(message.user, userId);
    }
  };

  Oskar.prototype.revealStatusForChannel = function(userId) {
    var userIds;
    userIds = this.slack.getUserIds();
    return this.mongo.getAllUserFeedback(userIds).then((function(_this) {
      return function(res) {
        return _this.composeMessage(userId, 'revealChannelStatus', res);
      };
    })(this));
  };

  Oskar.prototype.revealStatusForUser = function(userId, targetUserId) {
    var userObj;
    userObj = this.slack.getUser(targetUserId);
    return this.mongo.getLatestUserFeedback(targetUserId).then((function(_this) {
      return function(res) {
        if (res) {
          res.user = userObj;
        }
        return _this.composeMessage(userId, 'revealUserStatus', res);
      };
    })(this));
  };

  Oskar.prototype.handleFeedbackMessage = function(message) {
    this.slack.disallowUserComment(message.user);
    this.mongo.saveUserFeedbackMessage(message.user, message.text);
    return this.composeMessage(message.user, 'feedbackMessageReceived');
  };

  Oskar.prototype.composeMessage = function(userId, messageType, obj) {
    var statusMsg, userObj;
    if (messageType === 'requestFeedback') {
      userObj = this.slack.getUser(userId);
      statusMsg = "Hey " + userObj.profile.first_name + ", how are you doing today? Please reply with a number between 0 and 9. I\'ll keep track of everything for you.";
    }
    if (messageType === 'revealChannelStatus') {
      obj.forEach((function(_this) {
        return function(user) {
          userObj = _this.slack.getUser(user.id);
          statusMsg += "" + userObj.profile.first_name + " is feeling *" + user.feedback.status + "*";
          if (user.feedback.message) {
            statusMsg += " (" + user.feedback.message + ")";
          }
          return statusMsg += ".\r\n";
        };
      })(this));
    }
    if (messageType === 'revealUserStatus') {
      if (!obj) {
        statusMsg = "Oh, it looks like I haven\'t heard from " + obj.user.profile.first_name + " for a while. Sorry!";
      } else {
        statusMsg = "" + obj.user.profile.first_name + " is feeling *" + obj.status + "* on a scale from 0 to 9.";
        if (res.message) {
          statusMsg += "\r\nThe last time I asked him what\'s up he replied: " + obj.message;
        }
      }
    }
    if (messageType === 'alreadySubmitted') {
      statusMsg = 'Oops, looks like I\'ve already received some feedback from you in the last 20 hours.';
    }
    if (messageType === 'invalidInput') {
      statusMsg = 'Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 0 and 9';
    }
    if (messageType === 'lowFeedback') {
      statusMsg = 'Feel free to share with me what\'s wrong. I will treat it with confidence';
    }
    if (messageType === 'feedbackReceived') {
      statusMsg = 'Thanks a lot, buddy! Keep up the good work!';
    }
    if (messageType === 'feedbackMessageReceived') {
      statusMsg = 'Thanks, my friend. I really appreciate your openness.';
    }
    if (userId && statusMsg) {
      return this.slack.postMessage(userId, statusMsg);
    }
  };

  Oskar.prototype.checkForUserStatus = function(slack) {
    var userIds;
    userIds = slack.getUserIds();
    return userIds.forEach(function(userId) {
      var data;
      data = {
        userId: userId,
        status: 'triggered'
      };
      return slack.emit('presence', data);
    });
  };

  return Oskar;

})();

module.exports = Oskar;
