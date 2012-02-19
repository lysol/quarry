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
                        );""", [username, hash.sha256(password), email]
                    query = client.query """
                        SELECT * FROM users
                        WHERE username = $1
                        """, [username], (error, result) ->
                            callback result.rows[0]

exports.getUser = (username, callback) ->
    query = client.query "SELECT * FROM users WHERE username = $1 OR email = $1", [username], (err, result) ->
        callback result.rows[0]
