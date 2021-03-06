fs = require 'fs'
child_process = require 'child_process'

express = require 'express'
checkIdent = require 'ident-express'

allowedIPsPath = '/etc/gand-allowed-ips.json'
if fs.existsSync allowedIPsPath
  allowed_ips = require allowedIPsPath

app = express()
app.configure ->
  app.use express.bodyParser()

app.configure 'staging', ->
  app.use express.logger()
  app.use express.errorHandler { dumpExceptions: true, showStack: true}

app.configure 'production', ->
  app.use express.logger()
  app.use express.errorHandler()


# Define Port
PORT = process.env.GA_PORT or 3002
exports.ALLOWED_IPS = allowed_ips

validatePath = (req, res, next) ->
  unless /^[a-z0-9_.-]+[/]?[a-z0-9_.-]+$/i.test req.body.path
    return res.send 400
  next()

validateSize = (req, res, next) ->
  unless /^[0-9]{1,6}$/.test req.body.size
    return res.send 400
  next()

validatePathAndSize = [validatePath, validateSize]

validatePathExists = (req, res, next) ->
  # Assumes it's a valid path
  fs.exists "#{process.env.GA_PATH}/#{req.body.path}", (exists) ->
    if exists
      next()
    else
      return res.send 404

validateIdent = (req, res, next) ->
  if req.ident != "root"
    return res.send 403
  next()

app.all '*', (req, res, next) ->
  if req.ip in exports.ALLOWED_IPS
    next()
  else
    return res.send 403

app.post '/quota/?', checkIdent, validateIdent, validatePathAndSize, validatePathExists, (req, res) ->
  cmd = "gluster volume quota #{process.env.GA_VOLUME} limit-usage /#{req.body.path} #{req.body.size}MB"

  child_process.exec cmd, (err, stdout, stderr) ->
    if err?
      msg = "Got error setting quota:"
      console.warn "#{msg} (#{err}) #{stdout} #{stderr}"
      return res.send 500,
        error: msg
        statusCode: err.code
        stdout: stdout
        stderr: stderr
    res.send 200

# Start Server
app.listen PORT, ->
  console.log "Listening on #{PORT}\nPress CTRL-C to stop server."
