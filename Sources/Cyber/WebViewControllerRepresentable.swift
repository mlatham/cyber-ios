import Foundation
import SwiftUI
import WebKit

public struct WebViewControllerRepresentable: UIViewControllerRepresentable {
	public typealias UIViewControllerType = WebViewController
	
	public let webViewController: WebViewController
	
	public init(webViewController: WebViewController) {
		self.webViewController = webViewController
	}
	
	public init(bridgeConfig: BridgeConfiguration, webViewConfig: WKWebViewConfiguration? = nil) {
		self.webViewController = WebViewController(
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
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
