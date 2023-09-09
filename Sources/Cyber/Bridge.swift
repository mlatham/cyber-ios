import Foundation
import SwiftUI
import WebKit

open class Bridge: NSObject {

	// MARK: - Properties

	private var _userScript: WKUserScript {
        let source = try! String(contentsOf: config.scriptURL, encoding: .utf8)
        return WKUserScript(
			source: source,
			injectionTime: .atDocumentEnd,
			forMainFrameOnly: true,
			in: .page)
    }
    
    private var _reloadStartDate = Date()
    
    public var debugLoggingEnabled = false
	
	public weak var webView: WKWebView?
	public let config: BridgeConfig
	public var route: String
	
	public weak var delegate: BridgeDelegate?
	
	
	// MARK: - Inits
	
	deinit {
        webView?
			.configuration
			.userContentController
			.removeScriptMessageHandler(
				forName: config.handlerName)
    }
    
	public init(
		webView: WKWebView,
		route: String,
		config: BridgeConfig) {
        self.webView = webView
        self.route = route
        self.config = config
        
#if DEBUG
		if #available(iOS 16.4, *) {
			self.webView?.isInspectable = true
		}
#endif
        
        super.init()
        
        _setup()
    }
    
    
    // MARK: - Functions
    
	public func dispatchToScript(_ message: Message) {
		for middleware in config.middlewares {
			middleware.dispatchToScript(message)
		}
	
		let arguments: [Any?] = message.data != nil ? [message.name, message.data] : [message.name]
		_callJavaScript(function: "window.CyberNativeAdapter.dispatchToScript", arguments: arguments)
    }
    
    public func load(route: String) {
		self.route = route
		reload()
	}
    
	public func reload() {
		_reloadStartDate = Date()
		
		guard let url = self.config.localURL(for: route) else {
			Logger.log(.error, "\(self.route): Not found")
			return
		}
		
		let request = URLRequest(url: url)
		webView?.load(request)
	}
}


// MARK: - WKNavigationDelegate

extension Bridge: WKNavigationDelegate {
	public func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
		Logger.log(.debug, "\(self.route): Loaded in \(fabs(_reloadStartDate.timeIntervalSinceNow) * 1000) ms")
	}
}


// MARK: - WKScriptMessageHandler

extension Bridge: WKScriptMessageHandler {
	public func userContentController(
		_ userContentController: WKUserContentController,
		didReceive message: WKScriptMessage) {
		switch (message.name) {
		case config.handlerName:
			if let scriptMessage = Message(message: message) {
				for middleware in config.middlewares {
					middleware.dispatchToNative(scriptMessage)
				}
				
				delegate?.didReceive(scriptMessage)
			}
		default:
			break
		}
	}
}


// MARK: - Helper Functions

private extension Bridge {
	func _setup() {
        webView?.configuration.userContentController.addUserScript(_userScript)
        webView?.configuration.userContentController.add(self, name: config.handlerName)
        webView?.navigationDelegate = self
        
        reload()
    }
    
    func _callJavaScript(function: String, arguments: [Any?] = []) {
        let expression = JavaScriptExpression(function: function, arguments: arguments)
        
        guard let script = expression.wrappedString else {
            Logger.log(.error, "Error formatting JavaScript expression \(function)")
            return
        }
        
        let debug = debugLoggingEnabled
        Logger.logIf(debug, .trace, "[Native → Script] \(expression.string ?? "")")

        webView?.evaluateJavaScript(script, in: nil, in: .page) { result in
            Logger.logIf(debug, .trace, "[Native → Script] evaluation complete:\n\(expression.string ?? "")")
            
            switch result {
			case .success(let result):
				if let result = result as? [String: Any],
					let error = result["error"] as? String,
					let stack = result["stack"] as? String {
					Logger.logIf(debug, .trace, "Error evaluating JavaScript function \(function): \(error)\n\(stack)")
				} else {
					// Handle success?
				}
			case .failure(let error):
				Logger.log(.error, "\(dump(error))")
			}
        }
    }
}
