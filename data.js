var pg = require('pg');
var hash = require('hash');
var fs = require('fs');

try {
    var salt = fs.readFileSync('.salt', 'utf-8');
} catch (err) {
    var salt = '';
}


var connString = "tcp://quarry:quarry@localhost/quarry";
var client = new pg.Client(connString);
client.connect();

exports.createUser = function(username, password, email, callback) {
    var query = client.query("SELECT * FROM users WHERE username = $1", [username]);
    query.on('row', function(row) {
        throw new Error("Username already exists.");
    });
    var query = client.query("SELECT * FROM users WHERE email = $1", [email]);
    query.on('row', function(row) {
        throw new Error("Email address already exists.");
    });

    client.query("INSERT INTO users( \
        username, \
        password, \
        email     \
        ) VALUES ( \
        $1, $2, $3 \
        );", [username, hash.sha256(password), email]);
    client.query(" \
        SELECT * FROM users \
        WHERE username = $1", [username]).on('row', function(row) {
            callback(row);
        });
};

exports.getUser = function(username, callback) {
    client.query("SELECT * FROM users WHERE username = $1", [username])
         .on('row', function(row) { callback(row) });
};
