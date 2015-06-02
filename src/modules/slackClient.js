var EventEmitter, InputHelper, Promise, Slack, SlackClient, mongoClient, timeHelper,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Slack = require('../vendor/client');

mongoClient = require('../modules/mongoClient');

InputHelper = require('../helper/inputHelper');

timeHelper = require('../helper/timeHelper');

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
    this.messageHandler = __bind(this.messageHandler, this);
    this.presenceChangeHandler = __bind(this.presenceChangeHandler, this);
    this.token = '***REMOVED***';
    this.autoReconnect = true;
    this.autoMark = true;
    this.users = [];
    this.channels = [];
    this.disabledUsers = ['***REMOVED***', '***REMOVED***', 'USLACKBOT'];
    this.disabledChannels = ['***REMOVED***'];
    if (mongo != null) {
      this.mongo = mongo;
    }
  }

  SlackClient.prototype.connect = function() {
    var promise;
    this.slack = new Slack(this.token, this.autoReconnect, this.autoMark);
    this.slack.on('presenceChange', this.presenceChangeHandler);
    this.slack.on('message', this.messageHandler);
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
    users = this.users.filter((function(_this) {
      return function(user) {
        return _this.disabledUsers.indexOf(user.id) === -1;
      };
    })(this));
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
    if (this.disabledUsers.indexOf(userId) !== -1) {
      return null;
    }
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

  SlackClient.prototype.presenceChangeHandler = function(data, presence) {
    data = {
      userId: data.id,
      status: presence
    };
    return this.emit('presence', data);
  };

  SlackClient.prototype.messageHandler = function(message) {
    if ((this.getUser(message.user)) === void 0) {
      return false;
    }
    if (this.disabledChannels.indexOf(message.channel) !== -1) {
      return false;
    }
    message.type = 'input';
    return this.emit('message', message);
  };

  SlackClient.prototype.postMessage = function(userId, message) {
    if ((__indexOf.call(this.channels, userId) >= 0)) {
      return this.slack.postMessage(this.channels[userId].channel.id, message, function() {});
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
