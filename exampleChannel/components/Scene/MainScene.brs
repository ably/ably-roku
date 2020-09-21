sub init()
  LOG_LEVEL = 3
  m.CHANNELS = {
    COINDESK: "[product:ably-coindesk/bitcoin]bitcoin:usd"
    OPEN_WEATHER_NEWS: "[product:ably-openweathermap/weather]weather:5128581"
    BITFLYER: "[product:ably-bitflyer/bitcoin]bitcoin:jpy"
  }

  m.demosGroup = m.top.findNode("demosGroup")

  ' Create the different live example UI blocks
  createDemo({
    header: "Coindesk - bitcoin prices live stream"
    description: "CoinDesk provides current pricing for Bitcoin. This data is available for free on their website. Using API Streamer, it's easy to access this data as a realtime stream. View the documentation for this product on Ably Hub to learn how to implement this yourself."
    channel: m.CHANNELS.COINDESK
    logLevel: LOG_LEVEL
  })

  createDemo({
    header: "Open Weather News - a live stream of weather related data"
    description: "OpenWeatherMap provides live weather data for almost any location over the world. This data is available for free on their website. Using API Streamer, it's easy to access this data as a realtime stream. View the documentation for this product on Ably Hub to learn how to implement this yourself."
    channel: m.CHANNELS.OPEN_WEATHER_NEWS
    logLevel: LOG_LEVEL
  })

  createDemo({
    header: "Bitflyer - bitcoin prices live stream"
    description: "Bitflyer provides current pricing for Bitcoin. This data is available for free on their website. Using API Streamer, it's easy to access this data as a realtime stream. View the documentation for this product on Ably Hub to learn how to implement this yourself."
    channel: m.CHANNELS.BITFLYER
    logLevel: LOG_LEVEL
  })

  createAndRunAblyTask(LOG_LEVEL)
end sub

' Used to create both the demo Ui node and the Ably Task
' @param {Object} configuration - A configuration object containing the header, description, channel, and logLevel to use for this demo
sub createDemo(configuration as Object)
  ' Create the demo Ui nodes
  demoUiNode = m.demosGroup.createChild("DemoBlock")
  demoUiNode.update({
    subType: "DemoBlock"
    header: configuration.header
    description: configuration.description
    channel: configuration.channel
  })
  m[configuration.channel + "-channelDemoUiNode"] = demoUiNode
end sub

' Creates the Ably task, sets up watchers on the event fields, assigns the channels to subscribe to, sets the log level, and starts the task.
' @param {Integer} logLevel - The level of logging the task should use
sub createAndRunAblyTask(logLevel as Integer)
  ' Create the AblyTask
  m.ablyTask = createObject("roSGNode", "AblyTask")

  ' Observe the event fields
  m.ablyTask.observeField("messageEvent", "onMessageEvent")
  m.ablyTask.observeField("error", "onError")
  m.ablyTask.observeField("connected", "onConnected")

  ' Assign the channels you wish to subscribe to and the logLevel if you wish to change the default
  channels = []
  for each key in m.CHANNELS
    channels.push(m.CHANNELS[key])
  end for
  m.ablyTask.channels = channels
  m.ablyTask.logLevel = logLevel

  ' Start the task
  m.ablyTask.control = "RUN"
end sub

' Triggered when there is an error event
' @param {Object} event - The RoSGNodeEvent object with the callback data
sub onError(event as Object)
  print "------------------ onError -----------------"
  print event.getRoSGNode().channel, event.getData()
end sub

' Triggered when connected and subscribed to the channel
' @param {Object} event - The RoSGNodeEvent object with the callback data
sub onConnected(event as Object)
  print "--------------- onConnected ----------------"
  print event.getRoSGNode().channel, event.getData()
end sub

' Triggered when there are new messages to be handled.
' @param {Object} event - The RoSGNodeEvent object with the callback data
sub onMessageEvent(event as Object)
  print "-------------- onMessagesEvent --------------"
  ' Get the channel name from the event objects node
  messageEvent = event.getData()
  channel = messageEvent.channel

  print "Channel:", channel
  currentTime = getTime(createObject("roDateTime").ToISOString(), true)

  ' Get the messages array from the event object
  messages = messageEvent.messages
  ' Based on the channel call the appropriate handler function
  if channel = m.CHANNELS.COINDESK then
    handleCoindeskMessages(messages, currentTime)
  else if channel = m.CHANNELS.OPEN_WEATHER_NEWS then
    handleOpenWeatherNewsMessages(messages, currentTime)
  else if channel = m.CHANNELS.BITFLYER then
    handleBitflyerMessages(messages, currentTime)
  end if
end sub

' Handles live updates for the Coindesk example
' @param {Object} messages - The array of message objects
' @param {String} time - The time string to display on the UI
sub handleCoindeskMessages(messages as Object, time as String)
  demoUiNode = m[m.CHANNELS.COINDESK + "-channelDemoUiNode"]
  for each message in messages
    demoUiNode.liveText = "$" + toString(message.data)
    demoUiNode.time = time
  end for
end sub

' Handles live updates for the Open Weather News example
' @param {Object} messages - The array of message objects
' @param {String} time - The time string to display on the UI
sub handleOpenWeatherNewsMessages(messages as Object, time as String)
  demoUiNode = m[m.CHANNELS.OPEN_WEATHER_NEWS + "-channelDemoUiNode"]
  for each message in messages
    descriptions = []
    for each weather in message.data.weather
      if isNonEmptyString(weather.description) then
        descriptions.push(weather.description)
      end if
    end for

    newTemperature = toString(message.data.main.temp - 273.15)
    temperatureParts = newTemperature.tokenize(".")
    if temperatureParts.count() > 1 then
      newTemperature = temperatureParts[0] + "." + left(temperatureParts[1], 2)
    end if

    if isNonEmptyArray(descriptions) then
      demoUiNode.liveText = newTemperature + "C with " + descriptions.join(", ")
    else
      demoUiNode.liveText = newTemperature + "C"
    end if
    demoUiNode.time = time
  end for
end sub

' Handles live updates for the Bitfyler example
' @param {Object} messages - The array of message objects
' @param {String} time - The time string to display on the UI
sub handleBitflyerMessages(messages as Object, time as String)
  demoUiNode = m[m.CHANNELS.BITFLYER + "-channelDemoUiNode"]
  for each message in messages
    demoUiNode.liveText = "¥" + toString(message.data.price)
    demoUiNode.time = time
  end for
end sub
