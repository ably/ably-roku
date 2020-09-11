# Ably Roku SDK  <!-- omit in toc -->

- [Supported platforms](#supported-platforms)
- [Instillation](#instillation)
- [Using the Realtime API](#using-the-realtime-api)
    - [Introduction](#introduction)
    - [Connection](#connection)
    - [Subscribing to a channel](#subscribing-to-a-channel)
- [Contributing](#contributing)
    - [Process](#process)
    - [Development Requirements](#development-requirements)

## Supported platforms
This SDK supports the following platforms:

Roku: Firmware versions 9.2 and greater

## Instillation
TBD

## Using the Realtime API

#### Introduction
TBD
#### Connection
TBD
#### Subscribing to a channel
TBD

## Contributing
#### Process
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

#### Development Requirements
For Development and side loading of the channel you will need the VS Code [BrightScript Language Extension](https://marketplace.visualstudio.com/items?itemName=celsoaf.brightscript).

You will also need to create an `.env` in the root of the project with the following values to streamline side loading:

```
# This can ether be the IP address of your Roku
# or you can set it to ${promptForHost} and the
# extension will show you a list of devices on
# your network to pick from
ROKU_IP=111.111.111.111

# The password you set on the device when
# installing developer mode
ROKU_PASSWORD=aaaa
```
