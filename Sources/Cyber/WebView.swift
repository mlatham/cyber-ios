import Foundation
import WebKit

open class WebView: WKWebView {

	// MARK: - Properties
	
	public static let DEFAULT_WEBVIEW_CONFIG: WKWebViewConfiguration = {
		let config = WKWebViewConfiguration()
		config.preferences.isTextInteractionEnabled = false
		return config
	}()

	private var _bridge: Bridge? = nil
	public var bridge: Bridge {
		return _bridge!
	}
	
	public weak var delegate: BridgeDelegate? {
		get { return _bridge?.delegate }
		set { _bridge?.delegate = newValue }
	}
	
	
	// MARK: - Inits
	
	public init(
		route: String,
		bridgeConfig: BridgeConfig = BridgeConfig.default,
		webViewConfig: WKWebViewConfiguration? = nil,
		frame: CGRect = CGRect.zero) {
		let webViewConfig = webViewConfig
			?? bridgeConfig.webViewConfig(for: route)
			?? WebView.DEFAULT_WEBVIEW_CONFIG
	
		super.init(frame: frame, configuration: webViewConfig)
	
		// Initialize the bridge.
		_bridge = Bridge(webView: self, route: route, config: bridgeConfig)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("Not supported")
	}
	
	
	// MARK: - Functions
	
	public func load(route: String) {
		_bridge?.load(route: route)
	}

	public func dispatchToScript(_ message: Message) {
		_bridge?.dispatchToScript(message)
    }
}
