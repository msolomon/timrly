// Generated by CoffeeScript 1.6.2
(function() {
  var Group, RoomManager, User, connectHandlerFactory, disconnectHandlerFactory, fs, handler, http, io, roomManager, server, socketio, uniqueId;

  http = require('http');

  socketio = require('socket.io');

  fs = require('fs');

  handler = function(req, res) {
    var path;

    res.writeHead(200, {
      'Content-Type': 'text/html'
    });
    console.log('stuff', req.url);
    path = '.' + req.url;
    if (path === './') {
      path = 'client.html';
    }
    return res.end(fs.readFileSync(path));
  };

  uniqueId = function(length) {
    var id;

    if (length == null) {
      length = 5;
    }
    id = "";
    while (id.length < length) {
      id += Math.random().toString(36).substr(2);
    }
    return id.substr(0, length);
  };

  User = (function() {
    function User(socket) {
      this.socket = socket;
      this.name = 'boring user';
    }

    User.prototype.setName = function(name) {
      return this.name = name;
    };

    User.prototype.getName = function() {
      return this.name;
    };

    User.prototype.message = function(title, contents) {
      return this.socket.emit(title, contents);
    };

    return User;

  })();

  Group = (function() {
    function Group(name) {
      this.name = name;
      this.users = [];
      this.endTime = null;
    }

    Group.prototype.join = function(user) {
      return this.users.push(user);
    };

    Group.prototype.leave = function(user) {
      var u;

      return this.users = (function() {
        var _i, _len, _ref, _results;

        _ref = this.users;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          u = _ref[_i];
          if (u !== user) {
            _results.push(u);
          }
        }
        return _results;
      }).call(this);
    };

    Group.prototype.notify = function(user) {
      'Update all clients with full state update';
      var u, _i, _len, _ref, _results;

      _ref = this.users;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        u = _ref[_i];
        _results.push(u.message('update', this.info(u)));
      }
      return _results;
    };

    Group.prototype.info = function(user) {
      var u;

      return {
        group: this.name,
        user: user.getName(),
        users: (function() {
          var _i, _len, _ref, _results;

          _ref = this.users;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            u = _ref[_i];
            _results.push(u.getName());
          }
          return _results;
        }).call(this),
        end_time: this.endTime
      };
    };

    Group.prototype.setEndTime = function(endTime, expectedDelay) {
      if (expectedDelay == null) {
        expectedDelay = 500;
      }
      return this.endTime = endTime + expectedDelay;
    };

    return Group;

  })();

  RoomManager = (function() {
    function RoomManager() {
      this.groups = {};
      this.usersToGroups = {};
    }

    RoomManager.prototype.leaveGroup = function(user) {
      var old_group;

      old_group = this.usersToGroups[user];
      if (old_group != null) {
        old_group.leave(user);
        return old_group.notify();
      }
    };

    RoomManager.prototype.joinGroup = function(groupName, user) {
      'Leave previous group, if any, and join a new one';
      var group, _ref;

      this.leaveGroup(user);
      group = (_ref = this.groups[groupName]) != null ? _ref : this.groups[groupName] = new Group(groupName);
      group.join(user);
      this.usersToGroups[user] = group;
      return group;
    };

    RoomManager.prototype.getGroup = function(user) {
      return this.usersToGroups[user];
    };

    return RoomManager;

  })();

  connectHandlerFactory = function(roomManager) {
    var connectHandler;

    return connectHandler = function(socket) {
      var group, user;

      user = new User(socket);
      socket.set('user', user);
      group = roomManager.joinGroup(uniqueId(), user);
      group.notify();
      socket.on('set nickname', function(name) {
        return socket.get('user', function(err, user) {
          user.setName(name);
          group = roomManager.getGroup(user);
          return group.notify();
        });
      });
      socket.on('join group', function(groupName) {
        return socket.get('user', function(err, user) {
          group = roomManager.joinGroup(groupName, user);
          return group.notify();
        });
      });
      socket.on('leave group', function() {
        return socket.get('user', function(err, user) {
          roomManager.leaveGroup(user);
          return group.notify();
        });
      });
      return socket.on('set timer', function(endTime) {
        return socket.get('user', function(err, user) {
          group = roomManager.getGroup(user);
          group.setEndTime(endTime);
          return group.notify();
        });
      });
    };
  };

  disconnectHandlerFactory = function(roomManager) {
    return disconnectHandlerFactory = function(socket) {
      return socket.get('user', function(err, user) {
        return roomManager.leaveGroup(user);
      });
    };
  };

  server = http.createServer(handler);

  io = socketio.listen(server);

  roomManager = new RoomManager;

  io.sockets.on('connection', connectHandlerFactory(roomManager));

  io.sockets.on('disconnect', disconnectHandlerFactory(roomManager));

  server.listen(process.env.PORT || 5000);

}).call(this);
