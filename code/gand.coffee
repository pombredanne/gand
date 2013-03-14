fs = require 'fs'
child_process = require 'child_process'

express = require 'express'
checkIdent = require 'ident-express'

app = express()
app.configure ->
  app.use express.bodyParser()
  app.use express.logger()

# Define Port
port = process.env.GA_PORT or 3002

# Start Server
app.listen port, ->
  console.log "Listening on #{port}\nPress CTRL-C to stop server."
