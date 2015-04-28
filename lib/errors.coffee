log  = require('./log')(module)
util = require 'util'

module.exports.notFoundError = (id) ->
  err = new Error "Could not find: #{id}"
  err.name = 'NotFoundError'
  err.statusCode = 404
  return err


module.exports.handleError = (err, req, res) ->
  return log.debug 'handleError called with no error' if !err

  log.error "#{err.name}: #{err.message}"
  log.error "User: #{req.user.email}" if req.user
  log.debug util.inspect err

  res.statusCode = err.status || res.statusCode
  res.statusCode = err.statusCode || res.statusCode

  switch err.name
    when 'ValidationError'
      res.statusCode = res.statusCode || 400
      errToSend = error:
        name: 'Bad Request'
        message: "#{err.message} (check 'Accept' header)"
    when 'NotFoundError'
      res.statusCode = res.statusCode || 404
      errToSend = error:
        name: 'Not Found'
        message: err.message
    else
      res.statusCode = 500
      errToSend = error:
        name: 'Internal Server Error'

  return res.send errToSend
