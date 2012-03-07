port = 3000

twigjs = require 'twig'
express = require 'express'
data = require './data'
app = express.createServer()
io = require 'socket.io'
sio = require 'socket.io-sessions'
forms = require './forms'
connect = require 'connect'

loadedUsers = {}


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

sessionStorage = new connect.session.MemoryStore()
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
                            console.log 'from createuser'
                            console.log user
                            req.session.user = user
                            loadedUsers[user.id] = user
                            res.redirect '/registerSuccess'


app.get '/register', (req, res) ->
    f = new forms.RegisterForm 'register-form', 'form-horizontal'
    res.render 'register',
        register_form: f.render()

app.get '/logout', (req, res) ->
    if req.session.user and req.session.user.id in loadedUsers
        delete loadedUsers[req.session.user.id]
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
                console.log 'trylogin'
                console.log user
                req.session.user = user
                loadedUsers[user.id] = user
                console.log req.session.user
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
    if not req.session.user
        res.redirect '/login'
    res.render 'game'



#######
#

io = io.listen app

parseCookie = connect.utils.parseCookie

Session = connect.middleware.session.Session


io.set 'authorization', (inData, accept) ->
    if inData.headers.cookie
        inData.cookie = parseCookie inData.headers.cookie
        inData.sessionID = inData.cookie['express.sid']
        sessionStorage.get inData.sessionID, (err, session) ->
            if (err || !session)
                accept 'Error', false
            else
                inData.session = new Session inData, session
                accept null, true
    else
        return accept 'No cookie transmitted', false
    accept null, true

io.sockets.on 'connection', (client) ->
    hs = client.handshake
    if not hs.session or not hs.session.user or hs.session.user.id not in loadedUsers
        return
    user = loadedUsers[hs.session.user.id]
    console.log "USER: "
    console.log user

    console.log 'Received a connection with a session: ' + hs.sessionID

    #cb = =>
    #    hs.session.reload =>
    #        hs.session.touch().save()
    #
    #intervalID = setInterval cb, 60 * 1000

    #client.on 'disconnect', -> clearInterval intervalID

    client.on 'move', (data) ->
        console.log "User during move"
        console.log user
        user.move data.xd, data.yd
        data.sendAllBlocks user, (blocks) ->
            console.log 'Emitting block update'
            client.emit 'blockUpdate', blocks: blocks

    data.sendAllBlocks user, (blocks) ->
        client.emit 'blockUpdate', blocks: blocks


app.listen port