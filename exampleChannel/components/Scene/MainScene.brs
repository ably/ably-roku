sub init()
  m.ablyTask = createObject("roSGNode", "AblyTask")
  m.ablyTask.channel = "[product:ably-bitflyer/bitcoin]bitcoin:jpy"
  m.ablyTask.observeField("messages", "onMessages")
  m.ablyTask.observeField("error", "onError")
  m.ablyTask.observeField("connected", "onConnected")
  m.ablyTask.control = "RUN"
end sub

sub onMessages(event as Object)
  print "---------------- onMessages ----------------"
  messages = event.getData()
  for each message in messages
    print message
  end for
end sub

sub onError(event as Object)
  print "------------------ onError -----------------"
  print event.getData()
end sub

sub onConnected(event as Object)
  print "--------------- onConnected ----------------"
  print event.getData()
end sub
