coffeescript = require "connect-coffee-script"
responsive = require "stylus-responsive"
express = require "express"
stylus = require "stylus"
jade = require "jade-static"
nib = require "nib"


module.exports = (stack, callback) ->
    compilerFactory = (str, path) ->
        compiler = stylus str
        
        compiler.set "filename", path
        compiler.set "compress", false
        
        compiler.use nib()
        compiler.use responsive
        
        compiler.import "nib"
        compiler.import "responsive"

    stack.app.configure ->
        stack.app.use stylus.middleware
            src: stack.publicDirectory
            compile: compilerFactory

        stack.app.use jade stack.publicDirectory
        stack.app.use coffeescript stack.publicDirectory
        stack.app.use express.static stack.publicDirectory

    callback()
