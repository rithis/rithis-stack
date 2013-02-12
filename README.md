# Our web stack: express, mongoose, rithis-crud

## Example usage

```coffeescript
rithis = require "rithis-stack"


rithis.configure __dirname, "example-app", (stack, callback) ->
    # schemas
    DocumentSchema = new stack.mongoose.Schema
        name: type: "string", required: true
        date: type: "date", required: true

    # models
    Document = stack.connection.model "documents", DocumentSchema

    # routes
    app.get "/documents", stack.crud
        .list(Document)
        .sort("-date")
        .make()

    app.post "/documents", stack.crud
        .post(Document)
        .make()

    # done
    callback()
```

You can define your own stack:

```coffeescript
rithis = require "rithis-stack"

stack = new rithis.Stack __dirname, "example-app"

stack.app.configure ->
    stack.app.use express.logger()
    stack.app.use express.bodyParser()

stack.app.configure "development", ->
    stack.app.use express.errorHandler()

stack.plugins.push plugins.crud
stack.plugins.push plugins.mongoose

stack.plugins.push (stack, callback) ->
    # schemas
    DocumentSchema = new stack.mongoose.Schema
        name: type: "string", required: true
        date: type: "date", required: true

    # models
    Document = stack.connection.model "documents", DocumentSchema

    # routes
    app.get "/documents", stack.crud
        .list(Document)
        .sort("-date")
        .make()

    app.post "/documents", stack.crud
        .post(Document)
        .make()

    # done
    callback()
```
