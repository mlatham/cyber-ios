import Foundation
import WebKit

class WebViewController: UIViewController {
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
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("Not supported")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(webView)
		activateWebViewConstraints()
	}
	
	func activateWebViewConstraints() {
		webView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
	}
	
	func dispatchToScript(_ message: Message) {
		self.bridge.dispatchToScript(message)
    }
}
