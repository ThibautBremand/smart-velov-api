# General
bodyParser = require 'body-parser'
errors     = require './lib/errors'
express    = require 'express'
log        = require('./lib/log')(module)
logger     = require 'express-logger'
multer     = require 'multer'
path       = require 'path'
request    = require 'request'
gh         = new (require './lib/graphhopper')('http://aurelienbertron.fr:8989')
_          = require 'underscore'

# Database
stations = require './lib/stations'

stations.update process.env.VELOV_API_KEY, (err) ->
  throw err if err
  log.info 'Updated successfully.'

gh.default vehicle: 'bike2', instructions: true, locale: 'fr'

# Express setup
app = express()

app.use express.static(path.join __dirname, '/public')

# For parsing application/json
app.use bodyParser.json()
# For parsing application/x-www-form-urlencoded
app.use bodyParser.urlencoded extended: true
# For parsing multipart/form-data
app.use multer()

app.use logger path: 'logs/log.txt'


app.get '/station/:lat/:lng', (req, res, next) ->
  stations.nearest lat: req.params.lat, lng: req.params.lng, (err, nearest) ->
    return err if err
    res.json nearest

app.get '/route/velov/:start/:end', (req, res, next) ->
  startArray = req.params.start.split ','
  start = lat: startArray[0], lng: startArray[1]
  endArray = req.params.end.split ','
  end = lat: endArray[0], lng: endArray[1]

  stations.best process.env.VELOV_API_KEY, start, (err, best) ->
    return err if err
    stationStart = name: best.name, lat: best.position.lat, lng: best.position.lng
    stations.nearest end, (err, nearest) ->
      return err if err
      stationEnd = name: nearest.name, lat: nearest.position.lat, lng: nearest.position.lng
      # Get the path to start station
      gh.route [req.params.start,"#{stationStart.lat},#{stationStart.lng}"]
      gh.doRequest {vehicle: 'foot'}, (ghErr, ghBody) ->
        return ghErr if ghErr
        first = JSON.parse ghBody
        gh.route ["#{stationStart.lat},#{stationStart.lng}","#{stationEnd.lat},#{stationEnd.lng}"]
        gh.doRequest {vehicle: 'bike2'}, (ghErr2, ghBody2) ->
          return ghErr2 if ghErr2
          second = JSON.parse ghBody2
          gh.route ["#{stationEnd.lat},#{stationEnd.lng}", req.params.end]
          gh.doRequest {vehicle: 'foot'}, (ghErr3, ghBody3) ->
            return ghErr3 if ghErr3
            third = JSON.parse ghBody3
            ret = {paths: []}
            _.each [first,second,third], (itinerary) ->
              _.each itinerary.paths[0].instructions, (ins) ->
                delete ins.text
                delete ins.time
                delete ins.distance
              ret.paths.push itinerary.paths[0]
            res.json ret

app.get '/route/:start/:end/(:vehicle)?', (req, res, next) ->
  options = if req.params.vehicle? then {vehicle: req.params.vehicle} else {}
  gh.route [req.params.start,req.params.end]
  url = gh.doRequest options, (ghErr, ghBody) ->
    if ghErr
      next ghErr
    else
      jbody = JSON.parse ghBody
      _.each jbody.paths, (path) ->
        _.each path.instructions, (ins) ->
          delete ins.text
          delete ins.time
          delete ins.distance
      delete jbody.info
      res.json jbody

app.use (req, res, next) ->
  log.debug "Could not find URL #{req.url}"
  res.status 404
  res.end '<h1>404 not found</h1>'


app.use (error, req, res, next) ->
  log.error "Server error #{error}, #{req.url}"
  res.end 'err'


module.exports = app
