import Foundation
import SwiftUI
import WebKit

public struct WebViewControllerRepresentable: UIViewControllerRepresentable {

	// MARK: - Properties

	public typealias UIViewControllerType = WebViewController
	
	public let webViewController: WebViewController
	
	public var bridge: Bridge {
		return webViewController.bridge
	}
	
	public weak var delegate: BridgeDelegate? {
		get { return webViewController.delegate }
		set { webViewController.delegate = newValue }
	}
	
	
	// MARK: - Inits
	
	public init(webViewController: WebViewController) {
		self.webViewController = webViewController
	}
	
	public init(
		route: String,
		bridgeConfig: BridgeConfig = BridgeConfig.default!,
		webViewConfig: WKWebViewConfiguration? = nil) {
		self.webViewController = WebViewController(
			route: route,
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
	}
	
	
	// MARK: - Functions
	
	public func makeUIViewController(context: Context) -> WebViewController {
		return webViewController
	}
	
	public func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
	}
	
	public func load(route: String) {
		self.webViewController.load(route: route)
	}
	
    public func dispatchToScript(_ message: Message) {
		self.webViewController.dispatchToScript(message)
    }
}
