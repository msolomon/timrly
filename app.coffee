# Mike Solomon
# 9 Oct 2013
# timrly.js
# the only shared timer with a web 2.0 name

http = require 'http'
socketio = require 'socket.io'

handler = (req, res) ->
    res.end "<script src='socket.io/socket.io.js'></script>\
            <script>
            var socket = io.connect('http://localhost:8000');
            socket.on('notification', function(data) {
                console.log(data);
            });
            socket.on('nickname set', function(data) {
                console.log(data);
            });
            socket.on('error', function(data) {
                console.log(data);
            });
            socket.on('group set', function(data) {
                console.log(data);
            });
            socket.emit('set nickname', 'joe');
            socket.emit('set nickname', 'chet');
            socket.emit('set nickname', 'chet');
            socket.emit('set group', 'g1');
            socket.emit('set group', 'g2');
            </script>"


# attach socket.io to the server
server = http.createServer handler
io = socketio.listen server


# Store users in memory
users = {}
addUser = (nickname, id) ->
    if not users[nickname]
        users[nickname] = id
        true
    else
        false

removeUser = (nickname) ->
   users[nickname] = false 


# Store groups in memory
groups = {}
joinGroup = (oldGroup, newGroup, id) ->
    if oldGroup?
        groups[oldGroup] = (x for x in groups[oldGroup] when x != id)
    groups[newGroup] ?= []
    groups[newGroup].push id

getGroup = (group) ->
    groups[group]


pushHandler = (socket) ->
    id = Math.random()
    socket.set 'id', id

    # set nickname
    socket.on 'set nickname', (name) ->
        socket.get 'nickname', (err, oldName) ->
            if name and addUser name, id
                if oldName and not err
                    removeUser oldName
                socket.set 'nickname', name, () ->
                    socket.emit 'nickname set', users
            else
                socket.emit 'error', 'nickname ' + name + ' taken'

    # set group
    socket.on 'set group', (groupName) ->
        # socket.get 'id', (err, id) ->
        #     if err then console.log 'could not get id for socket', err
        socket.get 'group', (err, oldGroup) ->
            joinGroup oldGroup, groupName, id
            socket.emit 'group set', getGroup groupName

# start the app server
io.sockets.on 'connection', pushHandler
server.listen 8000
