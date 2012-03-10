
class Game

    constructor: ->
        @canvas_width = 800
        @canvas_height = 500
        @canvas = document.getElementById 'quarry'
        @canvasContext = @canvas.getContext '2d'
        @buffer = document.getElementById 'buffer'
        @bufferContext = @buffer.getContext '2d'
        @blockStorage = {}
        @blockIndex = {}
        @location =
            x: 0
            y: 0

        @clock = 0
        @frameRateTarget = 20
        @tileSize = 32

        @player_img = new Image()
        @player_img.src = "img/player.png"        
        @socket = null
        @kibo = new Kibo() 

    draw: =>
        @bufferContext.clearRect 0, 0, @canvas_width, @canvas_height
        @canvasContext.clearRect 0, 0, @canvas_width, @canvas_height
        @bufferContext.fillStyle = 'rgb(0,0,0)'
        @bufferContext.fillRect 0,0,@canvas_width,@canvas_height    
        @clock++
        if @clock % 100 == 0
            @clock = 0
            @buildImages()
        for id, block of @blockStorage
            xdiff = Math.abs block.x - location.x
            ydiff = Math.abs block.y - location.y
            if xdiff < @canvas_width / @tileSize and ydiff < @canvas_height / @tileSize
                x1 = (@location.x - block.x) * @tileSize + @canvas_width / 2
                x1 -= @tileSize / 2
                y1 = (@location.y - block.y) * @tileSize + @canvas_height / 2
                y1 -= @tileSize / 2
                if not block.image_cached
                    @buildImage block
                @bufferContext.drawImage block.image_cached, x1, y1, @tileSize, @tileSize
        @bufferContext.fillStyle = 'white'
        @bufferContext.font = '10pt Helvetica'
        @bufferContext.fillText "Position #{@location.x},#{@location.y}", 5, 20
        @bufferContext.drawImage @player_img, @canvas_width / 2 - @tileSize / 2, 
            @canvas_height / 2 - @tileSize / 2, @tileSize, @tileSize
        @canvasContext.drawImage @buffer, 0, 0, @canvas_width, @canvas_height

    initSocket: ->
        @socket = io.connect 'http://127.0.0.1:3000'
        @socket.on 'test', (data) ->
        @socket.on 'locationUpdate', (data) =>
            @setLocation data.location
        @socket.on 'blockUpdate', (data) =>
            for block in data.blocks
                @blockStorage[block.id] = block
                if not @blockIndex[block.x]
                    @blockIndex[block.x] = {}
                if not @blockIndex[block.x][block.y]
                    @blockIndex[block.x][block.y] = []
                if block.id not in @blockIndex[block.x][block.y]
                    @blockIndex[block.x][block.y].push block.id
        @socket.on 'blockLocationRemove', (data) ->
            for block in data.blocks
                if @blockIndex[block.x] and @blockIndex[block.x][block.y]
                    thisList = @blockIndex[block.x][block.y]
                    for key in thisList
                        if key == block.id
                            @blockIndex[block.x][block.y].splice key, 1
                            continue
                    if @blockIndex[block.x][block.y].length == 0
                        delete @blockIndex[block.x][block.y]

        @socket.on 'blockRemove', (data) ->
            for block in data.blocks
                for x in @blockIndex
                    for y in @blockIndex[x]
                        thisList = @blockIndex[x][y]
                        for item in thisList
                            if thisList[item] == block.id
                                @blockIndex[x][y].splice item, 1
                                continue
                if @blockStorage[block.id]
                    delete @blockStorage[block.id]    
    start: ->
        @initSocket()


        @kibo.down 'up', =>
            @location.y -= 1
            @socket.emit 'move', xd: 0, yd: -1

        @kibo.down 'down', =>
            @location.y += 1
            @socket.emit 'move', xd: 0, yd: 1

        @kibo.down 'left', =>
            @location.x -= 1
            @socket.emit 'move', xd: -1, yd: 0

        @kibo.down 'right', =>
            @location.x += 1
            @socket.emit 'move', xd: 1, yd: 0

        runDraw = => @draw()

        setInterval runDraw, 1000 / @frameRateTarget

    buildImage: (block) ->
        if not block.image_cached
            img = new Image()
            img.src = "img/#{block.image}"
            block.image_cached = img

    buildImages: ->
        for id of @blockIndex
            block = @blockIndex[id]
            @buildImage block

    setLocation: (loc) ->
        @location.x = loc.x
        @location.y = loc.y


($ 'document').ready () ->
    game = new Game()
    game.start()
