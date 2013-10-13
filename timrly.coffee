# Mike Solomon
# 9 Oct 2013
# timrly
# the only shared egg timer with a web 2.0 name

socket = io.connect 'http://localhost:8000'

createjs.Sound.registerSound $('#endSound')[0]

timeToString = (dateTime) ->
    dateTime.getMinutes().toString() + ":" + dateTime.getSeconds().toString() + "." + Math.floor(dateTime.getMilliseconds() / 100).toString()

socket.on 'update', (data) ->
    console.log data
    groupName = data['group']
    $('#groupName').val groupName
    localStorage['groupName'] = groupName
    username = data['user']
    $('#username').val username
    localStorage['username'] = username
    $('#members').text (u for u in data['users'])
    startTimer data['end_time']

timer = null
startTimer = (endTime) ->
    timeDisplay = $('#timeDisplay')
    empty_text = "00:00"
    clearInterval timer
    if not endTime?
        timeDisplay.text empty_text
        return
    timer = setInterval () ->
        time = new Date(null)
        milliseconds_left = endTime - new Date().getTime()
        if milliseconds_left <= 0
            clearInterval timer
            timer = setInterval () ->
                if document.title == empty_text
                    display_text = "--:--"
                else
                    display_text = empty_text
                document.title = display_text
                timeDisplay.text = display_text
            , 180
            milliseconds_left = 0
            if $('#soundOn').val()
                createjs.Sound.play 'endSound'
        time.setMilliseconds milliseconds_left
        timeString = timeToString time
        timeDisplay.text timeString
        document.title = timeString
    , 90


iChanged = () ->
    length = parseInt $('#time').val()
    console.log length
    if length == 0
        length = parseInt $('#customTime').val()
    length *= 1000
    now = new Date().getTime()
    socket.emit('set timer', now + length)

$(document).keypress (event) ->
    if event.keyCode == 13 # enter
        iChanged()

$('#start').click (event) ->
    iChanged()

$('#time').change (event) ->
    $('#customTime').val($(event.target).val())

$('#customTime').change (event) ->
    $('#time option').last().prop('selected', true)

$('#username').change (event) ->
    socket.emit 'set nickname', event.target.value

$('#groupName').change (event) ->
    socket.emit 'join group', event.target.value

$(window).unload (event) ->
    socket.emit 'leave group'

$(document).ready (event) ->
    username = localStorage['username']
    if username?
        console.log 'setting nick', username
        socket.emit 'set nickname', username
    groupName = localStorage['groupName']
    if groupName?
        socket.emit 'join group', groupName
