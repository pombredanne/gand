child_process = require 'child_process'

should = require 'should'
request = require 'request'
sinon = require 'sinon'

serv = require 'gand'

BASE_URL = 'http://localhost:3002'

describe 'gand', ->
  # Could bind to an internal IP, use ident
  context 'when gand receives a request from an allowed IP and ident', ->
    context 'POST /quota', ->
      postQuota = (form, that, done) ->
        request.post
          uri: "#{BASE_URL}/quota"
          form: form
        , (err, res, body) ->
          [that.err, that.res, that.body] = arguments
          done()

      before ->
        # TODO: this should use spawn, it's nicer
        @glusterStub = sinon.stub(child_process, 'exec').callsArg(1)

      context 'when the request is valid', ->
        path = 'tes/testington'
        size = 500 # MB
        before (done) ->
          postQuota
            path: path
            size: size
          , this, done

        it 'should add a quota for the specified path', ->
          @glusterStub.calledOnce.should.be.true
          quotaCalled = @glusterStub.calledWithMatch sinon.match RegExp(
            "gluster volume quota.*limit-usage.*#{path}.*#{size}MB")
          quotaCalled.should.be.true

        it 'returns success', ->
          @res.should.have.status 200

      context 'when the path is invalid', ->
        before (done) ->
          postQuota
            path: '/dev/kmem'
            size: 500 #MB
          , this, done

        it 'errors', ->
          @res.should.have.status 400

      context "when the path doesn't exist", ->
        before (done) ->
          postQuota
            path: 'flooplegarpledoesnotexist'
            size: 500 #MB
          , this, done

        it 'errors', ->
          @res.should.have.status 404

      context "when the size is invalid", ->
        before (done) ->
          postQuota
            path: 'tes/testington'
            size: 'hairyporkscratching'
          , this, done

        it 'errors', ->
          @res.should.have.status 400

    context 'PUT /quota/<path>', ->
      it 'should modify a quota for the specified path'

    # TODO: implement when needed
    context 'DELETE /quota/<path>', ->
      it 'should delete a quota for the specified path'

  context 'when gand receives a request from a disallowed IP', ->
    it 'returns an unauthorised error'

  context "when gand receives a request from an allowed IP, but ident isn't root", ->
    it 'returns an unauthorised error'
