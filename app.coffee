# General
express  = require 'express'
log      = require('./lib/log')(module)
logger   = require 'express-logger'
path     = require 'path'
request  = require 'request'
kd       = require 'kdtree'

# Database
stations = require './lib/stations'

stations.update process.env.VELOV_API_KEY, (err) ->
  throw err if err
  log.info 'Updated successfully.'

# Basic setup

app = express()

app.use express.static(path.join __dirname, '/public')

# Express app setup
app.use logger path: 'logs/log.txt'

app.get '/station', (req, res) ->
  tree = new kd.KDTree 2

  tree.insert 45.743317, 4.815747, 2010
  tree.insert 45.75197, 4.821662, 5015

  res.send answer: tree.nearest 45.75197, 4.821663


app.use (req, res, next) ->
  log.debug "Could not find URL #{req.url}"
  res.status 404
  res.end '<h1>404 not found</h1>'

app.use (error, req, res, next) ->
  log.error "HTTPS error #{error}, #{req.url}"
  res.end 'err'

module.exports = app
