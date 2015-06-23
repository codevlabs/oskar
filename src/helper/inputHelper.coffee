class InputHelper

  @isValidStatus: (status) ->
    numberPattern = /^[1-5]$/
    if !status.match numberPattern
      return false
    return true

  @isAskingForUserStatus: (input) ->
    userPattern = /^How is <[@|\!](\w+)>\s?\??$/i
    response = input.match userPattern
    if response?
      return response[1]
    return null

  @isAskingForHelp: (input) ->
    messagePattern = /help/i
    if input.match messagePattern
      return true
    return false

module.exports = InputHelper