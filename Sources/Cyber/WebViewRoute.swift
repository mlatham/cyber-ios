import WebKit

public class WebViewRoute {

	// MARK: - Properties

	private lazy var _pool = InstancePool<WebView>(
		1,
		create: {
			return WebView(
				route: self.route,
				bridgeConfig: self.config)
		})
	
	public let route: String
	public let config: BridgeConfig
	
	
	// MARK: - Inits
	
	public init(
		route: String,
		config: BridgeConfig) {
		self.route = route
		self.config = config
	}
	
	
	// MARK: - Functions
	
	public func dequeueInstance(initialState: [String: Any]? = nil) -> WebView? {
		let result = _pool.dequeueInstance()
		if let state = initialState, let result = result as? Stateful {
			result.setState(state)
		}
		return result
	}
	
	public func recycleInstance(_ instance: WebView) {
		_pool.recycleInstance(instance)
	}
}
