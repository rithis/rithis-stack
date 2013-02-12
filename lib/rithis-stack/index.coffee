express = require "express"
plugins = require "./plugins"
async = require "async"
path = require "path"


class Stack
    constructor: (@directory, @name, pluginsQueueConcurrency = 10) ->
        self = this

        @publicDirectory = path.join directory, "public"
        @app = express()

        worker = (plugin, callback) ->
            plugin self, callback

        @plugins = async.queue worker, pluginsQueueConcurrency

        @plugins.drain = ->
            port = process.env.PORT or 3000

            self.app.listen port, ->
                console.log "#{self.name} listening port #{port}"


defaultStack = (directory, name, plugin) ->
    stack = new Stack directory, name

    stack.app.configure ->
        stack.app.use express.logger()
        stack.app.use express.bodyParser()

    stack.app.configure "development", ->
        stack.app.use express.errorHandler()

    stack.plugins.push plugins.assets
    stack.plugins.push plugins.bower
    stack.plugins.push plugins.crud
    stack.plugins.push plugins.mongoose
    stack.plugins.push plugin


module.exports.Stack = Stack
module.exports.plugins = plugins
module.exports.configure = defaultStack
