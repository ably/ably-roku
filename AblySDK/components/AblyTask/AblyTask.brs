
sub init()
  m.top.functionName = "runTask"
  m.ACTIONS = {
    HEARTBEAT: 0,
    DISCONNECTED: 6,
    CLOSE: 7,
    ATTACH: 10,
    ATTACHED: 11,
    MESSAGE: 15
  }
  m.headers = {
    "Accept": "application/json"
    "Content-Type": "application/json"
  }

  m.MAXIMUM_LOG_LEVEL = 5
end sub

sub runTask()
  topValues = m.top.getFields()
  m.ENDPOINT = topValues.endpoint
  m.CHANNEL = topValues.channel
  m.KEY = getConnectionKey()
  m.logLevel = m.top.logLevel
  if m.logLevel > m.MAXIMUM_LOG_LEVEL then m.logLevel = m.MAXIMUM_LOG_LEVEL

  logInfo(m.KEY)
  m.connectionKey = ""
  if NOT isNonEmptyString(m.KEY) then return

  if connect() then
    if attach() then
      while true
        stream()
        sleep(20)
      end while
    end if
  end if
end sub

function connect() as Boolean
  response = makeRequest(connectEndpoint(), Invalid, "GET", m.headers)
  if response.code = 200 then
    if isNonEmptyArray(response.body) then
      firstEntry = response.body[0]
      if isNonEmptyAA(firstEntry) AND isNonEmptyAA(firstEntry.connectionDetails) then
        connectionDetails = firstEntry.connectionDetails
        m.connectionKey = connectionDetails.connectionKey
        m.top.connected = connectionDetails
        return true
      end if
    end if
  end if
  return false
end function

function attach() as Boolean
  response = makeRequest(sendEndpoint(attachParameters()))
  return response.code = 201
end function

sub stream()
  response = makeRequest(recvEndpoint())
  if response.code = 200 OR response.code = 201 then
    handleBody(response.body)
  else
    logError(response.body)
    m.top.error = response
  end if
end sub

sub handleBody(body)
  for each protocolMessage in body
    if isNumber(protocolMessage.action) then
      action = protocolMessage.action
      if m.ACTIONS.HEARTBEAT = action then
        ' /* nothing to do */
        logVerbose("heartbeat")
      else if m.ACTIONS.ATTACHED = action then
        ' /* TODO: handle any attach errors */
        logInfo("attached")
      else if m.ACTIONS.MESSAGE = action then
        messages = []
        for each message in protocolMessage.messages
          messages.push(message)
          logVerbose("message:", message)
        end for
        m.top.messages = messages
      else if m.ACTIONS.DISCONNECTED = action then
        logInfo("disconnected")
      end if
    end if
  end for
end sub

function getConnectionKey() as String
  response = makeRequest("https://www.ably.io/ably-auth/api-key/demos", Invalid)
  if response.code = 200 AND isNonEmptyString(response.body) then
    return response.body
  else
    m.top.error = response
    return ""
  end if
end function

function connectEndpoint() as String
  return m.endpoint + "connect"
end function

function sendEndpoint(body as Object) as String
  return appendQueriesToUri(m.endpoint + m.connectionKey + "/send", { "body": formatJson([body]) })
end function

function recvEndpoint() as String
  return m.endpoint + m.connectionKey + "/recv"
end function

function getDefaultQueryParams() as Object
  return {
    v: "1.2",
    key: m.KEY,
    stream: "false"
  }
end function

function attachParameters() as Object
  return {
    action: m.ACTIONS.ATTACH,
    channel: m.CHANNEL
  }
end function

function createNewUrlTransfer(messagePort as Object) as Object
  transferObject = createObject("roUrlTransfer")
  transferObject.setPort(messagePort)
  transferObject.enableEncodings(true)
  transferObject.retainBodyOnError(true)
  ' transferObject.setMinimumTransferRate(2147483647, m.timeout)
  return transferObject
end function

function makeRequest(url as String, body = Invalid as Dynamic, method = "GET" as String, headers = Invalid as Dynamic, cookies = Invalid as Dynamic, certificateFile = "common:/certs/ca-bundle.crt" as String) as Object
  url = urlProxy(appendQueriesToUri(url, getDefaultQueryParams()))
  messagePort = createObject("roMessagePort")
  transferObject = createNewUrlTransfer(messagePort)
  transferObject.setUrl(url)

  response = {
    "ok": false
    "code": 0
    "body": Invalid
    "headers": {}
    "messageDetails": ""
    "url": url
  }

  ' Make sure the Url was correctly set.... This can fail due to bad encoding...
  if url = transferObject.getUrl() then
    transferObject.setCertificatesFile(certificateFile)
    transferObject.initClientCertificates()

    if isNonEmptyAA(headers) then transferObject.setHeaders(headers)

    if isNonEmptyAA(cookies) then
      transferObject.enableCookies()
      transferObject.addCookies(cookies)
    else
      transferObject.clearCookies()
    end if

    transferObject.setRequest(method)

    if isAA(body) OR isArray(body) then
      ok = transferObject.asyncPostFromString(formatJson(body))
    else if isString(body) then
      ok = transferObject.asyncPostFromString(body)
    else
      ok = transferObject.asyncGetToString()
    end if
  else
    ok = false
  end if

  response.ok = ok

  if NOT ok then
    return response
  else
    while true
      message = getMessage(messagePort)
      if message <> Invalid then
        if isUrlEvent(message) then return processResponse(message, transferObject)
      end if
    end while
  end if
end function

function processResponse(message as Object, transferObject as Object) as Object
  code = message.getResponseCode()
  body = message.getString()
  headers = message.getResponseHeaders()
  requestUrl = transferObject.getUrl()
  ' Was there a curl error?
  ok = code >= 0

  if isNonEmptyString(body) then
    contentType = ""
    if isNonEmptyAA(headers) AND isNonEmptyString(headers["content-type"]) then contentType = headers["content-type"]
    if stringIncludes(contentType, "application/json") then
      bodyAsObject = parseJson(body)
      if isNotInvalid(bodyAsObject) then
        body = bodyAsObject
      end if
    end if
  else
    body = Invalid
  end if

  return {
    "ok": ok
    "code": message.getResponseCode()
    "body": body
    "headers": headers
    "messageDetails": message.getFailureReason()
    "url": requestUrl
  }
end function
