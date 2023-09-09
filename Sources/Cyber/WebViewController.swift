import Foundation
import WebKit

open class WebViewController: UIViewController {

	// MARK: - Properties

	public let webView: WebView
	
	public var bridge: Bridge {
		return webView.bridge
	}
	
	public weak var delegate: BridgeDelegate? {
		get { return bridge.delegate }
		set { bridge.delegate = newValue }
	}
	
	
	// MARK: - Inits

	public init(
		route: String,
		bridgeConfig: BridgeConfig = BridgeConfig.default,
		webViewConfig: WKWebViewConfiguration? = nil) {
		webView = WebView(
			route: route,
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
		
		super.init(nibName: nil, bundle: nil)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("Not supported")
	}
	
	
	// MARK: - Functions
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(webView)
		activateWebViewConstraints()
	}
	
	public func activateWebViewConstraints() {
		webView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
	}
	
	public func load(route: String) {
		webView.load(route: route)
	}
	
	public func dispatchToScript(_ message: Message) {
		webView.dispatchToScript(message)
    }
}
