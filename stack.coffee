mongoose = require 'mongoose'
express = require 'express'
bower = require 'bower'
async = require 'async'
exec = require('child_process').exec
crud = require 'rithis-crud'
path = require 'path'
fs = require 'fs'

coffeescript = require 'connect-coffee-script'
stylus = require('stylus').middleware
jade = require 'jade-static'


module.exports.configure = (directory, name, configurator) ->
    # path to public directory
    publicDirectory = path.join directory, 'public'

    # application
    app = express()

    app.configure ->
        app.use express.logger()
        app.use express.json()

        app.use jade publicDirectory
        app.use coffeescript publicDirectory
        app.use stylus publicDirectory
        app.use express.static publicDirectory

    app.configure 'development', ->
        app.use express.errorHandler()

    # database connection
    connectionString = process.env.MONGOHQ_URL or "mongodb://localhost/#{name}"
    db = mongoose.createConnection connectionString

    # startup
    componentsSource = path.join directory, 'component.json'
    componentsDestination = path.join publicDirectory, 'component.json'

    bowerTasks = [
        # link components config
        (callback) ->
            console.log "#{name} linking components.json"
            fs.symlink componentsSource, componentsDestination, ->
                callback()

        # install components
        (callback) ->
            previousDirectory = process.cwd()
            process.chdir publicDirectory

            installProcess = bower.commands.install()

            installProcess.on 'data', (data) ->
                console.log data

            installProcess.on 'end', ->
                process.chdir previousDirectory
                callback()

        # unlink components config
        (callback) ->
            console.log "#{name} unlinking components.json"
            fs.unlink componentsDestination, callback
    ]

    setupTasks = [
        # setup application
        (callback) ->
            console.log "#{name} configuring application"
            configurator app, db, callback

        # install components via bower
        (callback) ->
            console.log "#{name} installing components"
            async.series bowerTasks, callback
    ]

    async.series [
        # prepare application
        (callback) ->
            console.log "#{name} preparing application"
            async.parallel setupTasks, callback

        # serve application
        (callback) ->
            port = process.env.PORT or 3000

            app.listen port, ->
                console.log "#{name} listening port #{port}"
                callback()
    ]


module.exports.Schema = mongoose.Schema
module.exports.crud = crud
