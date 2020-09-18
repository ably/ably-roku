# Ably on Roku

- [Supported platforms](#supported-platforms)
- [Installation](#installation)
- [Live Examples](#live-examples)
- [Contributing](#contributing)
    - [Process](#process)
    - [Development Requirements](#development-requirements)
- [Know Issues and Limitations](#know-issues-and-limitations)

## Supported platforms

**Note: this is an experimental proof of concept and is not intended for production use at this time.**

This proof of concept supports the following platforms:

Roku: Firmware versions 9.2 and greater

## Installation

If you would like to try out this experimental work in your own channel you can copy the contents of `AblySDK/components` into your channels `components` folder.

Example running and listening to an `AblyTask`:

```brightscript
sub init()
  ' Create the AblyTask
  m.ablyTask = createObject("roSGNode", "AblyTask")

  ' Assignee the channel you wish to subscribe to
  m.ablyTask.channel = "[product:ably-bitflyer/bitcoin]bitcoin:jpy"

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

## Live Examples

![Demo Example Gif](runningDemo.gif)

If you would like to view the live examples on your own Roku device you can follow the steps listed in the [Contributing -> Development Requirements](#development-requirements) section.

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

You will also need to create an `.env` in the root of the project. This `.env` file can be empty but if you wish to speed up side loading you can add the following values:

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

## Know Issues and Limitations

- The ability to supply your own token/key is not yet supported
- Keys are not refreshed when they expire leading to error events
- JWT token is not yet supported
- One task is required per channel you wish to subscribe to leading to one connection per channel
  - Plan is to support many channels per task leading to less overall connections
- History until attached is not yet supported
- Unlike the client libraries for other platforms messages are returned as array bundles
  - If we get an update with many messages we send one `messages` event as an array containing all the messages rather then one `message` event per message received. This is to reduce the number of times we need to cross thread boundaries
  - This means all events `messages` will be returned as an array
