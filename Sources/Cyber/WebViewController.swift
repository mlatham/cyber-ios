import Foundation
import WebKit

open class WebViewController: UIViewController {
	public let webView: WKWebView
	public let bridge: Bridge

	public init(configuration: BridgeConfiguration, webViewConfiguration: WKWebViewConfiguration? = nil) {
		let webViewConfiguration = webViewConfiguration ?? {
			let configuration = WKWebViewConfiguration()
			configuration.preferences.isTextInteractionEnabled = false
			return configuration
		}()
	
		webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
		bridge = Bridge(webView: webView, configuration: configuration)
		
		super.init(nibName: nil, bundle: nil)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("Not supported")
	}
	
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
	
	public func dispatchToScript(_ message: Message) {
		self.bridge.dispatchToScript(message)
    }
}
