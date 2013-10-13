// Generated by CoffeeScript 1.6.2
(function() {
  var iChanged, socket, startTimer, timeToString, timer;

  socket = io.connect('http://localhost:8000');

  createjs.Sound.registerSound($('#endSound')[0]);

  timeToString = function(dateTime) {
    return dateTime.getMinutes().toString() + ":" + dateTime.getSeconds().toString() + "." + Math.floor(dateTime.getMilliseconds() / 100).toString();
  };

  socket.on('update', function(data) {
    var groupName, u, username;

    console.log(data);
    groupName = data['group'];
    $('#groupName').val(groupName);
    localStorage['groupName'] = groupName;
    username = data['user'];
    $('#username').val(username);
    localStorage['username'] = username;
    $('#members').text((function() {
      var _i, _len, _ref, _results;

      _ref = data['users'];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        u = _ref[_i];
        _results.push(u);
      }
      return _results;
    })());
    return startTimer(data['end_time']);
  });

  timer = null;

  startTimer = function(endTime) {
    var empty_text, timeDisplay;

    timeDisplay = $('#timeDisplay');
    empty_text = "00:00";
    clearInterval(timer);
    if (endTime == null) {
      timeDisplay.text(empty_text);
      return;
    }
    return timer = setInterval(function() {
      var milliseconds_left, time, timeString;

      time = new Date(null);
      milliseconds_left = endTime - new Date().getTime();
      if (milliseconds_left <= 0) {
        clearInterval(timer);
        timer = setInterval(function() {
          var display_text;

          if (document.title === empty_text) {
            display_text = "--:--";
          } else {
            display_text = empty_text;
          }
          document.title = display_text;
          return timeDisplay.text = display_text;
        }, 180);
        milliseconds_left = 0;
        if ($('#soundOn').val()) {
          createjs.Sound.play('endSound');
        }
      }
      time.setMilliseconds(milliseconds_left);
      timeString = timeToString(time);
      timeDisplay.text(timeString);
      return document.title = timeString;
    }, 90);
  };

  iChanged = function() {
    var length, now;

    length = parseInt($('#time').val());
    console.log(length);
    if (length === 0) {
      length = parseInt($('#customTime').val());
    }
    length *= 1000;
    now = new Date().getTime();
    return socket.emit('set timer', now + length);
  };

  $(document).keypress(function(event) {
    if (event.keyCode === 13) {
      return iChanged();
    }
  });

  $('#start').click(function(event) {
    return iChanged();
  });

  $('#time').change(function(event) {
    return $('#customTime').val($(event.target).val());
  });

  $('#customTime').change(function(event) {
    return $('#time option').last().prop('selected', true);
  });

  $('#username').change(function(event) {
    return socket.emit('set nickname', event.target.value);
  });

  $('#groupName').change(function(event) {
    return socket.emit('join group', event.target.value);
  });

  $(window).unload(function(event) {
    return socket.emit('leave group');
  });

  $(document).ready(function(event) {
    var groupName, username;

    username = localStorage['username'];
    if (username != null) {
      console.log('setting nick', username);
      socket.emit('set nickname', username);
    }
    groupName = localStorage['groupName'];
    if (groupName != null) {
      return socket.emit('join group', groupName);
    }
  });

}).call(this);