# needed in order to do string replacement
String.prototype.format = ->
  args = arguments
  return this.replace /{(\d+)}/g, (match, number) ->
    return if typeof args[number] isnt 'undefined' then args[number] else match

OskarTexts =
  statusText:
    '1': 'pretty bad'
    '2': 'a bit down'
    '3': 'alright'
    '4': 'really good'
    '5': 'awesome'

  introduction: "Hey there {0}, let me quickly introduce myself.\nMy name is Oskar, I'm your new happiness coach on Slack. I'm not going to bother you a lot, but every once in a while, I'm gonna ask how you feel, ok?\nLet me know when you're ready! Ah, and if you want to know a little bit more about me and what I do, check out the <http://oskar.herokuapp.com/faq|Oskar FAQ> or simply send me a message with 'help' and I'll send you that link again."

  firstMessage: "Cool! I'm ready as well. From now on I'll ask you this simple question: 'How is it going?'\nYou can reply to it with a number between 1 and 5. OK? Let's give it a try, type a number between 1 and 5"

  firstMessageSuccess: "That was easy, wasn't it? Let me now tell you what each of these numbers mean:\n5) Awesome :heart_eyes_cat:\n4) Really good :smile:\n3) Alright :neutral_face:\n2) A bit down :pensive:\n1) Pretty bad :tired_face:\n'That's it for now. Next time I'm gonna ask you will be tomorrow when you're back online. Have a great day and see you soon!" # todo: is now afternoon or next day"

  firstMessageFailure: "Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 1 and 5"

  requestFeedback:
    random: [
      "Hey {0}, How is it going? Just reply with a number between 1 and 5.\n",
      "Good morning {0}! Hope you\'re well rested. What\'s your status for today on a scale from 1 to 5?\n",
      "Nice to see you, {0}, Wanna tell me how you feel? A number between 1 and 5 is enough. \n"
    ]
    selection: "5) Awesome :heart_eyes_cat:\n
                4) Really good :smile:\n
                3) Alright :neutral_face:\n
                2) A bit down :pensive:\n
                1) Pretty bad :tired_face:\n"
    options: [
      "Hey, didn't you see my last message? It'll only take a second of your time to tell me how you're doing ;)"
      "Hellooooo, what's up? Do you want to ignore me? Just give me a number between 1 and 5 and I'll not bother you any longer."
    ]

  faq: "Looks like you need some help. Here's the link to the <http://oskar.herokuapp.com/faq|Oskar FAQ>"

  revealChannelStatus:
    status: "{0} is feeling *{1}*"
    message: " ({0})"

  revealUserStatus:
    error: "Oh, it looks like I haven\'t heard from {0} for a while. Sorry!"
    status: "{0} is feeling *{1}* on a scale from 1 to 5."
    message: "\r\nThe last time I asked him what\'s up he replied: {0}"

  newUserFeedback: "Hey, I just received some feedback from one of your colleagues:\n{0} is feeling *{1}* ({2})"

  alreadySubmitted: [
    "Oops, looks like I\'ve already received some feedback from you in the last 4 hours.",
    "You already told me how you feel in the last 4 hours, don\'t you remember?",
    "I know you love those number games, but let\'s wait a bit before we play again!"
  ]

  invalidInput: [
    "Oh it looks like you want to tell me how you feel, but unfortunately I only understand numbers between 1 and 5",
    "Sorry my friend, but as long as I\'m in beta, I only understand numbers between 1 and 5.",
    "I\'d really love to understand what you\'re saying, but for now, let\'s stick to numbers between 1 and 5."
  ]

  lowFeedback: [
    "Feel free to share with me what\'s wrong. I will treat it with confidence",
    "Aww no :( I\'m also not doing very well today. Too little sleep. What\'s up with you?",
    "No worries, my friend! You will already feel a bit better when you tell me what\'s on your mind?"
  ]

  highFeedback: [
    "Great to hear that. Wanna share with me what makes you feel so good?",
    "Woohoo, looks like you\'re on fire today. Wanna tell me what makes you feel so excited?",
    "Fantastic. I\'m sure you\'re gonna complete all your tasks today. What made you feel so awesome today?"
  ]

    # feedback already received
  feedbackReceived: [
    "Thanks a lot, buddy! Keep up the good work!",
    "You\'re a champion. Thanks for the input and have a great day!",
    "That\'s really helpful. I wish you good luck with everything today!"
  ]

    # feedback received
  feedbackMessageReceived: [
    "Thanks, my friend. I really appreciate your openness.",
    "That\'s the kind of feedback I wanted to hear. Much appreciated",
    "That\'s really helpful. I wish you good luck with everything today!"
  ]

module.exports = OskarTexts