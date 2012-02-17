port = 3000

twigjs = require 'twig'
express = require 'express'
data = require './data'
app = express.createServer()
io = require('socket.io').listen app
forms = require './forms'

app.configure () ->
    app.set 'view engine', 'html'

app.register 'html', twigjs

app.set 'view options',
    layout: false

app.use '/styles/', express.static __dirname + '/styles'
app.use '/js/', express.static __dirname + '/js'
app.use '/img/', express.static __dirname + '/img'
app.use '/asset_images/', express.static __dirname + '/asset_images'

app.use express.cookieParser()
app.use express.session secret: '19j0ddjijs9jsoiejr'

app.get '/register', (req, res) ->
    res.render 'register'

app.get '/login', (req, res) ->
    lform = new forms.LoginForm 'login-form'
    res.render 'login',
        login_form: lform

app.get '/', (req, res) ->
    res.render 'index'

io.sockets.on 'connection', (socket) ->
    socket.emit 'game_message', 'This is a test.'

app.listen port