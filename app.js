var twigjs = require('twig');
var express = require('express');
var data = require('./data');
var app = express.createServer();

app.configure(function() {
    app.set('view engine', 'html');
});

app.register('html', twigjs);

app.set('view options', {
    layout: false
});

app.use('/styles/', express.static(__dirname + '/styles'));

app.get('/', function(req, res) {
    res.render('index');
});

app.listen(3000);