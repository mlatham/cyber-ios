import Foundation
import os

enum LogLevel: Int, CustomStringConvertible {
	case error = 50
	case warn = 40
	case info = 30
	case debug = 20
	case trace = 10
	case all = 0
	
	var description : String {
		switch self {
		case .error: return "ERROR"
		case .warn: return "WARN"
		case .info: return "INFO"
		case .debug: return "DEBUG"
		case .trace: return "TRACE"
		default: return "DEBUG"
		}
	}
	
	var osLogLevel: OSLogType {
		switch self {
		case .error: return .error
		case .warn: return .info
		case .info: return .info
		case .debug, .trace: return .debug
		default: return .debug
		}
	}
}

class Logger {
	private static let _logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "crux")
	
	static func log(_ level: LogLevel, _ message: String) {
		_logger.log(level: level.osLogLevel, "\(message)")
	}
	
	static func logIf(_ condition: Bool, _ level: LogLevel, _ message: String) {
		guard condition else {
			return
		}
		_logger.log(level: level.osLogLevel, "\(message)")
	}
}