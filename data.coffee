pg = require 'pg'
redis = require 'redis'
fs = require 'fs'
crypto = require 'crypto'

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
        console.log result
        if result.rowCount == 1
            callback result.rows[0]
        else
            callback False
