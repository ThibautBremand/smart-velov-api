fs      = require 'fs'
log     = require('./log')(module)
request = require 'request'

dirty = true
stations = {}

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
    dirty = true

module.exports.update = (apiKey, callback) ->
  request 'https://api.jcdecaux.com/vls/v1/stations?contract=Lyon&apiKey=' +
  apiKey, (err, res, body) ->
    module.exports.save JSON.parse body
    callback err, res, stations if callback
