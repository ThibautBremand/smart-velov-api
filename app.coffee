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
    next err if err
    res.json nearest

app.get '/route/:start/:end/(:vehicle)?', (req, res, next) ->
  options = if req.params.vehicle? then {vehicle: req.params.vehicle} else {}
  gh.route [req.params.start,req.params.end]
  url = gh.doRequest options, (ghErr, ghRes) ->
    if ghErr
      next ghErr
    else
      body = ''
      ghRes.on 'data', (chunk) ->
        body += chunk
      ghRes.on 'end', ->
        jbody = JSON.parse(body)
        _.each(jbody.paths, (path) ->
          _.each(path.instructions, (ins) ->
            delete ins.text
            delete ins.time
            delete ins.distance
          )
        )
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
