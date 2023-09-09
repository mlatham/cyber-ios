import UIKit
import WebKit

extension Message {
	public var destination: String? {
		return data?["destination"] as? String
	}
	
	public var animated: Bool {
		return data?["animated"] as? Bool ?? true
	}
}

extension UIApplication {
	var keyWindow: UIWindow? {
		// Get connected scenes.
		return self.connectedScenes
			// Keep only active scenes, onscreen and visible to the user.
			.filter { $0.activationState == .foregroundActive }
			// Keep only the first `UIWindowScene`.
			.first(where: { $0 is UIWindowScene })
			// Get its associated windows.
			.flatMap({ $0 as? UIWindowScene })?.windows
			// Finally, keep only the key window.
			.first(where: \.isKeyWindow)
	}
}

open class NavigationMiddleware: BridgeMiddleware {

	// MARK: - Properties

	public var debugLoggingEnabled = false

	public let pool: WebViewControllerPool
	public let viewController: UIViewController?

	var currentViewController: UIViewController? {
		return viewController ?? UIApplication.shared.keyWindow?.rootViewController
	}


	// MARK: - Inits

	public init(config: BridgeConfig, viewController: UIViewController? = nil) {
		self.pool = WebViewControllerPool(config: config)
		self.viewController = viewController
	}
	

	// MARK: - Functions
	
	public func dispatchToNative(_ message: Message) {
		switch message.type {
		case .navigate:
			_navigate(message)
		case .navigateBack:
			_navigateBack(message)
		case .navigateBackToRoot:
			_navigateBackToRoot(message)
		case .present:
			_present(message)
		case .dismiss:
			_dismiss(message)
		default:
			break
		}
	}
	
	public func dispatchToScript(_ message: Message) {
	}

	private func _navigate(_ message: Message) {
		guard let route = message.destination,
			let navigationController = currentViewController?.navigationController,
			let destinationController = pool.dequeueInstance(for: route, initialState: message.data) else {
			return
		}
		
		navigationController.pushViewController(destinationController, animated: message.animated)
	}
	
	private func _navigateBack(_ message: Message) {
		guard let navigationController = currentViewController?.navigationController else {
			return
		}
	
		navigationController.popViewController(animated: message.animated)
	}
	
	private func _navigateBackToRoot(_ message: Message) {
		guard let navigationController = currentViewController?.navigationController else {
			return
		}
	
		navigationController.popToRootViewController(animated: message.animated)
	}
	
	private func _present(_ message: Message) {
		guard let route = message.destination,
			let destinationController = pool.dequeueInstance(for: route, initialState: message.data) else {
			return
		}
	
		currentViewController?.present(destinationController, animated: message.animated)
	}
	
	private func _dismiss(_ message: Message) {
		currentViewController?.dismiss(animated: message.animated)
	}
}
