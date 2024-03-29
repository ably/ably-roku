sub Main(inputArguments as object)
  if NOT runTests() then
    screen = createObject("roSGScreen")
    m.port = createObject("roMessagePort")
    screen.setMessagePort(m.port)
    scene = screen.CreateScene("MainScene")
    screen.show()
    scene.observeField("appExit", m.port)
    scene.setFocus(true)

    ' Get an api key for demonstration purposes and send it to the main scene
    scene.ablyApiKey = getAuthenticationKey()
  end if

  while true
    msg = wait(0, m.port)
    msgType = type(msg)

    if msgType = "roSGScreenEvent" then
      if msg.isScreenClosed() then
        return
      else if msgType = "roSGNodeEvent" then
        field = msg.getField()
        if field = "appExit" then
          return
        end if
      end if
    end if
  end while
end sub

function runTests() as Boolean
  if type(Rooibos_init) = "Function" then
    Rooibos_init() 'bs:disable-line
    return false
  else
    print "Rooibos not found. Running as sample channel"
    return false
  end if
end function

' Gets an api key from the demos endpoint
function getAuthenticationKey() as String
  transferObject = createObject("roUrlTransfer")
  transferObject.setCertificatesFile("common:/certs/ca-bundle.crt")
  transferObject.initClientCertificates()
  transferObject.retainBodyOnError(true)
  transferObject.setUrl("https://www.ably.io/ably-auth/api-key/demos")
  response = transferObject.getToString()
  return response
end function
