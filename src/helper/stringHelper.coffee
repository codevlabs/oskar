class StringHelper

  @convertStatusToText: (status) ->

    switch status
      when '1' then return 'really shit'
      when '2' then return 'a bit down'
      when '3' then return 'somewhere in between'
      when '4' then return 'alright'
      else return 'awesome'

module.exports = StringHelper