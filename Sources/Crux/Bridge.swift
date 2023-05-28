import Foundation
import SwiftUI
import WebKit

protocol BridgeDelegate: AnyObject {
	func didReceive(_ message: Message)
}

protocol BridgeMiddleware: AnyObject {
	func dispatchToNative(_ message: Message)
	func dispatchToScript(_ message: Message)
}

open class BridgeConfiguration {
	private static var _bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Bridge.self)
        #endif
    }
    
	static let DEFAULT_HANDLER_NAME = "crux"
	static let DEFAULT_SCRIPT_URL = _bundle.url(forResource: "ios-native-adapter", withExtension: "js")!

	// Development URL, to load in DEBUG configurations.
	var devURL: URL? = URL(string: "http://localhost:8081/")

	// Local (bundle or documents) URL, for allowing read file access.
	var localURL: URL? = nil
	
	// Remote URL. If bundle URL is missing, this URL will be loaded.
	var remoteURL: URL? = nil
	
	var handlerName: String = DEFAULT_HANDLER_NAME
	var scriptURL: URL = DEFAULT_SCRIPT_URL
	
	var url: URL? {
#if DEBUG
		if let devURL = devURL {
			return devURL
		}
#endif
		if let localURL = localURL {
			return localURL
		} else if let remoteURL = remoteURL {
			return remoteURL
		}
		
		return nil
	}
}

open class Bridge: NSObject {
	private var _userScript: WKUserScript {
        let source = try! String(contentsOf: configuration.scriptURL, encoding: .utf8)
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .page)
    }
    
    private var _loadDate = Date()
    
    var debugLoggingEnabled = false
	
	let webView: WKWebView
	let configuration: BridgeConfiguration
	
	weak var delegate: BridgeDelegate?
	var middlewares: [BridgeMiddleware] = []
	
	deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: configuration.handlerName)
    }
    
	init(webView: WKWebView, configuration: BridgeConfiguration) {
        self.configuration = configuration
        self.webView = webView
        
#if DEBUG
		if #available(iOS 16.4, *) {
			self.webView.isInspectable = true
		}
#endif
        
        super.init()
        
        _setup()
    }
    
	func dispatchToScript(_ message: Message) {
		for middleware in middlewares {
			middleware.dispatchToScript(message)
		}
	
		let arguments: [Any?] = message.data != nil ? [message.name, message.data] : [message.name]
		_callJavaScript(function: "window.CruxNativeAdapter.dispatchToScript", arguments: arguments)
    }
    
	func reload() {
		_loadDate = Date()
	
#if DEBUG
		if let devURL = self.configuration.devURL {
			let request = URLRequest(url: devURL)
			webView.load(request)
			return
		}
#endif
		if let localURL = self.configuration.localURL {
			webView.loadFileURL(localURL, allowingReadAccessTo: localURL)
			let request = URLRequest(url: localURL)
			webView.load(request)
		} else if let remoteURL = self.configuration.remoteURL {
			let request = URLRequest(url: remoteURL)
			webView.load(request)
		}
	}
}

extension Bridge: WKNavigationDelegate {
	public func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
		Logger.log(.debug, "\(self.configuration.url?.absoluteString ?? ""): Loaded in \(fabs(_loadDate.timeIntervalSinceNow) * 1000) ms")
	}
}

extension Bridge: WKScriptMessageHandler {
	public func userContentController(
		_ userContentController: WKUserContentController,
		didReceive message: WKScriptMessage) {
		switch (message.name) {
		case configuration.handlerName:
			if let scriptMessage = Message(message: message) {
				for middleware in middlewares {
					middleware.dispatchToNative(scriptMessage)
				}
				
				delegate?.didReceive(scriptMessage)
			}
		default:
			break
		}
	}
}

private extension Bridge {
	func _setup() {
        webView.configuration.userContentController.addUserScript(_userScript)
        webView.configuration.userContentController.add(self, name: configuration.handlerName)
        webView.navigationDelegate = self
        
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

        webView.evaluateJavaScript(script, in: nil, in: .page) { result in
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

struct JavaScriptExpression {
    let function: String
    let arguments: [Any?]
    
    var string: String? {
        guard let encodedArguments = _encode(arguments: arguments) else { return nil }
        return "\(function)(\(encodedArguments))"
    }
    
    var wrappedString: String? {
        guard let encodedArguments = _encode(arguments: arguments) else { return nil }
        return _wrap(function: function, encodedArguments: encodedArguments)
    }
    
	private func _wrap(function: String, encodedArguments arguments: String) -> String {
        """
        (function(result) {
          try {
            result.value = \(function)(\(arguments))
          } catch (error) {
            result.error = error.toString()
            result.stack = error.stack
          }
        
          return result
        })({})
        """
    }
    
    private func _encode(arguments: [Any?]) -> String? {
        let arguments = arguments.map { $0 == nil ? NSNull() : $0! }
        
        guard let data = try? JSONSerialization.data(withJSONObject: arguments),
            let string = String(data: data, encoding: .utf8) else {
                return nil
        }
        
        // Strip leading/trailing [] so we have a list of arguments suitable for inserting between parens
        return String(string.dropFirst().dropLast())
    }
}
