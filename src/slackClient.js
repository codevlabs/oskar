var EventEmitter, InputHelper, Promise, Slack, SlackClient, mongoClient, timeHelper,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Slack = require('./vendor/client');

mongoClient = require('./mongoClient');

InputHelper = require('./helper/inputHelper');

timeHelper = require('./helper/timeHelper');

Promise = require('promise');

EventEmitter = require('events').EventEmitter;

SlackClient = (function(_super) {
  __extends(SlackClient, _super);

  SlackClient.slack = null;

  SlackClient.mongo = null;

  function SlackClient(mongo) {
    if (mongo == null) {
      mongo = null;
    }
    this.onMessageHandler = __bind(this.onMessageHandler, this);
    this.onPresenceChangeHandler = __bind(this.onPresenceChangeHandler, this);
    this.token = '***REMOVED***';
    this.autoReconnect = true;
    this.autoMark = true;
    this.users = [];
    this.channels = [];
    if (mongo != null) {
      this.mongo = mongo;
    }
  }

  SlackClient.prototype.connect = function() {
    var promise;
    this.slack = new Slack(this.token, this.autoReconnect, this.autoMark);
    this.slack.on('presenceChange', this.onPresenceChangeHandler);
    this.slack.on('message', this.onMessageHandler);
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        _this.slack.on('open', function() {
          var attrs, user, _ref;
          _ref = _this.slack.users;
          for (user in _ref) {
            attrs = _ref[user];
            if (attrs.is_bot === false) {
              _this.users.push(attrs);
            }
          }
          return resolve(_this.slack);
        });
        _this.slack.on('error', function(error) {
          return reject(error);
        });
        return _this.slack.login();
      };
    })(this));
  };

  SlackClient.prototype.getUsers = function() {
    var users;
    users = this.users.filter(function(user) {
      return user.id !== 'USLACKBOT';
    });
    return users;
  };

  SlackClient.prototype.getUserIds = function() {
    var users;
    return users = this.getUsers().map(function(user) {
      return user.id;
    });
  };

  SlackClient.prototype.getUser = function(userId) {
    var filteredUsers, user;
    filteredUsers = (function() {
      var _i, _len, _ref, _results;
      _ref = this.users;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        user = _ref[_i];
        if (user.id === userId) {
          _results.push(user);
        }
      }
      return _results;
    }).call(this);
    return filteredUsers[0];
  };

  SlackClient.prototype.allowUserComment = function(userId) {
    var user;
    user = this.getUser(userId);
    return user.allowComment = true;
  };

  SlackClient.prototype.disallowUserComment = function(userId) {
    var user;
    user = this.getUser(userId);
    return user.allowComment = false;
  };

  SlackClient.prototype.isUserCommentAllowed = function(userId) {
    var user;
    user = this.getUser(userId);
    return typeof user !== 'undefined' && typeof user.allowComment !== 'undefined' && user.allowComment;
  };

  SlackClient.prototype.setPresence = function(presence, cb) {
    return this.slack.setPresence(presence, cb);
  };

  SlackClient.prototype.isUserPresent = function(userId) {
    return this.getUser(userId).presence;
  };

  SlackClient.prototype.getUserTimezone = function(userId) {
    return this.getUser(userId).tz;
  };

  SlackClient.prototype.getUserTimezoneOffset = function(userId) {
    return this.getUser(userId).tz_offset;
  };

  SlackClient.prototype.onPresenceChangeHandler = function(data, presence) {
    data = {
      userId: data.id,
      status: presence
    };
    return this.emit('presence', data);
  };

  SlackClient.prototype.onMessageHandler = function(message) {
    var statusMsg, user, userObj, users;
    if ((this.getUser(message.user)) === void 0) {
      return false;
    }
    if (message.channel === '***REMOVED***') {
      return;
    }
    if (user = InputHelper.isAskingForUserStatus(message.text)) {
      if (user === 'channel') {
        statusMsg = '';
        users = this.getUserIds();
        this.mongo.getAllUserFeedback(users).then((function(_this) {
          return function(res) {
            res.forEach(function(user) {
              var userObj;
              userObj = _this.getUser(user.id);
              statusMsg += "" + userObj.profile.first_name + " is feeling *" + user.feedback.status + "*";
              if (user.feedback.message) {
                statusMsg += " (" + user.feedback.message + ")";
              }
              return statusMsg += ".\r\n";
            });
            return _this.askUserForStatus(message.user, statusMsg);
          };
        })(this));
        return;
      }
      userObj = this.getUser(user);
      this.mongo.getLatestUserFeedback(user).then((function(_this) {
        return function(res) {
          if (!res) {
            statusMsg = "Oh, it looks like I haven\'t heard from " + userObj.profile.first_name + " for a while. Sorry!";
            _this.askUserForStatus(message.user, statusMsg);
            return;
          }
          statusMsg = "" + userObj.profile.first_name + " is feeling *" + res.status + "* on a scale from 0 to 9.";
          if (res.message) {
            statusMsg += "\r\nThe last time I asked him what\'s up he replied: " + res.message;
          }
          return _this.askUserForStatus(message.user, statusMsg);
        };
      })(this));
      return;
    }
    if (this.isUserCommentAllowed(message.user)) {
      this.emit('feedbackMessage', message);
      this.disallowUserComment(message.user);
      this.askUserForStatus(message.user, 'Thanks, my friend. I really appreciate your openness.');
      return;
    }
    return this.mongo.getLatestUserTimestampForProperty('feedback', message.user).then((function(_this) {
      return function(res) {
        if (res && !timeHelper.hasTimestampExpired(20, res)) {
          _this.askUserForStatus(message.user, 'Oops, looks like I\'ve already received some feedback from you in the last 20 hours.');
          return;
        }
        if (!InputHelper.isValidStatus(message.text)) {
          _this.askUserForStatus(message.user, 'Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 0 and 9');
          return;
        }
        if (parseInt(message.text) < 5) {
          _this.askUserForStatus(message.user, 'Feel free to share with me what\'s wrong. I will treat it with confidence');
          _this.allowUserComment(message.user);
          _this.emit('feedback', message);
          return;
        }
        _this.emit('feedback', message);
        return _this.askUserForStatus(message.user, 'Thanks a lot, buddy! Keep up the good work!');
      };
    })(this));
  };

  SlackClient.prototype.askUserForStatus = function(userId, message) {
    var user;
    user = this.getUser(userId);
    message = message || ("Hey " + user.name + ", how are you doing today? Please reply with a number between 0 and 9. I'll keep track of everything for you.");
    if ((__indexOf.call(this.channels, userId) >= 0)) {
      return this.slack.postMessage(this.channels[res].channel.id, message, function() {});
    }
    return this.slack.openDM(userId, (function(_this) {
      return function(res) {
        _this.channels[userId] = res;
        return _this.slack.postMessage(res.channel.id, message, function() {});
      };
    })(this));
  };

  return SlackClient;

})(EventEmitter);

module.exports = SlackClient;
