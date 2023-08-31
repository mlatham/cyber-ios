import Foundation

enum CyberError: Error {
    case runtimeError(_ message: String, _ code: Int = 0)
}
