import Foundation

open class InstancePool<T> {
	private var _instances: [T] = []
	
	private var _create: () -> T
	private var _recycle: (T) -> Void
	
	public init(
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
	
	public func dequeueInstance() -> T {
		if _instances.count > 0 {
			return _instances.removeFirst()
		}
		return _create()
	}
	
	public func recycleInstance(_ instance: T) {
		_recycle(instance)
		_instances.append(instance)
	}
}
