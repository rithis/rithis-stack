async = require "async"
path = require "path"
fs = require "fs"


module.exports = (stack, callback) ->
    stack.fixturesDirectory = path.join stack.directory, "fixtures"

    setupFixtures = ->
        db = stack.connection

        fs.readdir stack.fixturesDirectory, (err, files) ->
            return callback() unless files

            # prepare tasks
            tasks = []
            for file in files
                if path.extname(file) is ".json"
                    tasks.push
                        collection: path.basename file, ".json"
                        file: path.join stack.fixturesDirectory, file

            # worker for fixture task
            worker = (task, callback) ->
                async.waterfall [
                    (callback) ->
                        fs.readFile task.file, callback

                    (data, callback) ->
                        try
                            callback null, JSON.parse data
                        catch err
                            callback err

                    (fixture, callback) ->
                        collection = db.collection task.collection
                        collection.count (err, count) ->
                            return callback err if err
                            return callback null if count > 0

                            collection.insert fixture, safe: true, callback
                ], callback

            # run workers for each fixtures
            async.forEach tasks, worker, ->
                callback()

    # one means connected
    if stack.connection.readyState is 1
        setupFixtures()
    else
        stack.connection.on "connected", setupFixtures
