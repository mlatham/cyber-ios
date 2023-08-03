import Foundation
import WebKit

open class WebView: WKWebView {
	private var _bridge: Bridge? = nil
	public var bridge: Bridge {
		return _bridge!
	}
	
	public init(
		frame: CGRect,
		bridgeConfig: BridgeConfiguration,
		webViewConfig: WKWebViewConfiguration? = nil) {
		let webViewConfig = webViewConfig ?? {
			let configuration = WKWebViewConfiguration()
			configuration.preferences.isTextInteractionEnabled = false
			return configuration
		}()
	
		super.init(frame: frame, configuration: webViewConfig)
	
		// Initialize the bridge.
		_bridge = Bridge(webView: self, configuration: bridgeConfig)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("Not supported")
	}

	public func dispatchToScript(_ message: Message) {
		_bridge?.dispatchToScript(message)
    }
}
