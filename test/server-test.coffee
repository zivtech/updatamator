assert = require 'assert'
Server = require('../lib/server').Server
app = require './mock-app'
redisClient = app.RedisClient

# TODO: Isn't there some way to pass variables forward in tests?
# it 'should accept data as the constructor', ->
data = require('./json-samples/json-sample-1')
server = new Server(data, app)

describe 'Server', ->
  describe '#getHostname()', ->
    it 'should report the hostname', ->
      assert.equal server.getHostname(), 'server1.example.com'
  describe '#getCSSName()', ->
    it 'should provide a css class safe representation of the hostname', ->
      assert.equal server.getCSSName(), 'server1-example-com'
  describe '#getPackages()', ->
    it 'should return the list of packages', ->
      assert.equal server.getPackages().length, 36, 'Correct number of packages found'
      assert.equal server.getPackages()[35], 'perl-modules'
      assert.equal server.getPackages()[0], 'apparmor'
  describe '#save()', ->
    it 'should persist the server and package information to redis', ->
      server.save ->
        redisClient.get 'server1.example.com', (error, data)->
          assert.equal 1262, data.length, 'Correct package list has been retrieved.'
        redisClient.sismember server.getPackageString(), 'server1.example.com', (error, data)->
          assert.equal data, true, 'Hostname is in package list'
        redisClient.sismember 'hosts', server.getHostname(), (error, data)->
          assert.equal data, true, 'Hostname is in hosts list'
        redisClient.sismember 'packages', server.getPackageString(), (error, data)->
          assert.equal data, true, 'Package string is in packages list.'
