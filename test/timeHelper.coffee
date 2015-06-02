###################################################################
# Setup the tests
###################################################################
should = require 'should'

# Client = require '../src/client'
timeHelper = require '../src/helper/timeHelper'

###################################################################
# Helper
###################################################################

describe 'TimeHelper', ->

  before ->

  it 'should return false if timestamp is not older than 24 hours', ->
    timestamp = Date.now()
    hasExpired = timeHelper.hasTimestampExpired(timestamp)
    hasExpired.should.be.equal(false)

  it 'should return true if timestamp is older than 24 hours', ->
    timestamp = Date.now() - (86401 * 1000);
    hasExpired = timeHelper.hasTimestampExpired(24, timestamp)
    hasExpired.should.be.equal(true)

  it 'should return true when date is a day of the weekend', ->
    timestamp = Date.parse('Sat, 02 May 2015 15:00:00 GMT');
    isWeekend = timeHelper.isWeekend(timestamp, 0)
    isWeekend.should.be.equal(true)

  it 'should return false when date is not a day of the weekend', ->
    timestamp = Date.parse('Fri, 01 May 2015 15:00:00 GMT');
    isWeekend = timeHelper.isWeekend(timestamp)
    isWeekend.should.be.equal(false)

  it 'should return true when date is already a day of the weekend in a specific timezone', ->
    timestamp = Date.parse('Fri, 22 May 2015 20:00:00 GMT')
    isWeekend = timeHelper.isWeekend(timestamp, 8)
    isWeekend.should.be.equal(true)

  it 'should return false when date is not anymore a day of the weekend in a specific timezone', ->
    timestamp = Date.parse('Sun, 24 May 2015 20:00:00 GMT')
    isWeekend = timeHelper.isWeekend(timestamp, 8)
    isWeekend.should.be.equal(false)

  it 'should return false when date is not yet a day of the weekend in a specific timezone', ->
    timestamp = Date.parse('Sat, 23 May 2015 02:00:00 GMT')
    isWeekend = timeHelper.isWeekend(timestamp, -8)
    isWeekend.should.be.equal(false)

  it 'should return the current local time for a UTC date plus timezone difference', ->
    timestamp = Date.parse('Fri, 22 May 2015 15:00:00 GMT')
    diff = 8
    localTime = timeHelper.getLocalDate(timestamp, diff)
    localTime.getUTCHours().should.be.equal(23)

    timestamp = Date.parse('Thu, 21 May 2015 21:00:00 GMT')
    diff = -8
    localTime = timeHelper.getLocalDate(timestamp, diff)
    localTime.getUTCHours().should.be.equal(13)

    timestamp = Date.parse('Thu, 21 May 2015 00:00:00 GMT')
    diff = -3
    localTime = timeHelper.getLocalDate(timestamp, diff)
    localTime.getUTCHours().should.be.equal(21)

  it 'should return true if time falls between a specific interval', ->
    intervalMin = 6
    intervalMax = 10
    date = new Date('Wed, 20 May 2015 08:30:00 GMT')
    isInsideInterval = timeHelper.isDateInsideInterval(intervalMin, intervalMax, date)
    isInsideInterval.should.be.equal(true)

    intervalMin = 3
    intervalMax = 4
    date = new Date('Wed, 20 May 2015 03:59:59 GMT')
    isInsideInterval = timeHelper.isDateInsideInterval(intervalMin, intervalMax, date)
    isInsideInterval.should.be.equal(true)

  it 'should return false if time does not fall inside a specific interval', ->
    intervalMin = 11
    intervalMax = 12
    date = new Date('Tue, 19 May 2015 10:59:00 GMT+02:00')
    isInsideInterval = timeHelper.isDateInsideInterval(intervalMin, intervalMax, date)
    isInsideInterval.should.be.equal(false)

    intervalMin = 11
    intervalMax = 12
    date = new Date('Tue, 19 May 2015 12:01:00 GMT+02:00')
    isInsideInterval = timeHelper.isDateInsideInterval(intervalMin, intervalMax, date)
    isInsideInterval.should.be.equal(false)