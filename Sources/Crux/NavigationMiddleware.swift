import UIKit

public protocol Initializable {
	init(parameters: [String: Any])
}

open class Router {
	public var routes: [String: UIViewController.Type] = [:]

	public init(routes: [String: UIViewController.Type]) {
		self.routes = routes
	}

	public func destination(for route: String, parameters: [String: Any]?) -> UIViewController? {
		guard let type = routes[route] else {
			return nil
		}
		
		if let initializableType = type as? Initializable.Type {
			// Pass parameters if this is initializable.
			return initializableType.init(parameters: parameters ?? [:]) as? UIViewController
			
		} else {
			// Initialize without parameters.
			return type.init()
		}
	}
}

extension Message {
	public var destination: String? {
		return data?["destination"] as? String
	}
	
	public var animated: Bool {
		return data?["animated"] as? Bool ?? true
	}
}

open class NavigationMiddleware: BridgeMiddleware {
	public var debugLoggingEnabled = false

	public let viewController: UIViewController
	public let router: Router

	public init(viewController: UIViewController, router: Router) {
		self.viewController = viewController
		self.router = router
	}
	
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
			let destinationController = router.destination(for: route, parameters: message.data) else {
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
			let destinationController = router.destination(for: route, parameters: message.data) else {
			return
		}
	
		viewController.present(destinationController, animated: message.animated)
	}
	
	private func _dismiss(_ message: Message) {
		viewController.dismiss(animated: message.animated)
	}
}
