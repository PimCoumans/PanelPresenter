import UIKit

/// Allows any UIViewController to use panel presenting logic
/// Typically just creating a `PanelPresenter` instance and setting its `viewController` property to your view controller
///
/// Basic implementation:
/// ```
/// class MyViewController: UIViewController, PanelPresentable {
///
///     let panelPresenter = PanelPresenter()
///
///     init() {
///         super.init(nibName: nil, bundle: nil)
///         panelPresenter.viewController = self
///     }
///
///     func viewDidLoad() {
///         super.viewDidLoad()
///
///         // Your view will be added to `panelPresenter.contentView`
///         // so any constraints sizing your view will size the
///         // panel‘s scrollView
///         let someView = UIView()
///         view.addSubview(someView)
///
///         // .. set auto layout constraints
///     }
/// }

public protocol PanelPresentable: UIViewController {
	var panelPresenter: PanelPresenter { get }
	
	/// Override to provide your own scroll view to use for dismissing logic
	var panelScrollView: UIScrollView { get }
	
	/// Set an additional top inset from the screen‘s top
	var panelTopInset: CGFloat { get }
	
	var shouldAdjustPresenterTintMode: Bool { get }
}

extension PanelPresentable {
	public var panelScrollView: UIScrollView { panelPresenter.panelScrollView }
	public var panelTopInset: CGFloat { 10 }
	public var shouldAdjustPresenterTintMode: Bool { true }
	
	public var headerContentView: UIView { panelPresenter.headerContentView }
}

public extension UIViewController {
	var presentingPanelPresenter: PanelPresenter? {
		transitioningDelegate as? PanelPresenter
	}
}
