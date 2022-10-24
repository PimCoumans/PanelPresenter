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
	
	/// Return an instance of `PanelPresenter` that manages the view controller‘s presentation
	var panelPresenter: PanelPresenter { get }
	
	/// Override to provide your own scroll view to use for dismissing logic.
	var panelScrollView: UIScrollView { get }
	
	/// Set an additional top inset from the screen‘s top.
	/// Default value is `10`
	var panelTopInset: CGFloat { get }
	
	/// Whether the view controller allows the panel to be dismissed, return `false` to (temporarily) disable panel dismissing.
	/// Default value is `true`
	var panelCanBeDismissed: Bool { get }
	
	/// Returning `true` disables auto-resizing and keeps the panel‘s top below the safe area insets and ``panelTopInset``.
	/// Default value is `false`
	///
	/// When changing the value returned here, make sure to call `panelPresenter.updatePanelHeight(animated:)`
	/// or call `panelPresenter.layoutIfNeeded()` from your own animation logic
	var panelExtendsToFullHeight: Bool { get }
	
	/// Whether the tint mode of the presenting view controller‘s view should be changed when presented,
	/// Default value is `true`
	var shouldAdjustPresenterTintMode: Bool { get }
}

extension PanelPresentable {
	public var panelScrollView: UIScrollView { panelPresenter.panelScrollView }
	public var panelTopInset: CGFloat { 10 }
	public var panelCanBeDismissed: Bool { true }
	public var panelExtendsToFullHeight: Bool { false }
	public var shouldAdjustPresenterTintMode: Bool { true }
	
	public var headerContentView: UIView { panelPresenter.headerContentView }
}

public extension UIViewController {
	/// The panel presenter that presented this view controller, `nil` if not presented by any panel presenter
	var presentingPanelPresenter: PanelPresenter? {
		transitioningDelegate as? PanelPresenter
	}
}
