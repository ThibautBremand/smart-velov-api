fs      = require 'fs'
log     = require('./log')(module)
LA      = require 'look-alike'
request = require 'request'
_       = require 'underscore'
urllib  = require 'urllib-sync'

dirty = true
stations = {}
stationsTree = null # 2 dimensions for lat and lng

module.exports.supportedContracts = ['Lyon']
module.exports.necessaryProperties = [
  'number'
  'name'
  # 'address' may be empty
  'position' # lat + lng checked in missingProperty
  'banking'
  'bonus'
  'status'
  'contract_name'
  'bike_stands'
  'available_bike_stands'
  'available_bikes'
  'last_update'
]

# Aliases
supportedContracts = module.exports.supportedContracts
necessaryProperties = module.exports.necessaryProperties

module.exports.all = ->
  if dirty
    try
      fileData = fs.readFileSync './data/stations-data.json',
        encoding: 'utf-8'

      dirty = false
      stations = JSON.parse fileData

      # Replacing tree content
      stationsArray = []
      _.each stations, (infos, num) ->
        stationsArray.push lat: infos.position.lat, lng: infos.position.lng, number: infos.number
        return
      stationsTree = new LA stationsArray, attributes: ['lat','lng']

      log.info 'Loaded stations file successfully.'
    catch e
      stations = {}

  return stations

module.exports.missingProperty = missingProperty = (station) ->
  # Checking all necessary properties are there
  for p in necessaryProperties
    if station[p] == null || station[p] == undefined || station[p] == ""
      return p
  return 'position.lat' if not (   0 <= station.position.lat <=  90)
  return 'position.lng' if not (-180 <= station.position.lng <= 180)

  return false

module.exports.save = (stationsToAdd) ->
  stations = module.exports.all()

  for toAdd in stationsToAdd
    if not toAdd.contract_name in supportedContracts
      throw new Error 'Unsupported contract', supportedContracts

    # Getting the station or creating it if it doesn't already exists
    found = stations["#{toAdd.number}"] ? {}
    found.contract_name = toAdd.contract_name ? found.contract_name

    # Skipping toAdd in case the update time is older
    if found.last_update > toAdd.last_update
      missing = missingProperty found
      if missing
        throw new Error "Missing property #{missing}"
      continue

    found.last_update     = toAdd.last_update
    found.number          = toAdd.number          ? found.number
    found.name            = toAdd.name            ? found.name
    found.address         = toAdd.address         ? found.address
    found.position        = toAdd.position        ? (found.position ? {})
    found.position.lat    = toAdd.position.lat    ? found.position.lat
    found.position.lng    = toAdd.position.lng    ? found.position.lng
    found.banking         = toAdd.banking         ? found.banking
    found.bonus           = toAdd.bonus           ? found.bonus
    found.status          = toAdd.status          ? found.status
    found.bike_stands     = toAdd.bike_stands     ? found.bike_stands
    found.available_bike_stands =
        toAdd.available_bike_stands ? found.available_bike_stands
    found.available_bikes = toAdd.available_bikes ? found.available_bikes

    missing = missingProperty found
    if missing
      throw new Error "Missing property #{missing}"

    stations["#{toAdd.number}"] = found

  fs.writeFile './data/stations-data.json', JSON.stringify(stations), (err) ->
    throw err if err

    log.info 'Saved stations file successfully.'

    # Updates internal representations
    dirty = true
    stations = module.exports.all()

module.exports.update = (apiKey, callback) ->
  request 'https://api.jcdecaux.com/vls/v1/stations?contract=Lyon&apiKey=' +
  apiKey, (err, res, body) ->
    module.exports.save JSON.parse body
    callback err, res, stations if callback

getStation = (apiKey, number, callback) ->
  req = "https://api.jcdecaux.com/vls/v1/stations/#{number}?contract=Lyon&apiKey=#{apiKey}"
  request req, (err, res, body) ->
    if err
      callback err
    else
      callback null, JSON.parse body

module.exports.isTakeable = (apiKey, number, callback, options = {}) ->
  if not options.minBikes?
    options.minBikes = 2
  if not options.minStands?
    options.minStands = 2
  if not options.pref?
    options.pref = 'bikes'
  getStation apiKey, number, (err, station) ->
    if err
      callback err
    else
      if station.status != 'OPEN'
        callback "Station not opened"
      if options.pref == 'bikes'
        callback null, station.available_bikes >= options.minBikes
      else if options.pref == 'stands'
        callback null, station.available_bike_stands >= options.minStands
      else
        callback "Wrong value for preference parameter"

module.exports.nearest = (position, callback) ->
  stations = module.exports.all()

  if stationsTree == null
    err = 'Search tree not properly loaded'
    err.status = 500
    return callback err

  nearest = stationsTree.query lat: position.lat, lng: position.lng

  if 0 == nearest.length
    err = 'Could not found nearest station'
    err.status = 404
    return callback err

  callback null, stations["#{nearest[0].number}"]

# ATTENTION! This method doesn't work
module.exports.best = (apiKey, position, callback) ->
  stations = module.exports.all()

  if stationsTree == null
    err = 'Search tree not properly loaded'
    err.status = 500
    return callback err

  nearest = stationsTree.query lat: position.lat, lng: position.lng
  if 0 == nearest.length
    err = 'Could not found nearest station'
    err.status = 404
    return callback err

  module.exports.isTakeable apiKey, nearest[0].number, (err, takeable) ->
    if err or not takeable
      # Enlarge the search to the k-nearest stations
      checked = [nearest[0].number]
      k = 2
      while checked.length < 15
        rangeStations = stationsTree.query (lat: position.lat, lng: position.lng)
          , k: k, filter: (station) ->
            return not _.contains checked, station.number

        # the predicate is "not Takeable"
        # _.every returns true if all station pass the predicate (no station found)
        # returns false if one station doesn't pass the predicate (one station found)
        notFound = _.every rangeStations, (station) ->
          return not module.exports.isTakeable apiKey, station.number, (err, okay) ->
            if err or not okay
              checked.push station
              return true # continue looping
            else
              callback null, stations["#{station.number}"]
              return false # break loop

        if notFound
          k *= 2
        else
          break
      if checked.length >= 15
        err = 'Could not found available station at a decent distance'
        err.status = 404
        return callback err
    else
      callback null, stations["#{nearest[0].number}"]
