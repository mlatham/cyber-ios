public protocol BridgeMiddleware: AnyObject {
	func dispatchToNative(_ message: Message)
	func dispatchToScript(_ message: Message)
}
