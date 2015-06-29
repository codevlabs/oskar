# Oskar - the Slack satisfaction coach

[![Build Status](https://magnum.travis-ci.com/wearehanno/oskar.svg?token=LdpAvGamR6pf17d1ehyb&branch=master)](https://magnum.travis-ci.com/wearehanno/oskar)

## Description

Oskar is a Slackbot that tracks satisfaction of your team members. Every day it asks people for their current mood. This metric is stored in a database and tracked over time, allowing the team to understand which members are struggling or doing extremely well.

Everyone on your team can ask Oskar for another team member's or the entire team's current status. It is not meant to be a way of comparing people but to surface issues, unblock each other and eliminate isolation (especially in remote teams).

## How to

Oskar automatically asks you two times a day how you're doing. You can reply to him with a number between 1 to 5, and he will then ask you for feedback to know what's the trigger for your current low or high.

All data is collected in a database and made visible via the dashboard, which can be found at the URL:
`http://your-oskar-url.com/dashboard` (find instruction on how to set a username/password below)

You can send the following commands directly to Oskar:
- `How is @member?` - Tells you how a specific team member is doing
- `How is @channel?` - Returns the current status for the whole group

## Tech stack

- Oskar is build on node.js with express.js.
- It is written in CoffeeScript (such as the node slack client it uses)
- It uses a MongoDB database to store team member feedback
- It (usually, but not only) runs on Heroku

## Configuring Oskar

Oskar's configuration file can be found inside the `config` directoy. There you should:
- define the url to a fresh and empty MongoDB database (to create a mongoDB on Heroku for example, go to https://elements.heroku.com/addons/mongolab)
- insert a Slack bot token that belongs to your team (you can create a new Slackbot here: https://yourteam.slack.com/services/new/bot)

Additionally you can
- disable **channels** that Oskar is part of (you should disable the default channel that Slack added)
- disable **users** if you want specific people on your team to receive Oskar messages a tall

See the following instructions if you set up Oskar for the first time.

## Setting up Oskar on Heroku

If you're familiar with Heroku, you can quickly get Oskar up and running there with a few commands.

1. If you haven't already, install a Heroku account (http://heroku.com) and download the Heroku toolbelt. Instructions on how to get started with node.js on Heroku can be found here: https://devcenter.heroku.com/articles/getting-started-with-nodejs#introduction

2. Once you've created your Heroku account and downloaded the toolbelt, clone the Oskar repository into your directory of choice by running `git clone git@github.com:wearehanno/oskar.git`.

3. Now create a new Heroku instance for this repository by running `heroku create`.

4. Before we push our repository and run our app, we need to set up a MongoDB database. Run `heroku addons:create mongolab` to create a basic mongoDB. The basic plan of the extension is free but it will require you to enter your credit card details.

5. Get the remote URL for your new database by running `heroku config | grep MONGOLAB_URI` and add this URL to the `mongo.url` part of the Oskar config file which you can find at `config/default.json`.

6. Now push the repository to your new Heroku app by running `git push heroku master` and `heroku ps:scale web=1` to ensure that at least one instance of it is running.

7. Visit the URL that Heroku returned or run `heroku open` to see the Oskar website. Go to `http://your-oskar-url.com/dashboard` to see your team's statistics. It will ask you for a username and password that can be defined in your config file under `auth`

## Setting up a local dev environment / Contributing

- Download and install nodeJS: https://nodejs.org/download/
- Install Grunt: `npm install grunt -g`
- Run `npm install` to install dependencies
- Start the static part of the server without running Oskar: `grunt static`
- You can reach the site at http://localhost:5000
- Compile & watch Sass files: `grunt watch`

## Unit tests

Oskar is being tested with [Mocha](http://mochajs.org/) and [should.js](https://github.com/tj/should.js/)

Run the unit tests for all modules be running `npm test`.
To run only a single unit test call the test file explicitly, such as `npm test test/inputHelper.coffee`

For the mongo tests to pass, you'll have to run a mongo database under `mongodb://localhost:27017`. If you have mongo installed, just run `mongod` on the command line.
See here for more instructions: http://docs.mongodb.org/manual/installation/

You can modify the test parameters in `package.json` under `scripts.test`.