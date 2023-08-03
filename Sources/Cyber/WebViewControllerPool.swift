import Foundation
import WebKit

public class WebViewControllerRoute {
	private lazy var _pool = InstancePool<WebViewController>(
		1,
		create: {
			let bridgeConfig = BridgeConfiguration(
				devURL: self.devURL,
				localURL: self.localURL)
			return WebViewController(
				bridgeConfig: bridgeConfig,
				webViewConfig: self.webViewConfig)
		})
	
	public let webViewConfig: WKWebViewConfiguration?
	public let localURL: URL?
	public let devURL: URL?
	
	public init(
		webViewConfig: WKWebViewConfiguration? = nil,
		localURL: URL? = nil,
		devURL: URL? = nil) {
		self.webViewConfig = webViewConfig
		self.localURL = localURL
		self.devURL = devURL
	}
	
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

open class WebViewControllerPool {
	public let routes: [String: WebViewControllerRoute]

	public init(
		bundleBasePath: String,
		devBaseURL: String,
		routes: [String],
		routeToConfig: ((String) -> (WKWebViewConfiguration))? = nil) {
		var routesDictionary: [String: WebViewControllerRoute] = [:]
		for route in routes {
			let devURL = URL(string: "\(devBaseURL)/\(route)")
			let localURL = URL(string: "\(bundleBasePath)/\(route))")
			
			routesDictionary[route] = WebViewControllerRoute(
				webViewConfig: routeToConfig?(route) ?? nil,
				localURL: localURL,
				devURL: devURL)
		}
		self.routes = routesDictionary
	}
	
	func webViewConfig(for route: String) -> WKWebViewConfiguration? {
		return nil
	}
	
	func dequeueInstance(for route: String, initialState: [String: Any]? = nil) -> WebViewController? {
		guard let route = routes[route] else {
			return nil
		}
		
		return route.dequeueInstance(initialState: initialState)
	}
	
	func recycleInstance(_ instance: WebViewController, for route: String) {
		routes[route]?.recycleInstance(instance)
	}
}
