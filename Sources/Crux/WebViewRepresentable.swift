import Foundation
import SwiftUI
import WebKit

public struct WebViewRepresentable: UIViewRepresentable {
	public let webView: WKWebView
    public let bridge: Bridge
    
    public init(configuration: BridgeConfiguration, webView: WKWebView) {
		self.webView = webView
		self.bridge = Bridge(webView: webView, configuration: configuration)
	}
    
    public init(configuration: BridgeConfiguration, webViewConfiguration: WKWebViewConfiguration? = nil) {
		let webViewConfiguration = webViewConfiguration ?? {
			let configuration = WKWebViewConfiguration()
			configuration.preferences.isTextInteractionEnabled = false
			return configuration
		}()
		
		self.init(
			configuration: configuration,
			webView: WKWebView(frame: .zero, configuration: webViewConfiguration))
	}
    
    public func makeUIView(context: Context) -> WKWebView  {
        return self.webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    public func dispatchToScript(_ message: Message) {
		self.bridge.dispatchToScript(message)
    }
}

public struct WebViewControllerRepresentable: UIViewControllerRepresentable {
	public typealias UIViewControllerType = WebViewController
	
	public let webViewController: WebViewController
	
	public init(webViewController: WebViewController) {
		self.webViewController = webViewController
	}
	
	public init(configuration: BridgeConfiguration, webViewConfiguration: WKWebViewConfiguration? = nil) {
		self.webViewController = WebViewController(
			configuration: configuration,
			webViewConfiguration: webViewConfiguration)
	}
	
	public func makeUIViewController(context: Context) -> WebViewController {
		return webViewController
	}
	
	public func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
	}
	
    public func dispatchToScript(_ message: Message) {
		self.webViewController.dispatchToScript(message)
    }
}
