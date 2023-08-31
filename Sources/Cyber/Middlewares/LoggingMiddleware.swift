import Foundation

public extension Message {
	var logLevel: LogLevel {
		data?["log_level"] as? LogLevel ?? .debug
	}
}

open class LoggingMiddleware: BridgeMiddleware {

	// MARK: - Properties

	public let level: LogLevel
	
	
	// MARK: - Inits
	
	public init(level: LogLevel? = nil) {
#if DEBUG
		self.level = level ?? .debug
#else
		self.level = level ?? .error
#endif
	}
	
	
	// MARK: - Functions

	public func dispatchToNative(_ message: Message) {
		if message.type == .log {
			_log(message.logLevel, message)
		} else if message.type == .errorRaised {
			_log(.error, message)
		} else if level.rawValue <= LogLevel.trace.rawValue {
			_log(.trace, "[Script → Native]", message)
		}
	}
	
	public func dispatchToScript(_ message: Message) {
		if level.rawValue <= LogLevel.trace.rawValue {
			_log(.trace, "[Native → Script]", message)
		}
	}
	
	private func _log(_ level: LogLevel, _ message: Message) {
		_log(level, nil, message)
	}
	
	private func _log(_ level: LogLevel, _ extra: String?, _ message: Message) {
		if level.rawValue < self.level.rawValue {
			return
		}
		
		var extraString = ""
		if let extra = extra {
			extraString = "\(extra) "
		}
		let message = "\(extraString)\(message.jsonString ?? "")"
		Logger.log(level, message)
	}
}
