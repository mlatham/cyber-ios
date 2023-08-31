public protocol BridgeDelegate: AnyObject {
	func didReceive(_ message: Message)
}
