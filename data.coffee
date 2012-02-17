pg = require 'pg'
redis = require 'redis'
hash = require 'hash'
fs = require 'fs'

try
    salt = fs.readFileSync '.salt', 'utf-8'
catch err
    salt = ''

connString = "tcp://quarry:quarry@localhost/quarry"
client = new pg.Client connString
client.connect()

exports.createUser = (username, password, email, callback) ->
    query = client.query "SELECT * FROM users WHERE username = $1", [username]
    query.on 'row', (row) ->
        throw new Error 'Username already exists.'
    query = client.query "SELECT * FROM users WHERE email = $1", [email]
    query.on 'row', (row) ->
        throw new Error 'Email address already exists.'
    client.query """
        INSERT INTO users (
            username,
            password,
            email
        ) VALUES (
            $1,
            $2,
            $3
        );""", [username, hash.sha256(password), email]
    client.query """
        SELECT * FROM users
        WHERE username = $1
        """, [username]
            .on 'row', callback

exports.getUser = (username, callback) ->
    client.query "SELECT * FROM users WHERE username = $1", [username]
        .on 'row', callback
