should = require 'should'

describe 'gand', ->
  # Could bind to an internal IP, use ident
  context 'when gand receives a request from an allowed IP and ident', ->
    context 'POST /quota', ->
      it 'should add a quota for the specified user'

    context 'PUT /quota/<user>', ->
      it 'should modify a quota for the specified user'

    # We probably don't need this yet.
    context 'DELETE /quota/<user>', ->
      it 'should delete a quota for the specified user'

  context 'when gand receives a request from a disallowed IP', ->
    it 'returns an unauthorised error'

  context "when gand receives a request from an allowed IP, but ident isn't root", ->
    it 'returns an unauthorised error'
