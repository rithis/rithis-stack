sechash  = require 'sechash'
url      = require 'url'
expires  = require 'expires'
json     = require 'json-output'

module.exports = (stack, callback) ->
    options =
        expires: '1 week'
        authRoute: '/auth-token'
        authParam: 'authToken'
        authTokenHash:
            algorithm: 'sha256'
            iterations: 50

    generateSalt = ->
        sechash.basicHash 'sha1',
            String((Math.random() + 2) * Math.random())

    hashPassword = (password, salt) ->
        sechash.strongHashSync password,
            algorithm: options.authTokenHash.algorithm
            iterations: options.authTokenHash.iterations
            salt: salt

    options.authTokenHash.salt = generateSalt()
    
    UserSchema = new stack.mongoose.Schema
        username: type: "string", required: true
        password: type: "string", required: true
        salt: type: "string", required: true
        token: type: "string"
        tokenExpire: type: Date
        metadata: type: stack.mongoose.Schema.Types.Mixed

    UserSchema.pre 'validate', (next) ->
        @salt = generateSalt() unless @salt
        next()

    UserSchema.pre 'save', (next) ->
        @password = hashPassword @password, @salt
        next()

    User = stack.connection.model "users", UserSchema

    # Authenticate
    stack.app.use (req, res, next) ->
        uri = url.parse(req.url).pathname
        return next() unless options.authRoute == uri

        unless req.method == 'POST'
            message = '/auth-token only supports POST requests'
            return res.json json.error message
                , 405

        errorCallback = (err, status) ->
            res.json json.error err, status or 405
   
        User.findOne username: req.body.username, (err, user) ->
            if err
                return errorCallback err

            unless user
                return errorCallback 'User does not exists', 404

            if hashPassword(req.body.password, user.salt) != user.password
                return errorCallback 'Invalid password', 401
			
            authToken = sechash.strongHashSync(
                user.username + '+' + user.password + '+' + options.expires
            )

            user.token = authToken
            user.tokenExpire = new Date expires.after options.expires
            user.save ->
                res.json authToken: authToken
    
     # Populate user
    stack.app.use (req, res, next) ->
            if req.query[options.authParam]
                authToken = req.query[options.authParam]
            else if req.body[options.authParam]
                authToken = req.body[options.authParam]
            else if req.get 'Authorization'
                authToken = req.get('Authorization').replace 'Token ', ''

            unless authToken
                return next()

            User.findOne token: authToken, (err, user) ->
                return next() if err or !user
                return next() if expires.expired user.tokenExpire

                req.user =
                    username = user.username

                next()

    callback()
