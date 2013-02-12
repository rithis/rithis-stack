crud = require "rithis-crud"


module.exports = (stack, callback) ->
    stack.crud = crud
    callback()
