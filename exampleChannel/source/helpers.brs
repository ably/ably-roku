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


function forceStrSize(value as string, size as Integer, endChr = Chr(10))
	newValue = value
	if len(value) > size then
		newValue = left(value, size) + endChr
	else if endChr <> Chr(10) then
		newValue = value + String(size - len(value), " ") + endChr
	else
		newValue = value + endChr
	end if
	return newValue
end function

function getTime(isoString as String, withSeconds = false as Boolean) as String
  date = createObject("roDateTime")
	date.FromISO8601String(isoString)
	date.toLocalTime()
	currentHourOfDay = date.getHours()

	' Get the Meridiem value
	if currentHourOfDay > 11 then
		meridiem = " " + "PM"
	else
		meridiem = " " + "AM"
	end if

	' Prepare 12 hour values
	currentTwelveHour = currentHourOfDay MOD 12
	if currentHourOfDay = 0 OR currentHourOfDay = 12 then currentTwelveHour = 12
	twelveHourSimple = currentTwelveHour.ToStr()

	' Prepare minutes
	minutes = date.getMinutes()
	minutesTwoDigit = paddedString(minutes)

	' Prepare seconds
	seconds = date.getSeconds()
	secondsTwoDigit = paddedString(seconds)

	if NOT withSeconds then return substitute("{0}:{1}{2}", twelveHourSimple, minutesTwoDigit, meridiem)
	return substitute("{0}:{1}:{2}{3}", twelveHourSimple, minutesTwoDigit, secondsTwoDigit, meridiem)
end function

function paddedString(value as Dynamic, padLength = 2 as Integer, paddingCharacter = "0" as Dynamic) as String
	value = toString(value)
	while value.len() < padLength
		value = paddingCharacter + value
	end while
	return value
end function

function toString(value as Dynamic) as String
	if isString(value) then return value
	if isNumber(value) then return numberToString(value)
	if isNode(value) then return nodeToString(value)
	if isBoolean(value) then return booleanToString(value)
	if isAA(value) then return aaToString(value)
	if isArray(value) then return arrayToString(value)
	return ""
end function

function numberToString(value as Dynamic) as String
	return value.toStr()
end function

function nodeToString(node as Object) as String
	if NOT isNode(node) then return ""

	description = node.subtype()
	if node.isSubtype("Group") then
		id = node.id
		if id <> "" then
			description += " (" + id + ")" + aaToString(nodeToAA(node))
		end if
	end if
	return description
end function

function booleanToString(bool as Boolean) as String
	if bool then return "true"
	return "false"
end function

function aaToString(aa as Object) as String
	description = "{"
	for each key in aa
		description += key + ": " + toString(aa[key]) + ", "
	end for
	description = description.left(description.len() - 2) + "}"
	return description
end function

function arrayToString(array as Object) as String
	description = "["
	for each item in array
		description += toString(item) + ", "
	end for
	description = description.left(description.len() - 2) + "]"
	return description
end function

function nodeToAA(value as Object, removeId = false as Boolean, removeFields = [] as Object) as Object
	if isNode(value) then
		fields = value.getFields()
		fields.delete("change")
		fields.delete("focusable")
		fields.delete("focusedChild")
		fields.delete("ready")
		if removeId then fields.delete("id")
		'Looping through any additional fields if passed.
		if isNonEmptyArray(removeFields) then
			for each field in removeFields
				fields.delete(field)
			end for
		end if
		return fields
	else if isAA(value) then
		return value
	end if

	return {}
end function
