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

	public static let DEFAULT_HANDLER_NAME = "Cyber"
	public static let DEFAULT_SCRIPT_URL = _bundle.url(
		forResource: "ios-native-adapter",
		withExtension: "js")!

	/// Config used when none is provided to WebView and WebViewController.
    public static var `default` = try? BridgeConfig(
		routes: ["*"],
		subdirectory: "dist")

	/// WebView configuration blocks. Use these to override WKWebView default configurations per route.
	private let _routesToWebViewConfigs: [String: WKWebViewConfiguration]
	private var _routeURLs: [String: URL] = [:]

	public var handlerName: String = DEFAULT_HANDLER_NAME
	public var scriptURL: URL = DEFAULT_SCRIPT_URL

	/// Development URL, to load in DEBUG configurations, or nil to force only bundle loading.
	public var devBaseURL: URL? = URL(string: "http://localhost:8081")

	/// Local (bundle or documents) URL with read access to the .html file of each route.
	public var localBaseURL: URL
	
	/// List of routes. If a wildcard route is provided, this includes the explicit routes that were expanded from the wildcard.
	public let routes: [String]
	
	/// Base URL used for building routes.
	public var baseURL: URL? {
#if DEBUG
		if let devBaseURL = devBaseURL {
			return devBaseURL
		}
#endif
		return localBaseURL
	}
	
	
	// MARK: - Inits
	
	public init(
		routes: [String],
		subdirectory: String,
		routesToWebViewConfigs: [String: WKWebViewConfiguration] = [:],
		bundle: Bundle = Bundle.main) throws {
		
		// Build the bundle URL.
		let resourcePath = bundle.resourcePath
		let localBaseURL = URL(fileURLWithPath: resourcePath!)
			.appendingPathComponent(subdirectory)
			.absoluteURL
		
		try self.init(
			routes: routes,
			localBaseURL: localBaseURL)
	}
	
	public init(
		routes: [String],
		localBaseURL: URL,
		routesToWebViewConfigs: [String: WKWebViewConfiguration] = [:]) throws {
		self.localBaseURL = localBaseURL
		self._routesToWebViewConfigs = routesToWebViewConfigs
		
		if !FileManager.default.fileExists(atPath: localBaseURL.path) {
			throw CyberError.runtimeError("BridgeConfig.localBaseURL '\(localBaseURL.path)' not found")
		}
		
		// Load the routes, expanding wildcards if necessary.
		do {
			let routes = try BridgeConfig._resolveRoutes(routes, baseURL: localBaseURL)
			self.routes = routes
		} catch {
			throw CyberError.runtimeError("BridgeConfig.routes failed to load/expand wildcards.\nError: \(error).")
		}
		
		// Build a cache of each route URL.
		for route in self.routes {
			let routeDotHtml = BridgeConfig._addHtmlExtensionIfNeeded(route)
			let routeURL = baseURL?.appendingPathComponent(routeDotHtml)
			_routeURLs[routeDotHtml] = routeURL
		}
		
		let invalidRoutes = BridgeConfig._invalidRoutes(routeURLs: Array(_routeURLs.values))
		if !invalidRoutes.isEmpty {
			throw CyberError.runtimeError("Routes invalid: \(invalidRoutes)")
		}
	}
	
	
	// MARK: - Functions
	
	func webViewConfig(for route: String) -> WKWebViewConfiguration? {
		let routeDotHtml = BridgeConfig._addHtmlExtensionIfNeeded(route)
		return _routesToWebViewConfigs[routeDotHtml]
	}
	
	func localURL(for route: String) -> URL? {
		return _routeURLs[BridgeConfig._addHtmlExtensionIfNeeded(route)]
	}
}

private extension BridgeConfig {
	/// Ensures routes have an .html suffix.
	static func _addHtmlExtensionIfNeeded(_ route: String) -> String {
		if !route.hasSuffix(".html") {
			return route.appending(".html")
		}
		return route
	}
	
	/// Returns all routes based on this configuration. If routes is ["*"], returns one route for each .html file in `localBaseURL`.
	static func _resolveRoutes(_ routes: [String], baseURL: URL) throws -> [String] {
		guard routes != ["*"] else {
			return routes
		}
			
		var directoryFilenames: [String] = []
		var expandedRoutes: [String] = []
		
		// Load the routes available from the bundle.
		if #available(iOS 16.0, *) {
			directoryFilenames = try FileManager.default.contentsOfDirectory(
				atPath: baseURL.path(percentEncoded: false))
		} else {
			directoryFilenames = try FileManager.default.contentsOfDirectory(
				atPath: baseURL.path)
		}
		
		// Only pick up .html files.
		for filename in directoryFilenames {
			if filename.hasSuffix(".html") {
				expandedRoutes.append(filename)
			}
		}
		
		// Use the expanded routes.
		return expandedRoutes
	}
	
	/// Returns an array of any routes that aren't present in the bundle.
	static func _invalidRoutes(routeURLs: [URL]) -> [String] {
		var invalidRoutes = [String]()
	
		for routeURL in routeURLs {
			// Check that each route's path exists in the bundle.
			if !FileManager.default.fileExists(atPath: routeURL.path) {
				invalidRoutes.append(routeURL.path)
			}
		}
		
		return invalidRoutes
	}
}
