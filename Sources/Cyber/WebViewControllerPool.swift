import Foundation
import WebKit

open class WebViewControllerPool {

	// MARK: - Properties

	public let config: BridgeConfig
	public let routes: [String: WebViewControllerRoute]


	// MARK: - Inits

	public init(config: BridgeConfig = BridgeConfig.default) {
		var routesDictionary: [String: WebViewControllerRoute] = [:]
		for route in config.routes {
			routesDictionary[route.routeKey] = WebViewControllerRoute(
				route: route.route,
				config: config)
		}
		self.routes = routesDictionary
		self.config = config
	}
	
	
	// MARK: - Functions
	
	func webViewConfig(for route: String) -> WKWebViewConfiguration? {
		return config.webViewConfig(for: Route.key(for: route))
	}
	
	func dequeueInstance(for route: String, initialState: [String: Any]? = nil) -> WebViewController? {
		guard let route = routes[Route.key(for: route)] else {
			return nil
		}
		
		return route.dequeueInstance(initialState: initialState)
	}
	
	func recycleInstance(_ instance: WebViewController, for route: String) {
		routes[Route.key(for: route)]?.recycleInstance(instance)
	}
}
