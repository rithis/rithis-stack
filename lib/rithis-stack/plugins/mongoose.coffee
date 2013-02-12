mongoose = require "mongoose"


module.exports = (stack, callback) ->
    connectionString = process.env.MONGOHQ_URL or "mongodb://localhost/#{stack.name}"

    stack.connection = mongoose.createConnection()
    stack.mongoose = mongoose
    stack.mongodb = mongoose.mongo

    stack.connection.open connectionString, ->
        callback()
