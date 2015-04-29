# General
bodyParser = require 'body-parser'
errors     = require './lib/errors'
express    = require 'express'
log        = require('./lib/log')(module)
logger     = require 'express-logger'
multer     = require 'multer'
path       = require 'path'
request    = require 'request'

# Database
stations = require './lib/stations'

stations.update process.env.VELOV_API_KEY, (err) ->
  throw err if err
  log.info 'Updated successfully.'


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


app.get '/station/:lng/:lat', (req, res, next) ->
  res.send hello: 'bonjour'
  stations.nearest lat: req.params.lat, lng: req.params.lng, (err, nearest) ->
    console.log err if err
    console.log yo: nearest


app.use (req, res, next) ->
  log.debug "Could not find URL #{req.url}"
  res.status 404
  res.end '<h1>404 not found</h1>'


app.use (error, req, res, next) ->
  log.error "Server error #{error}, #{req.url}"
  res.end 'err'


module.exports = app
