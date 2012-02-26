port = 3000

twigjs = require 'twig'
express = require 'express'
data = require './data'
app = express.createServer()
io = require 'socket.io'
sio = require 'socket.io-sessions'
forms = require './forms'
redisStore = (require 'connect-redis')(express)
connect = require 'connect'

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
    key: 'express.sid'
    cookie: { path: '/', httpOnly: false, maxAge: null }

app.use app.router

app.dynamicHelpers session: (req, res) -> req.session

app.get '/registerSuccess', (req, res) ->
    res.render 'registerSuccess'

app.post '/register', (req, res) ->
    registerForm = new forms.RegisterForm 'register-form', 'form-horizontal'
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
    f = new forms.RegisterForm 'register-form', 'form-horizontal'
    res.render 'register',
        register_form: f.render()

app.get '/logout', (req, res) ->
    req.session.destroy()
    res.redirect '/'

app.post '/login', (req, res) ->
    loginForm = new forms.LoginForm 'login-form', 'form-horizontal'
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
    lform = new forms.LoginForm 'login-form', 'form-horizontal'
    res.render 'login',
        login_form: lform.render()

app.get '/', (req, res) ->
    res.render 'index'


####### GAME


app.get '/game', (req, res) ->
    console.log "HEADERS DURING GAME"
    console.log req.headers
    if not req.session.user
        res.redirect '/login'
    res.render 'game'



#######
#

io = io.listen app

parseCookie = connect.utils.parseCookie

Session = connect.middleware.session.Session


io.set 'authorization', (data, accept) ->
    console.log 'HEADERS DURING SOCKET:'
    console.log data.headers
    if data.headers.cookie
        data.cookie = parseCookie data.headers.cookie
        data.sessionID = data.cookie['express.sid']
        sessionStorage.get data.sessionID, (err, session) ->
            if (err || !session)
                accept 'Error', false
            else
                data.session = new Session data, session
                accept null, true
    else
        return accept 'No cookie transmitted', false
    accept null, true

io.sockets.on 'connection', (client) ->
    hs = client.handshake

    console.log 'Received a connection with a session: ' + hs.sessionID

    cb = ->
        hs.session.reload ->
            hs.session.touch().save()

    intervalID = setInterval cb, 60 * 1000

    client.on 'disconnect', -> clearInterval intervalId

    client.on 'move', (data) ->
        hs.session.user.move data.xd data.yd
        data.sendAllBlocks hs.session.user, (blocks) ->
            console.log 'Emitting block update'
            client.emit 'blockUpdate', blocks: blocks

    data.sendAllBlocks hs.session.user, (blocks) ->
        console.log 'Emitting block update'
        client.emit 'blockUpdate', blocks: blocks
    console.log 'butts'

    console.log 'Client connected'
    console.log client
    client.emit 'test', fart: 1



app.listen port