child_process = require 'child_process'

should = require 'should'
request = require 'request'
sinon = require 'sinon'

# https://github.com/scraperwiki/ident-express
# So that it appears in require.cache which we stub.
require 'ident-express'

fake_ident = 'root'
checkIdentFake = (req, res, next) ->
  req.ident = fake_ident
  next()

# ident-express doesn't return a module, but a function
# so we have to mock it via require's cache
@checkIdentStub = sinon.stub require.cache[require.resolve 'ident-express'],
  'exports',
  checkIdentFake

serv = require 'gand'

BASE_URL = 'http://localhost:3002'

describe 'gand', ->
  postQuota = (form, that, done) ->
    request.post
      uri: "#{BASE_URL}/quota"
      form: form
    , (err, res, body) ->
      [that.err, that.res, that.body] = arguments
      done()

  context 'when gand receives a request from an allowed IP and ident', ->
    serv.ALLOWED_IPS = ['127.0.0.1']
    context 'POST /quota', ->
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

  context 'when gand receives a request from a disallowed IP', ->
    before (done) ->
      serv.ALLOWED_IPS = []
      postQuota
        path: 'tes/testington'
        size: '500'
      , this, done

    it 'returns an unauthorised error', ->
      serv.ALLOWED_IPS = ['127.0.0.1']
      @res.should.have.status 403

  context "when gand receives a request from an allowed IP, but ident isn't root", ->
    before ->
      fake_ident = 'stilton'

    before (done) ->
      serv.ALLOWED_IPS = ['127.0.0.1']
      postQuota
        path: 'tes/testington'
        size: '500'
      , this, done

    it 'returns an unauthorised error', ->
      @res.should.have.status 403

    after ->
      fake_ident = 'root'






