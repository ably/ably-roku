'@SGNode AblyTaskTests
'@TestSuite [AT] AblyTask

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests the AblyTask logical functions
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@BeforeEach
sub AT__BeforeEach()
	m.node.ENDPOINT = Invalid
end sub

'@Test connectEndpoint
'@Params["https://rest.ably.io/comet", "https://rest.ably.io/comet/connect"]
'@Params["test", "test/connect"]
sub AT__connectEndpoint(inputEndpoint as String, expectedEndpoint as String)
	m.assertNotInvalid(m.node)
	m.node.ENDPOINT = inputEndpoint
	m.assertEqual(connectEndPoint(), expectedEndpoint)
end sub
