# Description:
#   lunch script
#
# - TODO: respect deadline
# - TODO: automatically close poll
# - TODO: only accept one vote and delete all other votes
#

module.exports = (robot) ->

  places = robot.brain.get('lunch_places') or []
  deadline = null
  orders = []


  robot.hear /vote (.*)/i, (res) ->
    name = res.match[1]
    place = findPlace(name)
    if (place)
      user = res.message.user.name
      if (user not in place.voters)
        place.voters.push user
        res.reply "vote counted. #{name} has now " + place.voters.length + " votes"
      else
        res.reply "Don't mess with me, I already counted your vote"
    else
      res.reply "I don't know anything about #{name}"


  # TODO: votes: shows a list of votes


  robot.hear /list lunchplaces/i, (res) ->
    output = listPlaces()
    res.reply output


  robot.hear /lunchplace add (.*)/i, (res) ->
    newplace = {
      name: res.match[1],
      visits: 0,
      lovers: [],
      haters: [],
      dateLastVist: null,
      voters: []
    }
    if (newplace in places)
      res.reply (newplace + " is already in our list" )
    else
      places.push newplace
      robot.brain.set 'lunch_places', places
      res.reply "I've added " + newplace.name + " to our list"


  robot.hear /I am hungry/i, (res) ->
    if (deadline)
      res.reply "voting has already begun. deadline is: " + deadline.toLocaleTimeString()
      res.reply "Cast your vote by saying 'vote <place name>'"
      return
    res.reply "Ok, let's make plans"
    res.reply "I know " + places.length + " places where we could go"
    if (places.length > 0)
      res.reply "What about:"
      places.sort (a, b) -> sortBy('visits', a, b)
      res.reply places[0].name # TODO: add reasoning
      deadline = new Date
      deadline = deadline.setMinutes(deadline.getMinutes() + 15)
      deadline = new Date(deadline)
      res.reply "Let's vote. Poll closing at " + deadline.toLocaleTimeString()
    else
      res.reply "Let's tell me about some places you like. 'lunchplace add <name>'"


  robot.hear /I hate (.*)/i, (res) ->
    name = res.match[1]
    for place in places
      if (place.name == name)
        hater = res.message.user.name
        if (hater not in place.haters)
          place.haters.push hater
          for index, elem in place.lovers
            place.lovers.splice index, 1 if elem is hater
        res.reply placeStatus place


  robot.hear /I love (.*)/i, (res) ->
    name = res.match[1]
    for place in places
      if (place.name == name)
        lover = res.message.user.name
        if (lover not in place.lovers)
          place.lovers.push lover
        for index, elem in place.haters
          place.haters.splice index, 1 if elem is lover
        res.reply placeStatus place


  robot.hear /What is the score of (.*)/i, (res) ->
    name = res.match[1]
    place = findPlace(name)
    res.reply placeScore(place)
    res.reply placeStatus place

# Order with a price
  robot.hear /I order (.*) *: *([0-9]*,+[0-9]*)/i, (res) ->
    name = res.message.user.name
    item = res.match[1]
    price = res.match[2]
    res.reply "foo"
    order = {
      name: name,
      item: item,
      price: price
    }
    orders.push order
    res.reply printOrder order

# Oder with no price
  robot.hear /I order (.*)/i, (res) ->
    name = res.message.user.name
    item = res.match[1]
    if item.indexOf(':') > 0
      return
    res.reply "bar"
    order = {
      name: name,
      item: item,
      price: 0
    }
    orders.push order
    res.reply printOrder order

# list all orders
  robot.hear /list orders/i, (res) ->
    res.reply " --- ORDERS --- "
    for order in orders
      res.reply printOrder order



# Heler Methods #

  one_day = 1000 * 60 * 60 * 24

  printOrder = (order) ->
    if order.price
      return "[" + order.name + "] " + order.item + " (" + order.price + "€)"
    else
      return "[" + order.name + "] " + order.item + " "

  listPlaces = () ->
    result = "our places:\n"
    for place, index in places
      result += "#{index}: #{place.name} (#{place.haters.length}x\u2620, #{place.lovers.length}x\u2661)"
      for voter in place.voters
        result += '#'
      result += '\n'
    return result


  findPlace = (name) ->
    for place in places
      if place.name == name then return place
    return null


  placeStatus = (place) ->
    return place.haters.length + " people hate and " + place.lovers.length + " people love " + place.name


  placeScore = (place) ->
    score = 1
    score = score + (place.lovers.length - place.haters.length)
    score = score + daysNotBeenThere(place)
    score = score + place.voters.length
    return score


  daysNotBeenThere = (place) ->
    if (place.dateLastVist)
      millis = (new Date.getTime - place.dateLastVist.getTime)
      return (millis / one_day)
    else
      return 10


  sortBy = (key, a, b, r) ->
    r = if r then 1 else -1
    return -1 * r if a[key] > b[key]
    return +1 * r if a[key] < b[key]
    return 0
