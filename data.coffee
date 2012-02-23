pg = require 'pg'
redis = require 'redis'
fs = require 'fs'
crypto = require 'crypto'
async = require 'async'


tileSize = 32
xTileRange = 800 / tileSize + 2 * tileSize
yTileRange = 500 / tileSize + 2 * tileSize


try
    salt = fs.readFileSync '.salt', 'utf-8'
catch err
    salt = ''

hash = (string) =>
    shasum = crypto.createHash 'sha256'
    shasum.update string
    shasum.update salt
    return shasum.digest 'hex'




connString = "tcp://quarry:quarry@localhost/quarry"
client = new pg.Client connString
client.connect()

exports.createUser = (username, password, email, callback) ->
    query = client.query "SELECT * FROM users WHERE username = $1", [username], (error, result) ->
        if result.rows[0]
            callback false, "This username already exists."
        else
            query = client.query "SELECT * FROM users WHERE email = $1", [email], (error, result) ->
                if result.rows[0]
                    callback false, 'Email address already exists.'
                else

                    client.query """
                        INSERT INTO users (
                            username,
                            password,
                            email
                        ) VALUES (
                            $1,
                            $2,
                            $3
                        );""", [username, hash(password), email]
                    query = client.query """
                        SELECT * FROM users
                        WHERE username = $1
                        """, [username], (error, result) ->
                            callback result.rows[0]

exports.getUser = (username, callback) ->
    query = client.query "SELECT * FROM users WHERE username = $1 OR email = $1", [username], (err, result) ->
        callback result.rows[0]


exports.tryLogin = (username, password, callback) ->
    password = hash password
    query = client.query "SELECT * FROM users WHERE (username = $1 OR email = $1) AND password = $2", [username, password], (err, result) ->
        if result.rowCount == 1
            callback result.rows[0]
        else
            callback False

redis.getSync = (key) ->
    returnVal = null
    redis.get key, (err, res) ->
        returnVal = res
    while not returnVal
        continue
    return returnVal

exports.connectUser = (username, callback) ->
    exports.getUser username, (user) ->
        redis.set "user:#{user.id}:x", user.x
        redis.set "user:#{user.id}:y", user.y
        redis.keys "user:#{user.id}:*", (keys) ->
            for key in keys
                user.__defineGetter__ key, () -> redis.getSync "user:#{user.id}:#{key}"
                user.__defineSetter__ key, (val) -> redis.set "user:#{user.id}:#{key}", val
        user.move = (xd, yx) ->
            @.x = x + xd
            @.y = y + yd
            redis.set "user:#{user.id}:x", @.x
            redis.set "user:#{user.id}:y", @.y

        user.setProp = (key, value) ->
            redis.get "user:#{user.id}:#{key}", (err, res) ->
                if !res
                    user.__defineGetter__ key, () -> redis.getSync "user:#{user.id}:#{key}"
                    user.__defineSetter__ key, (val) -> redis.set "user:#{user.id}:#{key}", val
                redis.set "user:#{user.id}:#{key}", value

        callback user


getBlocks = (x, y, callback) ->
    xl = parseInt x - xTileRange / 2
    xu = parseInt x + xTileRange / 2
    yl = parseInt y - yTileRange / 2
    yu = parseInt y + yTileRange / 2
    tups = []
    xes = x for x in [xl..xu]
    iyes = y for y in [yl..yu]
    for x in xes
        for y in iyes
            tup = [x, y]
            tups.push tup
    blocks = []
    procTup = (tup, cb) ->
        x = tup[0]
        y = tup[1]
        redis.hgetall "block:#{x}:#{y}", (err, res) ->
            if res
                blocks.push res
            cb()
    async.forEachSeries tups, procTup, (err) ->
        callback blocks

exports.sendAllBlocks = (user, callback) ->
    getBlocks user.x, user.y, (blocks) -> callback blocks
