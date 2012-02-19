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
app.use express.bodyParser()
app.use express.session secret: '19j0ddjijs9jsoiejr'

app.post '/register', (req, res) ->
    _render = (error) ->
        console.log "Error encountered #{error}"
        res.render 'register', error: error
    form = req.body
    console.log "Username: #{form.username}"
    data.getUser form.username, (user) ->
        console.log 'got here'
        if user
            _render 'This username already exists.'
        else
            user = data.getUser form.email, (user) ->
                if user
                    _render 'This email address already exists.'
                else
                    if form.password != form.password2
                        _render 'The passwords do not match.'
                    else if '@' not in form.email
                        _render 'Invalid email address.'
                    else
                        data.createUser form.username, form.password, form.email, (user) ->
                            console.log 'got here'
                            req.session.user = user
                            res.redirect '/registerSuccess'


app.get '/register', (req, res) ->
    f = new forms.RegisterForm 'register-form', 'well'
    res.render 'register',
        register_form: f.render()

app.get '/login', (req, res) ->
    lform = new forms.LoginForm 'login-form', 'well'
    res.render 'login',
        login_form: lform.render()

app.get '/', (req, res) ->
    res.render 'index', session: req.session

io.sockets.on 'connection', (socket) ->
    #socket.emit 'game_message', 'This is a test.'

app.listen port