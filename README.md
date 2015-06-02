# Oskar - the Slack satisfaction coach

## Description

Oskar is a Slackbot that tracks satisfaction of your team members. Every day it asks people for their current mood. This metric is stored in a database and tracked over time, allowing the team to understand which members are struggling or doing extremely well.

Everyone can ask Oskar for another team member's status, or a list of all team member's current status, and what they struggle with.

It is not meant to be a way of comparing people but to surface issues, unblock each other and eliminate isolation (especially in remote teams).

## How to

Oskar automatically asks people within an interval of 24 hours how they are doing. People can reply to question message with a number between 0-9. If the feedback is less than 5 Oskar will ask if the person is having any issues, and saves the reply to the database.

Team members can use the following commands:
- `How is @member?` - Tells you how a specific team member is doing
- `How is @channel?` - Returns the current status for the whole group

In order to disable specific channels or users, go to `src/slackClient.coffee` and add them to the variables `@disabledUsers` and `@disabledChannels`

## Tech stack

- Oskar is build on node.js with express.js.
- Such as the node slack client (and because of it), it is written in CoffeeScript.
- It uses a MongoDB database to store team member feedback
- It runs on Heroku (https://polar-temple-7947.herokuapp.com/)

## Installation

- To install all necessary dependencies, use `npm install`
- In `src/mongoClient.coffee`, replace the url in the constructor with the URL of your mongoDB (to create a mongoDB on Heroku, go to https://elements.heroku.com/addons/mongolab)
- In `src/slackClient.coffee`, replace the @token variable in the constructur with the one of your Slackbot (to create a slack bot go to https://yourteam.slack.com/services/new/bot)
- Run `grunt watch` to make changes to the code, as it will compile stuff from CoffeeScript to JS.

## Unit tests

Oskar is being tested with [Mocha](http://mochajs.org/) and [should.js](https://github.com/tj/should.js/)

Run the unit tests for all modules be running `npm test`.
To run only a single unit test call the test file explicitly, such as `npm test test/inputHelper.coffee`

For the mongo tests to pass, you'll have to run a mongo database under `mongodb://localhost:27017`. If you have mongo installed, just run `mongod` on the command line.
See here for more instructions: http://docs.mongodb.org/manual/installation/

You can modify the test parameters in `package.json` under `scripts.test`.