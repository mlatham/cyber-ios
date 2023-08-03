import Foundation
import SwiftUI
import WebKit

public struct WebViewRepresentable: UIViewRepresentable {
	public let webView: WebView
    
	public init(webView: WebView) {
		self.webView = webView
	}
    
    public init(
		bridgeConfig: BridgeConfiguration,
		webViewConfig: WKWebViewConfiguration? = nil) {
		self.webView = WebView(
			frame: .zero,
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
	}
    
    public func makeUIView(context: Context) -> WKWebView  {
        return self.webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    public func dispatchToScript(_ message: Message) {
		webView.dispatchToScript(message)
    }
}
