class StringHelper

  @convertStatusToText: (status) ->

    switch status
      when '1' then return 'pretty bad'
      when '2' then return 'a bit down'
      when '3' then return 'alright'
      when '4' then return 'really good'
      else return 'awesome'

module.exports = StringHelper