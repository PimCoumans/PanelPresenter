import UIKit

public extension UIScrollView {
	
	/// Adds adjustedContentInset to offset so offset aligns with actual scrollable area
	var relativeContentOffset: CGPoint {
		get {
			CGPoint(
				x: contentOffset.x + adjustedContentInset.left,
				y: contentOffset.y + adjustedContentInset.top
			)
		}
		set {
			contentOffset = CGPoint(
				x: newValue.x - adjustedContentInset.left,
				y: newValue.y - adjustedContentInset.top
			)
		}
	}
	
	private var pointPrecision: CGFloat { 1 / UIScreen.main.scale }
	
	/// Content sits at top offset or is scroll-bouncing at top
	var isAtTop: Bool {
		let offset = relativeContentOffset.y
		return offset < 0 || abs(offset) < pointPrecision
	}
	
	/// Wether given location is withing scrollView's content
	func isPointInScrollContent(_ point: CGPoint) -> Bool {
		guard self.point(inside: point, with: nil) else {
			return false
		}
		return CGRect(origin: .zero, size: contentSize).contains(point)
	}
	
	/// If content should be able to scroll without bouncing
	var contentExeedsBounds: Bool {
		let viewHeight = bounds.inset(by: adjustedContentInset).height
		return contentSize.height - viewHeight > pointPrecision
	}
}

public extension UIScrollView {
	/// Immediately halts scrolling and clamps offset to scrollable bounds
	/// - Returns: Relative change in vertical offset after clamping
	@discardableResult
	func stopVerticalScrolling() -> CGFloat {
		var contentOffset = self.contentOffset
		contentOffset.y = max(-adjustedContentInset.top, contentOffset.y)
		let contentHeight = contentSize.height + adjustedContentInset.bottom
		contentOffset.y = min(max(-adjustedContentInset.top, contentHeight - bounds.height), contentOffset.y)
		let difference = contentOffset.y - self.contentOffset.y
		setContentOffset(contentOffset, animated: false)
		return difference
	}
}
