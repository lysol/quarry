port = 3000

twigjs = require 'twig'
express = require 'express'
data = require './data'
app = express.createServer()
io = require 'socket.io'
sio = require 'socket.io-sessions'
forms = require './forms'
redisStore = (require 'connect-redis')(express)

app.configure () ->
    app.set 'view engine', 'html'

app.register 'html', twigjs

app.set 'view options',
    layout: false

app.use '/styles/', express.static __dirname + '/styles'
app.use '/js/', express.static __dirname + '/js'
app.use '/img/', express.static __dirname + '/img'
app.use '/asset_images/', express.static __dirname + '/asset_images'

app.use express.bodyParser()
app.use express.cookieParser()

sessionStorage = new redisStore
app.use express.session
    secret: '19j0ddjijs9jsoiejr'
    store: sessionStorage

app.dynamicHelpers session: (req, res) -> req.session

app.get '/registerSuccess', (req, res) ->
    res.render 'registerSuccess'

app.post '/register', (req, res) ->
    registerForm = new forms.RegisterForm 'register-form', 'well'
    registerForm = registerForm.render()
    _render = (error) ->
        res.render 'register',
            error: error
            register_form: registerForm
    form = req.body.quarryForm
    data.getUser form.username, (user) ->
        if user
            _render 'This username already exists.'
        else
            data.getUser form.email, (user) ->
                if user
                    _render 'This email address already exists.'
                else
                    if form.password != form.password2
                        _render 'The passwords do not match.'
                    else if '@' not in form.email
                        _render 'Invalid email address.'
                    else
                        data.createUser form.username, form.password, form.email, (user) ->
                            req.session.user = user
                            res.redirect '/registerSuccess'


app.get '/register', (req, res) ->
    f = new forms.RegisterForm 'register-form', 'well'
    res.render 'register',
        register_form: f.render()

app.get '/logout', (req, res) ->
    req.session.destroy()
    res.redirect '/'

app.post '/login', (req, res) ->
    loginForm = new forms.LoginForm 'login-form', 'well'
    loginForm = loginForm.render()
    form = req.body.quarryForm
    if not form.login or not form.password
        res.render 'login',
            error: 'Please fill out the entire form.'
            login_form: loginForm
    else
        data.tryLogin form.login, form.password, (user) ->
            if user
                req.session.user = user
                res.redirect '/'
            else
                res.render 'login',
                    error: 'Could not log you in.'
                    login_form: loginForm


app.get '/login', (req, res) ->
    lform = new forms.LoginForm 'login-form', 'well'
    res.render 'login',
        login_form: lform.render()

app.get '/', (req, res) ->
    res.render 'index'


####### GAME


app.get '/game', (req, res) ->
    if not req.session.user
        res.redirect '/login'
    res.render 'game'



#######
#

io = io.listen app

socket = sio.enable
    socket: io
    store: sessionStorage
    parser: express.cookieParser()

console.log socket

socket.on 'sinvalid', (client, session) -> client.emit 'refresh'

socket.on 'sconnection', (client, session) ->
    client.on 'move', (data) ->
        session.user.move data.xd data.yd
        data.sendAllBlocks session.user, (blocks) ->
            client.emit 'blockUpdate', blocks: blocks

    data.sendAllBlocks session.user, (blocks) ->
        client.emit 'blockUpdate', blocks: blocks
    console.log 'butts'

socket.on 'connection', (client) ->
    console.log 'farts'

app.listen port