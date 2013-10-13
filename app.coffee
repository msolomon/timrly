# Mike Solomon
# 9 Oct 2013
# timrly
# the only shared egg timer with a web 2.0 name

http = require 'http'
socketio = require 'socket.io'
fs = require 'fs'

handler = (req, res) ->
    res.writeHead 200, {'Content-Type': 'text/html'}
    console.log 'stuff', req.url
    # this is massively insecure. please don't run this anywhere
    path = '.' + req.url
    if path == './' then path = 'client.html'
    res.end fs.readFileSync path

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
        u.message 'update', @info(u) for u in @users

    info: (user) ->
        {
            group: @name,
            user: user.getName(),
            users: (u.getName() for u in @users),
            end_time: @endTime
        }

    setEndTime: (endTime, expectedDelay = 500) ->
        @endTime = endTime + expectedDelay


class RoomManager
    constructor: () ->
        @groups = {}
        @usersToGroups = {}

    leaveGroup: (user) ->
        old_group = @usersToGroups[user]
        if old_group?
            old_group.leave user
            old_group.notify()

    joinGroup: (groupName, user) ->
        'Leave previous group, if any, and join a new one'
        @leaveGroup user

        group = @groups[groupName] ? @groups[groupName] = new Group(groupName)
        group.join user
        @usersToGroups[user] = group
        group

    getGroup: (user) ->
        @usersToGroups[user]


connectHandlerFactory = (roomManager) ->
    connectHandler = (socket) ->
        user = new User(socket)
        socket.set 'user', user
        group = roomManager.joinGroup uniqueId(), user
        group.notify()

        # set nickname
        socket.on 'set nickname', (name) ->
            socket.get 'user', (err, user) ->
                user.setName name
                group = roomManager.getGroup user
                group.notify()

        # join group
        socket.on 'join group', (groupName) ->
            socket.get 'user', (err, user) ->
                group = roomManager.joinGroup groupName, user
                group.notify()

        socket.on 'leave group', () ->
            socket.get 'user', (err, user) ->
                roomManager.leaveGroup user
                group.notify()

        # set timer end time
        socket.on 'set timer', (endTime) ->
            socket.get 'user', (err, user) ->
                group = roomManager.getGroup user
                group.setEndTime endTime
                group.notify()

disconnectHandlerFactory = (roomManager) ->
    disconnectHandlerFactory = (socket) ->
        socket.get 'user', (err, user) ->
            roomManager.leaveGroup user

# start the app server
server = http.createServer handler
io = socketio.listen server
roomManager = new RoomManager
io.sockets.on 'connection', connectHandlerFactory(roomManager)
io.sockets.on 'disconnect', disconnectHandlerFactory(roomManager)
server.listen process.env.PORT || 5000
