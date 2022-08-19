import UIKit

/// Uses KVO to watch for `contentSize`, `frame` and `contentOffset` on the set ``scrollView``, so just a way to get scrollView updates without setting a delegate
class ScrollViewObserver {
	var scrollView: UIScrollView? { didSet {
		updateObservers()
	}}
	
	var didUpdate: ((UIScrollView) -> Void)?
	
	private var scrollContentSizeObserver: NSKeyValueObservation?
	private var scrollFrameObserver: NSKeyValueObservation?
	private var scrollContentOffsetObserver: NSKeyValueObservation?
	private var safeAreaInsetsObserver: NSKeyValueObservation?
}

private extension ScrollViewObserver {
	func updateObservers() {
		scrollContentSizeObserver = scrollView?.observe(\.contentSize, options: [.old, .new]) { [weak self] scrollView, change in
			guard change.oldValue != change.newValue else {
				return
			}
			self?.didUpdate?(scrollView)
		}
		
		scrollFrameObserver = scrollView?.observe(\.bounds, options: [.old, .new]) { [weak self] scrollView, change in
			guard change.oldValue?.size != change.newValue?.size else {
				return
			}
			self?.didUpdate?(scrollView)
		}
		
		scrollContentOffsetObserver = scrollView?.observe(\.contentOffset, options: [.old, .new]) { [weak self] scrollView, change in
			guard change.oldValue != change.newValue else {
				return
			}
			self?.didUpdate?(scrollView)
		}
		
		safeAreaInsetsObserver = scrollView?.observe(\.safeAreaInsets, options: [.old, .new]) { [weak self] scrollView, change in
			guard change.oldValue?.bottom != change.newValue?.bottom else {
				return
			}
			self?.didUpdate?(scrollView)
		}
	}
}
