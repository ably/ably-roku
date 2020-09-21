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


'==== Url helper functions ====
'#region - These functions are used to manipulate, validate, and query urls
'==== Url helper functions ====

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

'#endregion ==== End of the url helper functions ====


'==== General helper functions ====
'#region - These functions are used for a variety of general tasks
'==== General helper functions ====

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
