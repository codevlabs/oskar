Mongo = require('mongodb').MongoClient
Promise = require('promise');

class MongoClient

	@db = null
	@collection = null

	constructor: (url) ->
		if url
			@url = url
		else
			@url = '***REMOVED***'

	connect: () ->

		promise = new Promise (resolve, reject) =>

			# Use connect method to connect to the Mongo Server
			Mongo.connect @url, (err, db) =>

				if (err is null)
					@collection = db.collection('users')
					resolve(db)

				else
					db.close()
					reject()

	userExists: (userId) ->

		promise = new Promise (resolve, reject) =>

			@collection.find({ id: userId }).toArray (err, docs) =>
				resolve(docs.length > 0)

	saveUser: (user) ->

		promise = new Promise (resolve, reject) =>

			@userExists(user.id).then (res) =>

				if res is true
					return resolve(user)

				userObj =
					id: user.id
					name: user.name
					real_name: user.real_name
					tz: user.tz
					tz_offset: user.tz_offset
					image_48: user.profile.image_48

				@collection.insert userObj, (err, result) ->
					if (err is null)
						resolve(result)
					else
						reject()

	saveUserStatus: (userId, status) ->

		promise = new Promise (resolve, reject) =>

			user =
				id: userId

			update =
				$push:
					activity:
						status: status
						timestamp: Date.now()

			@collection.update user, update, (err, result) =>
				if (err is null)
					resolve(result)
				else
					reject()

	saveUserFeedback: (userId, feedback) ->

		promise = new Promise (resolve, reject) =>

			user =
				id: userId

			update =
				$push:
					feedback:
						status: feedback
						timestamp: Date.now()

			@collection.update user, update, (err, result) =>
				if (err is null)
					resolve(result)
				else
					reject()

	saveUserFeedbackMessage: (userId, feedbackMessage) ->

		promise = new Promise (resolve, reject) =>

			@getLatestUserTimestampForProperty('feedback', userId).then (res) =>

				find =
					id: userId
					feedback:
						$elemMatch:
							timestamp: res

				update =
					$set:
						'feedback.$.message': feedbackMessage

				@collection.update find, update, (err, result) =>
					if (err is null)
						resolve(result)
					else
						reject()

	getLatestUserFeedback: (userId) ->

		promise = new Promise (resolve, reject) =>

			@collection.find({ id: userId }).toArray (err, docs) =>

				if (err is not null)
					return reject()

				if (docs.length is 0)
					return resolve(false)

				if !docs[0].hasOwnProperty 'feedback'
					return resolve(null)

				timestamp = 0
				feedback = null

				# get latest message according to timestamp
				for obj in docs[0].feedback
					if obj.timestamp > timestamp
						timestamp = obj.timestamp
						feedback = obj

				resolve(feedback)

	getAllUserFeedback: (userIds) ->

		promise = new Promise (resolve, reject) =>

			@collection.find({ id: { $in: userIds } }).toArray (err, docs) =>

				if (err isnt null)
					reject()

				users = docs.map (elem) ->

					feedback = null

					if elem.feedback
						elem.feedback.sort (a, b) ->
							a.timestamp > b.timestamp

						feedback = elem.feedback.pop()

					res =
						id: elem.id
						feedback: feedback

				console.log users
				console.log resolve

				resolve(users)


	getLatestUserTimestampForProperty: (property, userId) ->

		promise = new Promise (resolve, reject) =>

			@collection.find({ id: userId }).toArray (err, docs) =>

				if (err is not null)
					return reject()

				if (docs.length is 0)
					return resolve(false)

				if !docs[0].hasOwnProperty property
					return resolve(null)

				docs[0][property].sort (a, b) ->
					a.timestamp > b.timestamp

				resolve docs[0][property].pop().timestamp

module.exports = MongoClient