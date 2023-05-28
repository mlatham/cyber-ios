import WebKit

public enum MessageType: String {
	case pageLoaded
	case pageLoadFailed
	case errorRaised
	case log
	case navigate
	case navigateBack
	case navigateBackToRoot
	case present
	case dismiss
}

public struct Message {
    public let name: String
    public let data: [String: Any]?
    
    /// Milliseconds since unix epoch as provided by JavaScript Date.now().
    public var timestamp: TimeInterval {
        data?["timestamp"] as? TimeInterval ?? 0
    }
    
    public var date: Date {
        Date(timeIntervalSince1970: timestamp / 1000.0)
    }
    
    public var type: MessageType? {
		return MessageType(rawValue: name)
	}
	
	public var jsonString: String? {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: self.asDictionary(), options: [.sortedKeys]) else {
			return nil
		}
        
        return String(data: jsonData, encoding: .utf8)
	}

	public init(name: String, data: [String: Any]? = nil) {
		self.name = name
		self.data = data
	}
	
	public init?(message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
            let name = body["name"] as? String,
            let data = body["data"] as? [String: Any]
        else {
            return nil
        }
        
        self.init(name: name, data: data)
    }
	
	public func asDictionary() -> [String: Any] {
		var result: [String: Any] = ["name": self.name]
		if let data = self.data {
			result["data"] = data
		}
		return result
	}
}
