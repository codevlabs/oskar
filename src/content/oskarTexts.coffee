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
      "Hey {0}, How's everything going? Hit me with a number from 1-5, and I'll share it with the rest of the team.\n",
      "Hello, me again! Just checking in to see how you're feeling. Want to share?\n",
      "Nice to see you, {0}, Wanna tell me how you feel? A number between 1 and 5 is enough. \n"
    ]
    selection: "(5) :heart_eyes_cat: Awesome\n
                (4) :smile: Really good\n
                (3) :neutral_face: Alright\n
                (2) :pensive: A bit down\n
                (1) :tired_face: Pretty bad\n"
    options: [
      "Hey, didn't you see my last message? It'll only take a second of your time to tell me how you're doing :wink:"
      "Hellooooo, what's up? Do you want to ignore me? Just give me a number between 1 and 5 and I'll not bother you any longer."
    ]

  faq: "Looks like you need some help. Here's the link to the <http://oskar.herokuapp.com/faq|Oskar FAQ>"

  revealChannelStatus:
    status: "{0} is feeling *{1}*"
    message: " ({0})"

  revealUserStatus:
    error: "Hmm, it looks like I haven't heard from {0} for a while. You might want to ping them directly."
    status: "Looks like {0} is feeling *{1}/5* right now."
    message: "\r\nThe last time I asked what's up, they told me: {0}"

  newUserFeedback: "Hey, I thought you might want to know that *{0}* is feeling *{1}/5*: '{2}'"

  alreadySubmitted: [
    "Oops, looks like I\'ve already received some feedback from you in the last 4 hours.",
    "Oh, hey there! I actually have some feedback from you already, in the last 4 hours. Let's leave it a little longer before we catch up :smile:",
    "Easy, tiger! I know you love those number games, but let\'s wait a bit before we play again! I'll ping you in a few hours to see how you're doing."
  ]

  invalidInput: [
    "Oh! I'm not sure what you meant, there: I only understand numbers between 1 and 5. Do you mind phrasing that a little differently?",
    "Oh! I'm not sure what you meant, there: I only understand numbers between 1 and 5. Do you mind phrasing that a little differently?",
    "I\'d really love to understand what you\'re saying, but until I become a little more educated, I'll need you to stick to using numbers between 1 and 5 to tell me how you feel."
  ]

  lowFeedback: [
    "That sucks. I was really hoping you'd be feeling a little better than that. Is there anything I should know?",
    "Oh dear :worried: I\'m having a rough day over here too... I think I didn't get enough sleep last night. Wanna tell me a little more? Perhaps one of your teammates will be able to help out.",
    "No worries, my friend! You will already feel a bit better when you tell me what\'s on your mind?"
  ]

  averageFeedback: [
    "OK. Go get em :tiger: ..if you've got something you want to share feel free. If not have a grrreat day!",
    "OK. Go get em :tiger: ..if you've got something you want to share feel free. If not have a grrreat day!",
    "OK. Go get em :tiger: ..if you've got something you want to share feel free. If not have a grrreat day!"
  ]

  highFeedback: [
    ":trophy: Winning! It\'s so great to hear that. Wanna tell me why things are going so well?",
    ":thumbsup: looks like you\'re on :fire: today. Is there anything you\'d like to share with the team?",
    "There's nothing I like more than great feedback! :clap::skin-tone-4: What\'s made you feel so awesome today?"
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
