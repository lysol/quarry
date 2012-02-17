var socket = io.connect('http://localhost:3000');

socket.on('game_message', function(data) {
    console.log(data);
});
