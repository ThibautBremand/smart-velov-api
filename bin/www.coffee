# Module dependencies
app   = require '../app'
http  = require 'http'
https = require 'https'
log   = require('../lib/log')(module)
pem   = require 'pem'
step  = require 'step'

# Default is HTTPS = true, you need to set it to false to change it
isHttps = not (process.env.HTTPS && process.env.HTTPS.toLowerCase() == "false")

# Get port from environment and store in Express
# (defaults to 3000 for HTTPS, 4000 for HTTP)
port = process.env.PORT || (if isHttps then 3000 else 4000)
app.set 'port', port

step ->
  # Create HTTP (or HTTPS) server
  if isHttps
    callback = this
    pem.createCertificate days: 1, selfSigned: true, (err, keys) ->
      httpsOptions =
        key: keys.serviceKey
        cert: keys.certificate

      callback null, https.createServer(httpsOptions, app)
  else
    return http.createServer app

, (err, server) ->
  throw err if err

  # Listen on provided port, on all network interfaces
  server.listen port
  server.on 'listening', ->
    log.info "Express server listening on port #{server.address().port},"
    log.info "HTTPS #{if isHttps then 'activated' else 'deactived'}."

  # Event listener for HTTP server "error" event
  server.on 'error', (error) ->
    # handle specific listen errors with friendly messages
    switch error.code
      when 'EACCES'
        log.error "Port #{port} requires elevated privileges,"
        log.error 'exiting.'
        process.exit 1
      when 'EADDRINUSE'
        log.error "Port #{port} is already in use,"
        log.error 'exiting.'
        process.exit 1
      else
        throw error
