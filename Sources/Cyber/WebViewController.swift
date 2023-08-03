import Foundation
import WebKit

open class WebViewController: UIViewController {
	public let webView: WebView

	public init(
		bridgeConfig: BridgeConfiguration,
		webViewConfig: WKWebViewConfiguration? = nil) {
		webView = WebView(
			frame: .zero,
			bridgeConfig: bridgeConfig,
			webViewConfig: webViewConfig)
		
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
		webView.dispatchToScript(message)
    }
}
