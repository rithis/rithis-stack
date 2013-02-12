bower = require "bower"
async = require "async"
path = require "path"
fs = require "fs"


module.exports = (stack, callback) ->
    componentsSource = path.join stack.directory, "component.json"
    componentsDestination = path.join stack.publicDirectory, "component.json"
    componentsDirectory = path.join stack.publicDirectory, "components"

    bowerTasks = [
        # link components config
        (callback) ->
            console.log "#{stack.name} linking components.json"
            fs.symlink componentsSource, componentsDestination, ->
                callback()

        # install components
        (callback) ->
            previousDirectory = process.cwd()
            process.chdir stack.publicDirectory

            installation = bower.commands.install()

            installation.on "data", (data) ->
                console.log data

            installation.on "end", ->
                process.chdir previousDirectory
                callback()

        # unlink components config
        (callback) ->
            console.log "#{stack.name} unlinking components.json"
            fs.unlink componentsDestination, ->
                callback()

        # set right modification time
        (callback) ->
            fs.stat componentsDirectory, (err, stats) ->
                callback err, stats.atime

        (atime, callback) ->
            fs.stat componentsSource, (err, stats) ->
                callback err, atime, stats.mtime

        (atime, mtime, callback) ->
            fs.utimes componentsDirectory, atime, mtime, ->
                callback()
    ]

    unless fs.existsSync componentsSource
        return callback()

    if fs.existsSync componentsDirectory
        fileStats = fs.statSync componentsSource
        directoryStats = fs.statSync componentsDirectory

        if fileStats.mtime <= directoryStats.mtime
            return callback()

    console.log "#{stack.name} installing components"
    async.waterfall bowerTasks, ->
        callback()
