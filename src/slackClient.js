var Slack, SlackClient;

Slack = require('./client');

SlackClient = (function() {
  function SlackClient() {
    this.token = '***REMOVED***';
    this.autoReconnect = true;
    this.autoMark = true;
  }

  SlackClient.prototype.connect = function() {
    return console.log('trying to connect...');
  };

  return SlackClient;

})();

module.exports = SlackClient;
