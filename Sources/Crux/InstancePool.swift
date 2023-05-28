import Foundation

class InstancePool<T> {
	private var _instances: [T] = []
	
	private var _create: () -> T
	private var _recycle: (T) -> Void
	
	init(
		_ initialCount: Int,
		create: @escaping () -> T,
		recycle: @escaping (T) -> Void) {
		_create = create
		_recycle = recycle
		
		DispatchQueue.global(qos: .userInitiated).async {
			for _ in 0...initialCount {
				DispatchQueue.main.async {
					self._instances.append(self._create())
				}
			}
		}
	}
	
	func dequeueInstance() -> T {
		if _instances.count > 0 {
			return _instances.removeFirst()
		}
		return _create()
	}
	
	func recycleInstance(_ instance: T) {
		_recycle(instance)
		_instances.append(instance)
	}
}
