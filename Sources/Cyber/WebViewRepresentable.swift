import Foundation
import SwiftUI
import WebKit

public struct WebViewRepresentable: UIViewRepresentable {

	// MARK: - Properties

	public let webView: WebView
	
	public var bridge: Bridge {
		return webView.bridge
	}
	
	public weak var delegate: BridgeDelegate? {
		get { return webView.delegate }
		set { webView.delegate = newValue }
	}
	
	
	// MARK: - Inits
    
	public init(webView: WebView) {
		self.webView = webView
	}
    
    public init(
		route: String,
		bridgeConfig: BridgeConfig = BridgeConfig.default,
		webViewConfig: WKWebViewConfiguration? = nil) {
		self.webView = WebView(
			route: route,
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
	}
	
	
	// MARK: - Functions
    
    public func makeUIView(context: Context) -> WKWebView  {
        return self.webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    public func load(route: String) {
		webView.load(route: route)
	}
    
    public func dispatchToScript(_ message: Message) {
		webView.dispatchToScript(message)
    }
}
