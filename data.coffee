pg = require 'pg'
redis = (require 'redis').createClient()
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
client = new pg.Client
    host: 'localhost'
    user: 'quarry'
    password: 'quarry'
    database: 'quarry'
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
                    config =
                        text: """SELECT * FROM users WHERE username = $1"""
                        rowClass: exports.User
                    query = client.query config, [username], (error, result) ->
                        console.log result
                        callback result.rows[0]

exports.getUser = (username, callback) ->
    config = 
        text: "SELECT * FROM users WHERE username = $1 OR email = $1"
        rowClass: User
    query = client.query config, [username], (err, result) ->
        console.log result
        callback result.rows[0]


exports.tryLogin = (username, password, callback) ->
    password = hash password
    config = 
        text: "SELECT * FROM users WHERE (username = $1 OR email = $1) AND password = $2"
        rowClass: User
    query = client.query config, [username, password], (err, result) ->
        if result.rowCount == 1
            exports.connectUser result.rows[0]['username'], callback
        else
            callback False


exports.connectUser = (username, callback) ->
    exports.getUser username, (user) ->
        if not user
            throw 'No user found'
        redis.set "user:#{user.id}:x", user.x
        redis.set "user:#{user.id}:y", user.y
        #redis.hgetall "user:#{user.id}:properties", (hash) ->
        #    for key in hash
        #        user.__defineGetter__ key, () -> redis.hgetSync "user:#{user.id}:properties", key
        #        user.__defineSetter__ key, (val) -> redis.hset "user:#{user.id}:properties", key, val

        #user.setProp = (key, value) ->
        #    redis.get "user:#{user.id}:#{key}", (err, res) ->
        #        if !res
        #            user.__defineGetter__ key, () -> redis.hgetSync "user:#{user.id}:properties", key
        #            user.__defineSetter__ key, (val) -> redis.hset "user:#{user.id}:properties", key, val
        #        redis.set "user:#{user.id}:#{key}", value

        callback user


class User

    constructor: ->
        console.log @
        console.log 'balls'

    move: (xd, yx) =>
        console.log "Moving #{xd} #{xy}"
        @x = x + xd
        @y = y + yd
        redis.set "user:#{user.id}:x", @.x
        redis.set "user:#{user.id}:y", @.y


class Block
    constructor: (@x, @y, @id=null) ->
        if not @id
            @genId()

    hasProperty: (name, cb) -> redis.hexists "block_content:id:#{@id}", name, (err, res) -> cb res

    getProperty: (name, cb) -> redis.hget "block_content:id:#{@id}", name, (err, res) ->
        console.log "Key: #{name}\t Val: #{res}"
        cb res

    setProperty: (name, val, cb) ->
        redis.hset "block_content:id:#{@id}", name, val, (err, res) ->
            cb !err and res == 1

    setProperties: (hash, cb) ->
        redis.hmset "block_content:id:#{@id}", hash, (err, res) ->
            cb !err and res == 1

    dump: (cb) ->
        us = @
        resultant = {}
        redis.hkeys "block_content:id:#{@id}", (err, res) ->
            procTup = (key, cb) ->
                console.log 
                us.getProperty key, (res) ->
                    resultant[key] = res
                    cb()
            async.forEachSeries res, procTup, (err) ->
                cb resultant

    genId: -> @id = hash (new Date()).getTime().toString() + Math.random()


getBlocks = (x, y, callback) ->
    xl = parseInt x - xTileRange / 2
    xu = parseInt x + xTileRange / 2
    yl = parseInt y - yTileRange / 2
    yu = parseInt y + yTileRange / 2
    tups = []
    xes = (x for x in [xl..xu])
    iyes = (y for y in [yl..yu])
    for x in xes
        for y in iyes
            tup = [x, y]
            tups.push tup
    blocks = []
    procTup = (tup, cb) ->
        x = tup[0]
        y = tup[1]
        redis.scard "block:#{x}:#{y}:ids", (err, res) ->
            if res > 0
                redis.smembers "block:#{x}:#{y}:ids", (err, res) ->
                    procTup2 = (id, cb2) ->
                        (new Block x, y, id).dump (block) ->
                            blocks.push block
                            cb2()
                    async.forEachSeries res, procTup2, (err) ->
                        cb()
            else
                cb()
    async.forEachSeries tups, procTup, (err) ->
        callback blocks


exports.createBlock = (block, x, y, cb) ->
    block.dump (data) ->
        console.log data
        redis.hmset "block_content:id:#{block.id}", data, (err, res) ->
            redis.sadd "block:#{x}:#{y}:ids", block.id, (err, res) ->
                if not err
                    cb block.id



exports.sendAllBlocks = (user, callback) ->
    getBlocks user.x, user.y, (blocks) -> callback blocks

exports.Block = Block
exports.User = User

exports.quit = -> redis.quit()

exports.keys = (cb) ->
    redis.keys '*', (err, res) ->
        icb = (key, ncb) ->
            redis.hgetall key, (err, res) ->
                ncb()
        async.forEachSeries res, icb, (err) ->
            cb()
