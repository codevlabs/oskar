class TimeHelper

  @hasTimestampExpired: (intervalInHours, timestamp) ->
    intervalInSeconds = intervalInHours * 3600 * 1000
    nowMinusInterval = Date.now() - intervalInSeconds

    if (timestamp < nowMinusInterval)
      return true
    else
      return false

  @isWeekend: (timestamp, diff) ->
    date = @getLocalDate timestamp, diff
    return date.getDay() is (6 or 7)

  @getUTCDate: ->
    now = new Date();
    now_utc = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds())

  @getLocalDate: (timestamp, diff) ->
    if timestamp is null
      date = @getUTCDate()
    else
      date = new Date(timestamp)

    newHours = date.getUTCHours() + diff
    new Date(date.setUTCHours newHours)

  @isDateInsideInterval: (min, max, date) ->
    min <= date.getHours() < max

module.exports = TimeHelper