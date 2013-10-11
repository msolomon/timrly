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
            socket.on('update', function(data) {
                console.log('update', data);
            });
            socket.on('group joined', function(data) {
                console.log(data);
            });
            socket.emit('set nickname', 'joe');
            socket.emit('set nickname', 'chet');
            socket.emit('set nickname', 'chet');
            socket.emit('join group', 'g1');
            socket.emit('join group', 'g2');
            </script>"

uniqueId = (length=5) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

class User
    constructor: (@socket) ->
        @name = 'boring user'

    setName: (name) ->
        @name = name

    getName: () ->
        @name

    message: (title, contents) ->
        @socket.emit title, contents


class Group
    constructor: (@name) ->
        @users = []
        @endTime = null

    join: (user) ->
        @users.push user

    leave: (user) ->
        @users = (u for u in @users when u != user)

    notify: (user) ->
        'Update all clients with full state update'
        info = @info(user)
        user.message 'update', info for user in @users

    info: (user) ->
        {
            group: @name,
            user: user,
            users: (u.getName() for u in @users),
            end_time: @endTime
        }

    setEndTime: (endTime) ->
        @endTime = endTime


class RoomManager
    constructor: () ->
        @groups = {}
        @usersToGroups = {}

    joinGroup: (groupName, user) ->
        'Leave previous group, if any, and join a new one'
        old_group = @usersToGroups[user]
        if old_group?
            old_group.leave user

        group = @groups[groupName] ? @groups[groupName] = new Group(groupName)
        group.join user
        @usersToGroups[user] = group
        group

    getGroup: (user) ->
        @usersToGroups[user]


pushHandlerFactory = (roomManager) ->
    pushHandler = (socket) ->
        user = new User(socket)
        socket.set 'user', user
        group = roomManager.joinGroup uniqueId(), user
        group.notify user.getName()

        # set nickname
        socket.on 'set nickname', (name) ->
            socket.get 'user', (err, user) ->
                user.setName name
                group.notify user.getName()

        # join group
        socket.on 'join group', (groupName) ->
            socket.get 'user', (err, user) ->
                group = roomManager.joinGroup groupName, user
                group.notify user.getName()

        # set timer end time
        socket.on 'set timer', (endTime) ->
            socket.get 'user', (err, user) ->
                group = roomManager.getGroup[user]
                group.notify user.getName()


# start the app server
server = http.createServer handler
io = socketio.listen server
io.sockets.on 'connection', pushHandlerFactory(new RoomManager)
server.listen 8000
