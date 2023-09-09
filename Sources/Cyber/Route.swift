import Foundation

public struct Route {
	public let route: String
	public let routeDotHtml: String
	public let routeKey: String
	
	public let localURL: URL
	public let devURL: URL
	
	public var envURL: URL {
#if DEBUG
		return devURL
#else
		return url
#endif
	}
	
	public var localURLExists: Bool {
		return FileManager.default.fileExists(atPath: localURL.path)
	}
		
	public init(route: String, localBaseURL: URL, devBaseURL: URL) {
		// Ensure the route key includes the .html extension.
		self.routeDotHtml = Route.addHtmlExtensionIfNeeded(route)
		self.routeKey = self.routeDotHtml
		self.route = route
		
		// The URL includes the .html extensions.
		self.localURL = localBaseURL.appendingPathComponent(routeDotHtml)
		self.devURL = devBaseURL.appendingPathComponent(routeDotHtml)
	}
	
	public static func key(for route: String) -> String {
		return addHtmlExtensionIfNeeded(route)
	}
	
	public static func addHtmlExtensionIfNeeded(_ route: String) -> String {
		return !route.hasSuffix(".html")
			? route.appending(".html")
			: route
	}
}
