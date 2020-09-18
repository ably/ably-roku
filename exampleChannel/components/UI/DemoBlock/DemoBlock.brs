sub init()
	m.top.observeField("time", "onUpdate")
	m.updateAnimation = m.top.findNode("updateAnimation")
end sub

sub onUpdate()
	m.updateAnimation.control = "stop"
	m.updateAnimation.control = "start"
end sub
