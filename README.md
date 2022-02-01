
# Ably on Roku - proof-of-concept

## Description

This repository is a proof-of-concept demo of subscribing to [Ably channels](https://www.ably.io/) on Roku platform
using Brightscript.

[Bitflyer](https://www.ably.io/hub/ably-bitflyer/bitcoin), [Coindesk](https://www.ably.io/hub/ably-coindesk/bitcoin) and [Weather Data](https://www.ably.io/hub/ably-openweathermap/weather) channels from Ably Hub are used to power this demo.

**Note: this is an experimental proof of concept and is not intended for production use at this time.**

Example screen capture from a Roku device:

![Demo Example Gif](runningDemo.gif)

If you would like to view the live examples on your own Roku device you can follow the steps listed in the [Contributing -> Development Requirements](#development-requirements) section.

## Supported platforms

This proof of concept supports the following platforms:

Roku: Firmware versions 9.2 and greater

## Installation

If you would like to try out this experimental work in your own channel you can copy the contents of `source/components` into your channel's `components` folder.

Example running and listening to an `AblyTask`:

```brightscript
sub init()
  ' Create the AblyTask
  m.ablyTask = createObject("roSGNode", "AblyTask")

  ' Assign the API to the task used for authentication
  m.ablyTask.key = "xVLyHw.XuwW-w:yOPxtXWlsZn10nzy"

  ' Assign the channels you wish to subscribe to
  m.ablyTask.channels = [
    "[product:ably-bitflyer/bitcoin]bitcoin:jpy",
    "[product:ably-coindesk/bitcoin]bitcoin:usd",
    "[product:ably-openweathermap/weather]weather:5128581"
  ]

  ' Observe the event fields
  m.ablyTask.observeField("messages", "onMessages")
  m.ablyTask.observeField("error", "onError")
  m.ablyTask.observeField("connected", "onConnected")

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
sub onMessages(event as Object)
  print "---------------- onMessages ----------------"
  messages = event.getData()
  for each message in messages
    print message.data
  end for
end sub
```

## Want to use Ably on Roku?

If you want to use Ably on Roku platform please [get in touch with the Ably team](https://ably.com/contact).

## About Ably


Ably is an enterprise-ready pub/sub messaging platform with integrated services to easily build complete realtime functionality delivered directly to end-users. We power the apps people and enterprises depend on everyday. Developers from startups to industrial giants build on Ably to simplify engineering, minimize DevOps overhead, and increase development velocity.

[ably.com](https://ably.com)


## Contributing

#### Process

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

#### Development Requirements

For development and side loading of the channel we use [VS Code](https://code.visualstudio.com/) with the [BrightScript Language Extension](https://marketplace.visualstudio.com/items?itemName=celsoaf.brightscript).

You will also need to [Enabling Developer Mode](https://developer.roku.com/en-ca/videos/courses/getting-started/developer-mode.md) on your device.

**Note**: We will not be using the browser-based Development Application Installer shown in the video ourselves. The extension will be taking care of all of that for us in VS Code.

You will also need to create a `.env` in the root of the project. This `.env` file can be empty but if you wish to speed up side loading you can add the following values:

```shell
# This can ether be the IP address of your Roku
# or you can set it to ${promptForHost} and the
# extension will show you a list of devices on
# your network to pick from
ROKU_IP=111.111.111.111

# The password you set on the device when
# installing developer mode
ROKU_PASSWORD=aaaa
```

Once you have created your `.env` file you are now ready to side load the channel. Simply click on `Run` -> `Start Debugging` or press `F5` by default. The extension should take over from here.

## Known Issues and Limitations

- The ability to supply your own token is not yet supported
- Unlike the client libraries for other platforms messages are returned as array bundles
  - If we get an update with many messages we send one `messageEvent` event object that has a `messages` array containing all the messages rather than one `message` event per message received. This is to reduce the number of times we need to cross thread boundaries
  - This means all events `messages` will be returned as an array
