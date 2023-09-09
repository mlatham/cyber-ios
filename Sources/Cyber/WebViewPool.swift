import Foundation
import WebKit

open class WebViewPool {

	// MARK: - Properties

	public let config: BridgeConfig
	public let routes: [String: WebViewRoute]


	// MARK: - Inits

	public init(config: BridgeConfig = BridgeConfig.default) {
		var routesDictionary: [String: WebViewRoute] = [:]
		for route in config.routes {
			routesDictionary[route] = WebViewRoute(
				route: route,
				config: config)
		}
		self.routes = routesDictionary
		self.config = config
	}
	
	
	// MARK: - Functions
	
	func webViewConfig(for route: String) -> WKWebViewConfiguration? {
		return config.webViewConfig(for: route)
	}
	
	func dequeueInstance(for route: String, initialState: [String: Any]? = nil) -> WebView? {
		guard let route = routes[route] else {
			return nil
		}
		
		return route.dequeueInstance(initialState: initialState)
	}
	
	func recycleInstance(_ instance: WebView, for route: String) {
		routes[route]?.recycleInstance(instance)
	}
}
