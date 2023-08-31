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

open class NavigationMiddleware: BridgeMiddleware {

	// MARK: - Properties

	public var debugLoggingEnabled = false

	public let viewController: UIViewController
	public let pool: WebViewControllerPool


	// MARK: - Inits

	public init(viewController: UIViewController, pool: WebViewControllerPool) {
		self.viewController = viewController
		self.pool = pool
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
			let navigationController = viewController.navigationController,
			let destinationController = pool.dequeueInstance(for: route, initialState: message.data) else {
			return
		}
		
		navigationController.pushViewController(destinationController, animated: message.animated)
	}
	
	private func _navigateBack(_ message: Message) {
		guard let navigationController = viewController.navigationController else {
			return
		}
	
		navigationController.popViewController(animated: message.animated)
	}
	
	private func _navigateBackToRoot(_ message: Message) {
		guard let navigationController = viewController.navigationController else {
			return
		}
	
		navigationController.popToRootViewController(animated: message.animated)
	}
	
	private func _present(_ message: Message) {
		guard let route = message.destination,
			let destinationController = pool.dequeueInstance(for: route, initialState: message.data) else {
			return
		}
	
		viewController.present(destinationController, animated: message.animated)
	}
	
	private func _dismiss(_ message: Message) {
		viewController.dismiss(animated: message.animated)
	}
}
