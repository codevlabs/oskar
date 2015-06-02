var TimeHelper;

TimeHelper = (function() {
  function TimeHelper() {}

  TimeHelper.hasTimestampExpired = function(intervalInHours, timestamp) {
    var intervalInSeconds, nowMinusInterval;
    intervalInSeconds = intervalInHours * 3600 * 1000;
    nowMinusInterval = Date.now() - intervalInSeconds;
    if (timestamp < nowMinusInterval) {
      return true;
    } else {
      return false;
    }
  };

  TimeHelper.isWeekend = function(timestamp, diff) {
    var date;
    date = this.getLocalDate(timestamp, diff);
    return date.getDay() === (6 || 7);
  };

  TimeHelper.getUTCDate = function() {
    var now, now_utc;
    now = new Date();
    return now_utc = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds());
  };

  TimeHelper.getLocalDate = function(timestamp, diff) {
    var date, newHours;
    if (timestamp === null) {
      date = this.getUTCDate();
    } else {
      date = new Date(timestamp);
    }
    newHours = date.getUTCHours() + diff;
    return new Date(date.setUTCHours(newHours));
  };

  TimeHelper.isDateInsideInterval = function(min, max, date) {
    var _ref;
    return (min <= (_ref = date.getUTCHours()) && _ref < max);
  };

  return TimeHelper;

})();

module.exports = TimeHelper;
