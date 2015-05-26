class InputHelper

  @isValidStatus: (status) ->
    numberPattern = /^[0-9]$/
    if !status.match numberPattern
      return false
    return true

  @isAskingForUserStatus: (input) ->
    userPattern = /^How is <[@|\!](\w+)>\s?\??$/i
    response = input.match userPattern
    if response?
      return response[1]
    return null

module.exports = InputHelper