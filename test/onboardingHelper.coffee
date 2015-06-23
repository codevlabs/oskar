###################################################################
# Setup the tests
###################################################################
should = require 'should'
sinon = require 'sinon'
whenLib = require 'when'

MongoClient = require '../src/modules/mongoClient'
OnboardingHelper = require '../src/helper/onboardingHelper'

###################################################################
# Onboarding Helper
###################################################################

mongo = new MongoClient()
setOnboardingStatusStub = sinon.stub mongo, 'setOnboardingStatus'
getOnboardingStatusStub = sinon.stub mongo, 'getOnboardingStatus'
saveUserFeedbackStub = sinon.stub mongo, 'saveUserFeedback'
getOnboardingStatusStub.withArgs('user1').returns(whenLib 1)
getOnboardingStatusStub.withArgs('user2').returns(whenLib 0)
getOnboardingStatusStub.withArgs('user3').returns(whenLib 3)

userIds = ['user1', 'user2', 'user3']

onboardingHelper = new OnboardingHelper(mongo, userIds)
onboardingHelper.retainOnboardingStatusForUsers(userIds)

describe 'OnboardingHelper', ->

  it 'should save the initial onboarding status of each user', ->

    userId = 'user1'

    status = onboardingHelper.getOnboardingStatus(userId)
    status.should.be.equal(1)

    userId = 'user2'

    status = onboardingHelper.getOnboardingStatus(userId)
    status.should.be.equal(0)

  it 'should tell if the user has been onboarded', ->

    userId = 'user1'

    isOnboarded = onboardingHelper.isOnboarded(userId)
    isOnboarded.should.be.equal(false)

    userId = 'user3'

    isOnboarded = onboardingHelper.isOnboarded(userId)
    isOnboarded.should.be.equal(true)

  it 'should get the onboarding status that i have set', ->

    onboardingHelper.setOnboardingStatus('user1', 2)
    isOnboarded = onboardingHelper.getOnboardingStatus('user1')
    isOnboarded.should.be.equal 2

  it 'should emit an introduction event when welcome is called and user onboarding status is 0', ->

    spy = sinon.spy()

    onboardingHelper.on 'message', spy
    onboardingHelper.welcome('user2')

    spy.called.should.be.equal true
    spy.args[0][0].type.should.be.equal 'introduction'

  it 'should emit a firstMessage event when advance is called and user onboarding status is 1', ->

    spy = sinon.spy()

    onboardingHelper.on 'message', spy
    onboardingHelper.setOnboardingStatus('user1', 1)
    onboardingHelper.advance('user1')

    spy.called.should.be.equal true
    spy.args[0][0].type.should.be.equal 'firstMessage'

  it 'should emit a firstMessageFailure event when advance is called and user onboarding status is 2 and message is not valid', ->

    spy = sinon.spy()

    onboardingHelper.on 'message', spy
    onboardingHelper.setOnboardingStatus('user1', 2)
    onboardingHelper.advance('user1', null)

    spy.called.should.be.equal true
    spy.args[0][0].type.should.be.equal 'firstMessageFailure'

  it 'should emit a firstMessageSuccess event when advance is called and user onboarding status is 2 and message is valid', ->

    spy = sinon.spy()

    onboardingHelper.on 'message', spy
    onboardingHelper.setOnboardingStatus('user1', 2)
    onboardingHelper.advance('user1', '1')
    spy.args[0][0].type.should.be.equal 'firstMessageSuccess'

    spy.called.should.be.equal true

  it 'should save status in mongo when onboarding completed', ->

    saveUserFeedbackStub.reset()

    onboardingHelper.setOnboardingStatus('user1', 2)
    onboardingHelper.advance('user1', '4')

    setOnboardingStatusStub.called.should.be.equal true
    setOnboardingStatusStub.args[0][0].should.be.equal 'user1'
    setOnboardingStatusStub.args[0][1].should.be.equal 3

    saveUserFeedbackStub.called.should.be.equal true
    saveUserFeedbackStub.args[0][0].should.be.equal 'user1'
    saveUserFeedbackStub.args[0][1].should.be.equal '4'