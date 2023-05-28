import Foundation
import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
	let webView: WKWebView
    let bridge: Bridge
    
    init(configuration: BridgeConfiguration, webViewConfiguration: WKWebViewConfiguration? = nil) {
		let webViewConfiguration = webViewConfiguration ?? {
			let configuration = WKWebViewConfiguration()
			configuration.preferences.isTextInteractionEnabled = false
			return configuration
		}()
		
		webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
		bridge = Bridge(webView: webView, configuration: configuration)
	}
    
    func makeUIView(context: Context) -> WKWebView  {
        return self.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    func dispatchToScript(_ message: Message) {
		self.bridge.dispatchToScript(message)
    }
}

struct WebViewControllerRepresentable: UIViewControllerRepresentable {
	typealias UIViewControllerType = WebViewController
	
	let webViewController: WebViewController
	
	init(configuration: BridgeConfiguration, webViewConfiguration: WKWebViewConfiguration? = nil) {
		webViewController = WebViewController(
			configuration: configuration,
			webViewConfiguration: webViewConfiguration)
	}
	
	func makeUIViewController(context: Context) -> WebViewController {
		return webViewController
	}
	
	func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
	}
	
    func dispatchToScript(_ message: Message) {
		self.webViewController.dispatchToScript(message)
    }
}
