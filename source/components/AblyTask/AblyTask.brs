'==== Setup ====
'#region - The main setup and initial auth flows
'==== Setup ====

sub init()
  ' Function to run in the task tread once started
  m.top.functionName = "runTask"

  ' Used for testing and working on token refresh logic
  ' If you want to test/work on refreshing on AUTH actions set a TTL of more then "45000" ms
  ' If you want to test/work on tokens expiring then set a TTL of "30000" ms or less
  m.TOKEN_TTL$ = ""

  ' Possible actions returned by realtime services
  m.ACTIONS = {
    HEARTBEAT: 0,
    ACK: 1,
    NACK: 2,
    CONNECT: 3,
    CONNECTED: 4,
    DISCONNECT: 5,
    DISCONNECTED: 6,
    CLOSE: 7,
    CLOSED: 8,
    ERROR: 9,
    ATTACH: 10,
    ATTACHED: 11,
    DETACH: 12,
    DETACHED: 13,
    PRESENCE: 14,
    MESSAGE: 15,
    SYNC: 16,
    AUTH: 17
  }

  ' Highest supported log level. If set higher it will be lowered to match.
  m.MAXIMUM_LOG_LEVEL = 5
end sub

' Any code run from this functions will be run in the async task thread
sub runTask()
  ' Used to stop the event loop in the event of an error
  m.encounteredCriticalError = false

  ' Get all the public values in one pass to limit the amount of rendezvous
  topValues = m.top.getFields()

  ' Process constructor values
  m.ENDPOINT = topValues.endpoint
  m.CHANNELS = topValues.channels
  HISTORY_UNTIL_ATTACH = topValues.historyUntilAttach

  m.logLevel = m.top.logLevel
  if m.logLevel > m.MAXIMUM_LOG_LEVEL then m.logLevel = m.MAXIMUM_LOG_LEVEL

  ' Get the Authentication key
  m.authenticationKey = topValues.key
  getJwtToken()

  ' Establish the initial connection
  if connect() then
    subscribeToChannels(HISTORY_UNTIL_ATTACH)
    ' Start watching for events
    stream()
  end if
end sub
'#endregion ==== End of Setup ====



'==== Comet protocol handling ====
'#region - Main starting point for processing events sent to us via the comet protocol
'==== Comet protocol handling ====

sub handleBody(body)
  for each protocolMessage in body
    if isNumber(protocolMessage.action) then
      action = protocolMessage.action
      if m.ACTIONS.HEARTBEAT = action then
        ' /* nothing to do */
        logVerbose("heartbeat")
      else if m.ACTIONS.ATTACHED = action then
        ' /* TODO: handle any attach errors */
        logInfo("Attached to:", protocolMessage.channel)
      else if m.ACTIONS.MESSAGE = action then
        ' Process the message into something the client can use
        eventBody = {
          channel: protocolMessage.channel
        }

        ' Process each message for the client to lower the impact on the render thread
        messages = []
        for each message in protocolMessage.messages
          if message.encoding = "json" then message.data = ParseJson(message.data)
          messages.push(message)
          logVerbose("message:", message)
        end for

        ' Attach the processed messages to the event to be returned to the client
        eventBody.messages = messages

        ' Return the event to the client
        m.top.messageEvent = eventBody
      else if m.ACTIONS.DISCONNECTED = action then
        logInfo("disconnected", protocolMessage)
      else if m.ACTIONS.AUTH = action then
        logInfo("AUTH action received - updating token")
        getJwtToken()
      end if
    end if
  end for
end sub

'#endregion ==== End of Comet protocol handling ====



'==== REST api functions ====
'#region - These functions are used call and handle different REST api requests
'==== REST api functions ====

sub getJwtToken()
  ' Clear the old token
  m.jwtToken = Invalid

  ' the & denotes LongInteger
  ' Without this the conversion to milliseconds will be incorrect
  timestamp& = createObject("roDateTime").AsSeconds()
  timestamp& = timestamp& * 1000

  ' Split the token into the public and private parts
  keyParts = m.authenticationKey.tokenize(":")
  keyName = keyParts[0]
  keySecret = keyParts[1]

  ' Get a JWT token
  result = makeRequest(requestTokenEndpoint(keyName), {
    "body": {
      "ttl": m.TOKEN_TTL$,
      "timestamp": timestamp&,
      "keyName": keyName,
    },
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
      "Authorization": "Basic " + stringToBase64(m.authenticationKey),
    }
  })

  if result.code = 201 then
    m.jwtToken = result.body.token
  else
    triggerErrorEvent("JWT Token Fetch", result.body, true)
  end if
end sub

function connect() as Boolean
  ' Make the initial connection request
  response = makeRequest(connectEndpoint(), {
    "headers": addAuthenticationToHeaders({
      "Accept": "application/json"
      "Content-Type": "application/json"
    })
  })

  ' Handle the response
  if response.code = 200 then
    if isNonEmptyArray(response.body) then
      firstEntry = response.body[0]
      if isNonEmptyAA(firstEntry) AND isNonEmptyAA(firstEntry.connectionDetails) then
        ' Store the connection key and emit a connection event
        logInfo("Connection:", firstEntry)
        m.connection = firstEntry
        m.top.connected = firstEntry.connectionDetails
        return true
      end if
    end if
  end if

  ' There was an error, emit an error event
  triggerErrorEvent("Connection", response.body, true)
  return false
end function

sub subscribeToChannels(getLastMessageFromHistory = false as Boolean)
  for each channel in m.CHANNELS
    ' Get the last message for this channel if configured to do so
    if getLastMessageFromHistory then history(channel)
    ' Send an attach requests for each channel
    logInfo("Attaching:", channel, "success:", attach(channel))
  end for
end sub

function history(channel as String) as Boolean
  ' Request a the last historic message for the supplied channel
  response = makeRequest(historyEndpoint(channel), { "headers": addAuthenticationToHeaders() })
  success = response.code = 200 AND isNonEmptyArray(response.body)

  if success then
    ' Process and trigger message events based on the history of the channel
    handleBody([{
      action: m.ACTIONS.MESSAGE
      channel: channel
      messages: response.body
    }])
  else
    logInfo("No history returned for channel:", channel)
  end if

  return success
end function

function attach(channel as String) as Boolean
  ' Request a subscription to the supplied channel be added to the current connection
  response = makeRequest(sendEndpoint({
    action: m.ACTIONS.ATTACH,
    channel: channel
  }), { "headers": addAuthenticationToHeaders() })
  return response.code = 201
end function

function stream() as Boolean
  ' Start the main event loop
  while NOT m.encounteredCriticalError
    ' Get the next message
    response = makeRequest(recvEndpoint(), { "headers": addAuthenticationToHeaders() })
    if response.code = 200 OR response.code = 201 then
      ' Good response, handle the body contents
      handleBody(response.body)
    else if response.code = 401 AND (response.body.error.code >= 40140 AND response.body.error.code < 40150) then
      ' https://docs.ably.io/client-lib-development-guide/features/#RSA4b
      logInfo(response.body.error.message)
      logInfo("Token expired - refreshing")
      ' Refresh the Token
      getJwtToken()
      connect()
      subscribeToChannels(false)
    else
      triggerErrorEvent("Stream", response.body, true)
      ' End the task on error by stopping the event loop
      exit while
    end if
  end while
end function

'#endregion ==== End of the REST api functions ====



'==== Endpoint functions ====
'#region - These functions are used to get and format different endpoint urls
'==== Endpoint functions ====

function requestTokenEndpoint(keyName as String) as String
  return m.ENDPOINT + "/keys/" + keyName + "/requestToken"
end function

function connectEndpoint() as String
  queries = {
    "v": "1.2",
    "stream": "false"
  }
  ' If there is a valid JWT token then we should not include the api key in the query
  if NOT isNonEmptyString(m.jwtToken) then queries["key"] = m.authenticationKey
  return appendQueriesToUri(m.ENDPOINT + "/comet/connect", queries)
end function

function historyEndpoint(channel as Object, limit = "1" as String) as String
  return appendQueriesToUri(m.ENDPOINT + "/channels/" + channel.encodeUriComponent() + "/messages", { "limit": limit })
end function

function sendEndpoint(body as Object) as String
  return appendQueriesToUri(m.ENDPOINT + "/comet/" + m.connection.connectionKey + "/send", { "body": formatJson([body]) })
end function

function recvEndpoint() as String
  return m.ENDPOINT + "/comet/" + m.connection.connectionKey + "/recv"
end function

'#endregion ==== End of the Endpoint functions ====



'==== General helper functions ====
'#region - These functions are used for a variety of general tasks
'==== General helper functions ====

sub triggerErrorEvent(context as String, messageBody as Dynamic, critical = false as Boolean)
  ' There was an error, emit an error event
  error = {
    "critical": critical
    "context": context
    "details": messageBody
  }
  if critical then
    ' In the event of a critical error execution of the task will be terminated
    m.encounteredCriticalError = true
    logError(context + ":", messageBody)
  else
    logWarn(context + ":", messageBody)
  end if

  ' Send the error information back to the client
  m.top.error = error
end sub

function addAuthenticationToHeaders(headers = {} as Object) as Object
  if isNonEmptyString(m.jwtToken) then headers["Authorization"] = "Bearer " + m.jwtToken
  return headers
end function

'#endregion ==== End of the general helper functions ====
