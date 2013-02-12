module.exports = (stack, callback) ->
    stack.app.get "/files/:filename", (req, res) ->
        gs = new stack.mongodb.GridStore stack.connection.db, req.params.filename, "r"

        gs.open (err) ->
            if err and err.message is "#{req.params.filename} does not exist"
                return res.send 404

            if err
                return res.send 500

            compiledMetadata = []
            for key, value of gs.metadata
                compiledMetadata.push "#{key}=#{value}"

            res.set "Content-Type", gs.contentType
            res.set "X-Object-Metadata", compiledMetadata.join "; "

            stream = gs.stream true
            stream.pipe res


    stack.app.post "/files", (req, res) ->
        unless req.files.file and req.body.filename
            return res.send 400

        metadata = {}
        for key, value of req.body
            unless key is "filename" or key is "content-type"
                metadata[key] = value

        gs = new stack.mongodb.GridStore stack.connection.db, req.body.filename, "w",
            content_type: req.body["content-type"] or "binary/octet-stream"
            metadata: metadata

        gs.open (err) ->
            if err
                return res.send 500

            if gs.length > 0
                return gs.close ->
                    res.send 409

            gs.writeFile req.files.file.path, (err) ->
                gs.close ->
                    if err
                        return res.send 500

                    res.send 201


    callback()
