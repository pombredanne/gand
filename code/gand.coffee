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
  res.send 456

# Start Server
app.listen port, ->
  console.log "Listening on #{port}\nPress CTRL-C to stop server."
