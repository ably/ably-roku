#const PROXY = false

'==== Type validation functions ====
'#region - These functions are used to help limit the possibilities of type miss match errors
'==== Type validation functions ====

function isString(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "String") OR (valueType = "roString")
end function

function isNonEmptyString(value as Dynamic) as Boolean
	return isString(value) AND value <> ""
end function

function isBoolean(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Boolean") OR (valueType = "roBoolean")
end function

function isArray(value as Dynamic) as Boolean
	return type(value) = "roArray"
end function

function isNonEmptyArray(value as Dynamic) as Boolean
	return (isArray(value) AND NOT value.isEmpty())
end function

function isInteger(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Integer") OR (valueType = "roInt") OR (valueType = "roInteger") OR (valueType = "LongInteger")
end function

function isFloat(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Float") OR (valueType = "roFloat")
end function

function isDouble(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Double") OR (valueType = "roDouble") OR (valueType = "roIntrinsicDouble")
end function

function isNumber(obj as Dynamic) as Boolean
	if (isInteger(obj)) then return true
	if (isFloat(obj)) then return true
	if (isDouble(obj)) then return true
	return false
end function

function isAA(value as Dynamic) as Boolean
	return type(value) = "roAssociativeArray"
end function

function isNonEmptyAA(value as Dynamic) as Boolean
	return (isAA(value) AND NOT value.isEmpty())
end function

function isNode(value as Dynamic, subType = "" as String) as Boolean
	if type(value) <> "roSGNode" then return false
	if subType <> "" then return value.isSubtype(subType)
	return true
end function

function isUrlEvent(value as Dynamic) as Boolean
	return (type(value) = "roUrlEvent")
end function

function isKeyedValueType(value as Dynamic) as Boolean
	return getInterface(value, "ifAssociativeArray") <> Invalid
end function

function isFunction(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "roFunction") OR (valueType = "Function")
end function

function isInvalid(value as Dynamic) as Boolean
	return NOT isNotInvalid(value)
end function

function isNotInvalid(value as Dynamic) as Boolean
	return (type(value) <> "<uninitialized>" AND value <> Invalid)
end function

'#endregion ==== End of the type validation functions ====


'==== Network and Url helper functions ====
'#region - These functions are used to manipulate, validate, and query urls as well as sending network requests
'==== Network and Url helper functions ====

' @description Makes a network request.
' @param {AssociativeArray} url - The URL to be used for the transfer request.
' @property {AssociativeArray} requestOptions - An object containing items like body, or headers.
' @param {AssociativeArray|Array|String} [requestOptions.body] - The request body. AAs and Arrays will be automatically converted to json.
' @param {String} [requestOptions.certificateFile] - A path to a certificate File. Default is "common:/certs/ca-bundle.crt".
' @param {AssociativeArray[]} [requestOptions.cookies] - Cookies should be an Array of AssociativeArrays. Each AA should be in the same format as the AAs returned by [getCookie()]{@link https://developer.roku.com/en-ca/docs/references/brightscript/interfaces/ifhttpagent.md#getcookiesdomain-as-string-path-as-string-as-object}. The specified cookies are added to the cookie cache.
' @param {AssociativeArray} [requestOptions.headers] - An object of key value pairs to be used as headers.
' @param {String} [requestOptions.method] - A HTTP method string. Supported values are: "GET", "HEAD", "POST"
' @property {AssociativeArray} [requestOptions.queries] - An object of key value pairs to be used as query parameters.
' @return {TransferInfo} Returns a transfer info object with details about the request.
function makeRequest(url as String, requestOptions as Object) as Object

  ' Request defaults
  options = {
    body: Invalid
    certificateFile: "common:/certs/ca-bundle.crt"
    cookies: Invalid
    headers: Invalid
    method: "GET"
    queries: Invalid
  }

  ' Override the default options with the incoming options
  options.append(requestOptions)

  if isNonEmptyAA(options.queries) then url = appendQueriesToUri(url, options.queries)

  url = urlProxy(url)
  messagePort = createObject("roMessagePort")
  transferObject = createNewUrlTransfer(messagePort)
  transferObject.setUrl(url)

  ' Make sure the Url was correctly set.... This can fail due to bad encoding...
  if url = transferObject.getUrl() then
    if isNonEmptyString(options.certificateFile) then
      transferObject.setCertificatesFile(options.certificateFile)
      transferObject.initClientCertificates()
    end if

    if isNonEmptyAA(options.headers) then transferObject.setHeaders(options.headers)

    if isNonEmptyAA(options.cookies) then
      transferObject.enableCookies()
      transferObject.addCookies(options.cookies)
    else
      transferObject.clearCookies()
    end if

    if isNonEmptyString(options.method) then transferObject.setRequest(options.method)

    body = options.body
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

  if NOT ok then
    return {
      "ok": ok
      "code": 0
      "body": Invalid
      "headers": {}
      "messageDetails": ""
      "url": url
    }
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

  if ok AND isNonEmptyString(body) then
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

function createNewUrlTransfer(messagePort as Object) as Object
  transferObject = createObject("roUrlTransfer")
  transferObject.setPort(messagePort)
  transferObject.enableEncodings(true)
  transferObject.retainBodyOnError(true)
  ' transferObject.setMinimumTransferRate(2147483647, m.timeout)
  return transferObject
end function

function urlProxy(url as string) as string
  #if PROXY
    if left(url, 4) <> "http" then return url
    ' This address is <HOST_RUNNING_CHARLES>:<CHARLES_PORT>
    proxyAddress = "192.168.8.185:8888"

    ' Make sure we have not already formatted this url
    ' This can lead to a recursive address
    if not url.inStr(proxyAddress) > -1 then
      if url <> invalid and proxyAddress <> invalid
        proxyPrefix = "http://" + proxyAddress + "/;"
        currentUrl = url

        ' Double check again. You really don't want a recursive address
        if currentUrl.inStr(proxyPrefix) = 0 then
          return url
        end if

        ' Combine the addresses together resulting in the following format:
        ' <HOST_RUNNING_CHARLES>:<CHARLES_PORT>;<ORIGINAL_ADDRESS>
        proxyUrl = proxyPrefix + currentUrl
        return proxyUrl
      end if
    end if
  #end if

  return url
end function

function appendQueriesToUri(uri as String, queryParameters = Invalid as Dynamic) as String
	if isNonEmptyString(uri) AND isNonEmptyAA(queryParameters) then
		first = (0 = Instr(0, uri, "?"))

		for each key in queryParameters
			value = queryParameters[key]

			if isNonEmptyString(value) then
				if first then
					uri += "?"
					first = false
				else
					uri += "&"
				end if

				uri += (key.encodeUriComponent() + "=" + value.encodeUriComponent())
			end if
		end for
	end if

	return uri
end function

'#endregion ==== End of the Network and Url helper functions ====


'==== General helper functions ====
'#region - These functions are used for a variety of general tasks
'==== General helper functions ====

function stringToBase64(value as String) as String
	byteArray = createObject("roByteArray")
	byteArray.fromAsciiString(value)
	return byteArray.toBase64String()
end function

sub getMessage(messagePort as Object, sleepInterval = 20 as Integer) as Dynamic
	message = messagePort.getMessage()
	if message = Invalid then sleep(sleepInterval)
	return message
end sub

function stringIncludes(value as String, subString as String) as Boolean
	return stringIndexOf(value, subString) > -1
end function

function stringIndexOf(value as String, subString as String) as Integer
	return value.Instr(subString)
end function

'#endregion ==== End of the general helper functions ====


'==== Logging functions ====
'#region - These functions are used logging events based on the current log level
'==== Logging functions ====

'log statements under the VERBOSE label and log level
sub logVerbose(param1 as Dynamic, param2 = "nil", param3 = "nil", param4 = "nil", param5 = "nil", param6 = "nil", param7 = "nil", param8 = "nil", param9 = "nil", param10 = "nil")
	logAny([param1, param2, param3, param4, param5, param6, param7, param8, param9, param10], 5)
end sub

'log statements under the DEBUG label and log level
sub logDebug(param1 as Dynamic, param2 = "nil", param3 = "nil", param4 = "nil", param5 = "nil", param6 = "nil", param7 = "nil", param8 = "nil", param9 = "nil", param10 = "nil")
	logAny([param1, param2, param3, param4, param5, param6, param7, param8, param9, param10], 4)
end sub

'log statements under the INFO label and log level
sub logInfo(param1 as Dynamic, param2 = "nil", param3 = "nil", param4 = "nil", param5 = "nil", param6 = "nil", param7 = "nil", param8 = "nil", param9 = "nil", param10 = "nil")
	logAny([param1, param2, param3, param4, param5, param6, param7, param8, param9, param10], 3)
end sub

'log statements under the WARN label and log level
sub logWarn(param1 as Dynamic, param2 = "nil", param3 = "nil", param4 = "nil", param5 = "nil", param6 = "nil", param7 = "nil", param8 = "nil", param9 = "nil", param10 = "nil")
	logAny([param1, param2, param3, param4, param5, param6, param7, param8, param9, param10], 2)
end sub

'log statements under the ERROR label and log level
sub logError(param1 as Dynamic, param2 = "nil", param3 = "nil", param4 = "nil", param5 = "nil", param6 = "nil", param7 = "nil", param8 = "nil", param9 = "nil", param10 = "nil")
	logAny([param1, param2, param3, param4, param5, param6, param7, param8, param9, param10], 1)
end sub

'log statements under the INFO label and log level
sub logAny(paramArr as Object, level as Integer)
	if NOT createObject("roAppInfo").IsDev() then return
	logLevel = m.logLevel
	if logLevel < level then return

	filtered = []
	for each item in paramArr
		if NOT (isString(item) AND item = "nil") then filtered.push(item)
	end for

	if level = 1 then
		levelInfo = "ERROR]"
	else if level = 2 then
		levelInfo = "WARN]"
	else if level = 3 then
		levelInfo = "INFO]"
	else if level = 4 then
		levelInfo = "DEBUG]"
	else
		levelInfo = "VERBOSE]"
	end if

	logStr = mid(createObject("roDateTime").toISOString(), 12, 5) + " | [Ably-" + levelInfo

	print logStr; tab(23); " | ";
	for each item in filtered
		print item; " ";
	end for
	print ""
end sub

'#endregion ==== End of the logging functions ====
