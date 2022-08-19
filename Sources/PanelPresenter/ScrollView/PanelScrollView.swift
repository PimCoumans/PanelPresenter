import UIKit

/// Custom scrollView that can forces touch cancellation, even in `UIControl`s
/// Also available from my [TouchCancellingScrollView.swift gist](https://gist.github.com/PimCoumans/6e82ca50a27df1d768b40fd9a73940fb).
/// - Note: Make sure to set `canCancelContentTouches` to `true`
public class PanelScrollView: UIScrollView {
	
	/// Set to `false` to allow drags in`UIControls`
	public var canCancelControlContentTouches: Bool = true
	
	/// Cancels all touches, even when touch is in  a `UIControl`.
	/// Set `alwaysCancelsContentTouches` to `false` to not use this behaviour
	public override func touchesShouldCancel(in view: UIView) -> Bool {
		if canCancelContentTouches && canCancelControlContentTouches && view is UIControl {
			return true
		}
		return super.touchesShouldCancel(in: view)
	}
}
