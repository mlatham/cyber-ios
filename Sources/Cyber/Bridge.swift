import Foundation
import SwiftUI
import WebKit

public protocol BridgeDelegate: AnyObject {
	func didReceive(_ message: Message)
}

public protocol BridgeMiddleware: AnyObject {
	func dispatchToNative(_ message: Message)
	func dispatchToScript(_ message: Message)
}

public struct BridgeConfiguration {
	private static var _bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Bridge.self)
        #endif
    }
    
	public static let DEFAULT_HANDLER_NAME = "Cyber"
	public static let DEFAULT_SCRIPT_URL = _bundle.url(
		forResource: "ios-native-adapter",
		withExtension: "js")!

	// Development URL, to load in DEBUG configurations.
	public var devURL: URL? = URL(string: "http://localhost:8081/")

	// Local (bundle or documents) URL, for allowing read file access.
	public var localURL: URL? = nil
	
	// Remote URL. If bundle URL is missing, this URL will be loaded.
	public var remoteURL: URL? = nil
	
	public var handlerName: String = DEFAULT_HANDLER_NAME
	public var scriptURL: URL = DEFAULT_SCRIPT_URL
	
	public var url: URL? {
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
	
	public init(
		devURL: URL? = nil,
		localURL: URL? = nil,
		remoteURL: URL? = nil,
		handlerName: String = DEFAULT_HANDLER_NAME,
		scriptURL: URL = DEFAULT_SCRIPT_URL) {
		self.devURL = devURL
		self.localURL = localURL
		self.remoteURL = remoteURL
		self.handlerName = handlerName
		self.scriptURL = scriptURL
	}
}

open class Bridge: NSObject {
	private var _userScript: WKUserScript {
        let source = try! String(contentsOf: configuration.scriptURL, encoding: .utf8)
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .page)
    }
    
    private var _loadDate = Date()
    
    public var debugLoggingEnabled = false
	
	public let webView: WKWebView
	public let configuration: BridgeConfiguration
	
	public weak var delegate: BridgeDelegate?
	public var middlewares: [BridgeMiddleware] = []
	
	deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: configuration.handlerName)
    }
    
	public init(webView: WKWebView, configuration: BridgeConfiguration) {
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
    
	public func dispatchToScript(_ message: Message) {
		for middleware in middlewares {
			middleware.dispatchToScript(message)
		}
	
		let arguments: [Any?] = message.data != nil ? [message.name, message.data] : [message.name]
		_callJavaScript(function: "window.CyberNativeAdapter.dispatchToScript", arguments: arguments)
    }
    
	public func reload() {
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
