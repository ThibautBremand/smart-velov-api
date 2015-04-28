winston = require 'winston'

module.exports = (module) ->
  # using filename in log statements
  path = module.filename.split('/').slice(-2).join('/')

  new winston.Logger
    transports : [
      new winston.transports.Console
        colorize:   true,
        level:      'debug',
        label:      path
    ]
