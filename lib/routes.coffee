fs = require 'fs'
coffee = require 'coffee-script'
Server = require('./server').Server
PackageSet = require('../lib/package-set').PackageSet
async = require 'async'

module.exports.attach = (app)->
  app.router.get '/', ->
    context = this
    packageSet = new PackageSet(app)
    packageSet.listSets (error, sets)->
      loadPackageSet = (packageString, next)->
        item = new PackageSet(app)
        item.load packageString, (error)->
          if error
            return next error
          item.getThemableOutput (error, output)->
            output.packageSet = item
            next error, output
      async.map sets, loadPackageSet, (error, packageSets)->
        if error
          app.log.error 'Error loading packages for display', error
          return
        for i, packageSet of packageSets
          packageSets[i]['available-packages'] = app.renderTemplate 'package-detail', packageSet.packages
          servers = packageSet.packageSet.getServers()
          # TODO: this server.replace is duplicated from Server::getCSSName(), perhaps we should us that code somehow?
          servers = ({'server-name': server, 'css-name': "#{server.replace(/\./g, '-')}-logs"} for server in servers)
          packageSets[i]['server-logs'] = app.renderTemplate 'server-logs', servers
        availablePackageSets = app.renderTemplate 'available-package-set', packageSets
        content = app.renderTemplate 'available-package-sets', 'available-package-sets': availablePackageSets
        data =
          content: content
        app.sendResponse context, 200, app.renderPage context, data

  app.router.post '/package-updates', ->
    context = this
    data = context.req.body
    if data.hostname and data.updates
      response = 201
      message = 'Updates recorded'
      server = new Server(data, app)
      server.save()
      app.log.info "Update information received from #{server.getHostname()}"
    else
      response = 500
      message = 'Message parsing failed'
    context.res.writeHead response,
      'Content-Type': 'application/json'
    context.res.json message



  # Serve our client side javascript.
  app.router.get 'js/minified.js', ->
    if not app.clientScripts
      javascript = ''
      javascripts = [
        'clientLib/jquery-1.8.0.min'
        'clientLib/plates'
        'css/javascripts/foundation/jquery.foundation.accordion'
      ]
      for name in javascripts
        javascript += fs.readFileSync app.dir + "/#{name}.js", 'utf8'
      coffeescripts = [
        'lib/client'
      ]
      for name in coffeescripts
        javascript += coffee.compile fs.readFileSync "#{app.dir}/#{name}.coffee", 'utf8'
      app.clientScripts = javascript
    app.sendResponse this, 200, app.clientScripts,
      'Content-Type': 'application/javascript'
