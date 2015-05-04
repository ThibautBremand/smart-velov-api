URL = require('url')
urllib = require('urllib-sync')
http = require('http')
_ = require('underscore')

GH = (_host) ->
  this.url = URL.parse(_host)
  this.defaults = {'type': 'json'}
  this.reset()
  return this

GH.prototype.default = (_options, _net) ->
  this.defaults = _.extend(this.defaults, _options)
  if _net
    infos = this.getInfos()
    if infos
      this.defaults = _.extend(this.defaults, {
        'vehicle': infos.supported_vehicles[0]
      });

GH.prototype.getInfos = ->
  return false if !this.url.href
  url = _.extend(this.url,(pathname: '/info'))
  res = urllib.request(URL.format(url));
  return false if res.statusCode != 200
  return JSON.parse(res.data)

GH.prototype.route = (_points,_options) ->
  return false if !this.url.href
  return false if !_points
  this.points = _points
  this.url.pathname = '/route'
  this.url.query = _.extend(this.defaults, _options)
  return this.url

GH.prototype.doRequest = (_options, _callback) ->
  options = _.extend(this.url.query, _options)
  if options.instructions?
    if options.instructions in [true,false]
      options.instructions = "#{options.instructions}"
    else
      delete options.instructions
  this.url.query = options
  _.each(options, (value, key) ->
    this.url.query[key] = "#{value}"
  , this)

  urlStr = URL.format(this.url)
  for point in this.points
    urlStr += "&point=#{point}"

  http.get(urlStr, (res) ->
    err = if res.statusCode == 200 then null else (code: res.statusCode, message: res.statusMessage)
    _callback(err, res)
  ).on('error', (e) ->
    _callback(e)
  )
  return urlStr

GH.prototype.reset = ->
  this.points = []
  delete this.url.query
  this.url.pathname = '/'

module.exports = GH;
