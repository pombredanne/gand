fs = require 'fs'
child_process = require 'child_process'

express = require 'express'
checkIdent = require 'ident-express'

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
port = process.env.GA_PORT or 3002

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

app.post '/quota/?', validatePathAndSize, validatePathExists, (req, res) ->
  cmd = "gluster volume quota #{process.env.GA_VOLUME} limit-usage #{process.env.GA_PATH}/#{req.body.path} #{req.body.size}MB"
  
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
app.listen port, ->
  console.log "Listening on #{port}\nPress CTRL-C to stop server."
