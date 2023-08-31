import WebKit

public class WebViewControllerRoute {

	// MARK: - Properties

	private lazy var _pool = InstancePool<WebViewController>(
		1,
		create: {
			return WebViewController(
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
	
	public func dequeueInstance(initialState: [String: Any]? = nil) -> WebViewController? {
		let result = _pool.dequeueInstance()
		if let state = initialState, let result = result as? Stateful {
			result.setState(state)
		}
		return result
	}
	
	public func recycleInstance(_ instance: WebViewController) {
		_pool.recycleInstance(instance)
	}
}
