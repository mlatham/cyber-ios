import Foundation
import WebKit

public protocol Stateful {
	func setState(_ state: [String: Any])
}

public protocol Route {
	var key: String { get }
	func controller(initialState: [String: Any]?) -> UIViewController?
}

public protocol RecyclableRoute: Route {
	func recycle(controller: UIViewController)
}

public class GenericRoute<T> where T : UIViewController {
	public let key: String
	
	public init(key: String) {
		self.key = key
	}
	
	public func controller(initialState: [String: Any]?) -> T? {
		let result = T.init()
		if let state = initialState, let result = result as? Stateful {
			result.setState(state)
		}
		return result
	}
}

public class WebViewRoute: GenericRoute<WebViewController>, RecyclableRoute {
	private lazy var _pool = InstancePool<WebViewController>(
		1,
		create: {
			let configuration = BridgeConfiguration(
				devURL: self.devURL,
				localURL: self.localURL,
				remoteURL: self.remoteURL)
			return WebViewController(
				configuration: configuration,
				webViewConfiguration: self.webViewConfiguration)
		})
	
	public let webViewConfiguration: WKWebViewConfiguration?
	public let remoteURL: URL?
	public let localURL: URL?
	public let devURL: URL?
	
	public init(
		key: String,
		webViewConfiguration: WKWebViewConfiguration? = nil,
		remoteURL: URL? = nil,
		localURL: URL? = nil,
		devURL: URL? = nil) {
		self.webViewConfiguration = webViewConfiguration
		self.remoteURL = remoteURL
		self.localURL = localURL
		self.devURL = devURL
		
		super.init(key: key)
	}
	
	public func controller(initialState: [String: Any]?) -> UIViewController? {
		let result = _pool.dequeueInstance()
		if let state = initialState, let result = result as? Stateful {
			result.setState(state)
		}
		return result
	}
	
	public func recycle(controller: UIViewController) {
		if let webViewController = controller as? WebViewController {
			_pool.recycleInstance(webViewController)
		}
	}
}

open class Router {
	public let routes: [String: Route]

	public init(routes: [Route]) {
		var routesDictionary: [String: Route] = [:]
		for route in routes {
			routesDictionary[route.key] = route
		}
		self.routes = routesDictionary
	}
	
	public func controller(for key: String, initialState: [String: Any]?) -> UIViewController? {
		guard let route = routes[key] else {
			return nil
		}
		
		return route.controller(initialState: initialState)
	}

	public func recycle(controller: UIViewController, for key: String) {
		if let pool = routes[key] as? RecyclableRoute {
			pool.recycle(controller: controller)
		}
	}
}
