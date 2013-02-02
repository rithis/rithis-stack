# Our web stack: express, mongoose, rithis-crud

## Example usage

```coffeescript
rithis = require 'rithis-stack'


rithis.configure __dirname, "example-app", (app, db, callback) ->
    # schemas
    DocumentSchema = new rithis.Schema
        name: type: 'string', required: true
        date: type: 'date', required: true

    # models
    Document = db.model 'documents', DocumentSchema

    # routes
    app.get '/documents', rithis.crud
        .list(Document)
        .sort('-date')
        .make()

    app.post '/documents', rithis.crud
        .post(Document)
        .make()

    # done
    callback()
```
