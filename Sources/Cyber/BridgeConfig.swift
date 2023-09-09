import Foundation
import WebKit

public struct BridgeConfig {


	// MARK: - Properties

	/// This package's bundle.
	private static var _bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Bridge.self)
        #endif
    }

	public static let DEFAULT_DEV_URL = URL(string: "http://localhost:8081")!
	public static let DEFAULT_HANDLER_NAME = "Cyber"
	public static let DEFAULT_SCRIPT_URL = _bundle.url(
		forResource: "ios-native-adapter",
		withExtension: "js")!

	/// Config used when none is provided to WebView and WebViewController.
    public static var `default` = {
		var config = try! BridgeConfig(
			routes: ["*"],
			subdirectory: "dist")
		
		// Creates middleware.
		config.middlewares.append(NavigationMiddleware(config: config))
		config.middlewares.append(LoggingMiddleware(level: .all))
		
		return config
	}()

	/// WebView configuration blocks. Use these to override WKWebView default configurations per route.
	private let _routeKeysToWebViewConfigs: [String: WKWebViewConfiguration]
	private var _routeKeysToRoutes: [String: Route] = [:]

	public var handlerName: String = DEFAULT_HANDLER_NAME
	public var scriptURL: URL = DEFAULT_SCRIPT_URL

	/// Development URL, to load in DEBUG configurations, or nil to force only bundle loading.
	public let devBaseURL: URL

	/// Local (bundle or documents) URL with read access to the .html file of each route.
	public let localBaseURL: URL
	
	/// List of routes. If a wildcard route is provided, this includes the explicit routes that were expanded from the wildcard.
	public private(set) var routes: [Route] = []
	
	/// WebViews and WebViewControllers initialized with this config will use these middlewares.
	public var middlewares: [BridgeMiddleware] = []
	
	
	// MARK: - Inits
	
	public init(
		routes: [String],
		subdirectory: String,
		devBaseURL: URL = DEFAULT_DEV_URL,
		routesToWebViewConfigs: [String: WKWebViewConfiguration] = [:],
		bundle: Bundle = Bundle.main) throws {
		
		// Build the bundle URL.
		let resourcePath = bundle.resourcePath
		let localBaseURL = URL(fileURLWithPath: resourcePath!)
			.appendingPathComponent(subdirectory)
			.absoluteURL
		
		try self.init(
			routes: routes,
			localBaseURL: localBaseURL,
			devBaseURL: devBaseURL)
	}
	
	public init(
		routes: [String],
		localBaseURL: URL,
		devBaseURL: URL = DEFAULT_DEV_URL,
		routesToWebViewConfigs: [String: WKWebViewConfiguration] = [:]) throws {
		self.devBaseURL = devBaseURL
		self.localBaseURL = localBaseURL
		
		// Convert route strings to route keys.
		var routeKeysToWebViewConfigs: [String: WKWebViewConfiguration] = [:]
		for route in routesToWebViewConfigs.keys {
			routeKeysToWebViewConfigs[Route.key(for: route)] = routesToWebViewConfigs[route]
		}
		self._routeKeysToWebViewConfigs = routeKeysToWebViewConfigs
		
		// Load the routes.
		try loadRoutes(routes)
	}
	
	
	// MARK: - Functions
	
	public mutating func loadRoutes(_ routes: [String]) throws {
		if !FileManager.default.fileExists(atPath: localBaseURL.path) {
			throw CyberError.runtimeError("BridgeConfig.localBaseURL '\(localBaseURL.path)' not found")
		}
		
		// Load the routes, expanding wildcards if necessary.
		do {
			let routes = try _resolveRoutes(routes)
			self.routes = routes
		} catch {
			throw CyberError.runtimeError("BridgeConfig.routes failed to load/expand wildcards.\nError: \(error).")
		}
		
		// Build a cache of each route by its string.
		for route in self.routes {
			_routeKeysToRoutes[route.routeKey] = route
		}
		
		let invalidRoutes = self.routes.filter { !$0.localURLExists }.compactMap { $0.localURL }
		if !invalidRoutes.isEmpty {
			throw CyberError.runtimeError("Local routes missing: \(invalidRoutes)")
		}
	}
	
	func webViewConfig(for route: String) -> WKWebViewConfiguration? {
		return _routeKeysToWebViewConfigs[Route.key(for: route)]
	}
	
	func url(for route: String) -> URL? {
		let route = _routeKeysToRoutes[Route.key(for: route)]
		return route?.envURL // Local or dev URL based on build type.
	}
}

private extension BridgeConfig {
	/// Returns all routes based on this configuration. If routes is ["*"], returns one route for each .html file in `localBaseURL`.
	func _resolveRoutes(_ routes: [String]) throws -> [Route] {
		var routes = routes
		if routes == ["*"] {
			var directoryFilenames: [String] = []
			var expandedRoutes: [String] = []
			
			// Load the routes available from the bundle.
			if #available(iOS 16.0, *) {
				directoryFilenames = try FileManager.default.contentsOfDirectory(
					atPath: localBaseURL.path(percentEncoded: false))
			} else {
				directoryFilenames = try FileManager.default.contentsOfDirectory(
					atPath: localBaseURL.path)
			}
			
			// Only pick up .html files.
			for filename in directoryFilenames {
				if filename.hasSuffix(".html") {
					expandedRoutes.append(filename)
				}
			}
			
			// Overwrite the routes array with the expanded routes.
			routes = expandedRoutes
		}
		
		// Convert to route objects.
		var routeWrappers: [Route] = []
		for route in routes {
			routeWrappers.append(Route(
				route: route,
				localBaseURL: localBaseURL,
				devBaseURL: devBaseURL))
		}
			
		// Use the route wrappers.
		return routeWrappers
	}
}
