var MongoClient, Oscar, SlackClient, TimeHelper, express, oscar,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

express = require('express');

MongoClient = require('./mongoClient');

SlackClient = require('./slackClient');

TimeHelper = require('./helper/timeHelper');

Oscar = (function() {
  function Oscar() {
    this.presenceHandler = __bind(this.presenceHandler, this);
    this.app = express();
    this.app.set('view engine', 'ejs');
    this.app.set('views', 'src/views/');
    this.app.use('/public', express["static"](__dirname + '/public'));
    this.mongo = new MongoClient();
    this.mongo.connect();
    this.slack = new SlackClient(this.mongo);
    this.slack.connect();
    this.setupEvents();
    this.setupRoutes();
    setInterval(this.checkForUserStatus, 3600 * 1000);
  }

  Oscar.prototype.setupEvents = function() {
    this.slack.on('feedback', function(data) {
      return this.mongo.saveUserFeedback(data.user, data.text);
    });
    this.slack.on('feedbackMessage', function(data) {
      return this.mongo.saveUserFeedbackMessage(data.user, data.text);
    });
    return this.slack.on('presence', this.presenceHandler);
  };

  Oscar.prototype.setupRoutes = function() {
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

  Oscar.prototype.presenceHandler = function(data) {
    var user;
    user = this.slack.getUser(data.userId);
    return this.mongo.saveUser(user).then(function(res) {
      return this.mongo.getLatestUserTimestampForProperty('feedback', data.userId).then(function(res) {
        if (res === false) {
          return;
        }
        this.mongo.saveUserStatus(data.userId, data.status);
        if (data.status !== 'active') {
          return;
        }
        if (TimeHelper.isWeekend()) {
          return;
        }
        if (res === null || TimeHelper.hasTimestampExpired(20, res)) {
          return this.slack.askUserForStatus(data.userId);
        }
      });
    });
  };

  Oscar.prototype.checkForUserStatus = function() {
    var userIds;
    userIds = this.slack.getUserIds();
    return userIds.forEach(function(userId) {
      var data;
      data = {
        userId: userId,
        status: 'triggered'
      };
      return this.slack.emit('presence', data);
    });
  };

  return Oscar;

})();

oscar = new Oscar();
