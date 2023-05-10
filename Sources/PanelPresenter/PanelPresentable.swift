import UIKit

/// Allows any UIViewController to use panel presenting logic
/// Typically by just creating a `PanelPresenter` instance and setting its `viewController` property to your view controller
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
///         // Your view will be added to the presenter’s scrollView
///         // so any constraints sizing your view will size the
///         // panel’s scrollView
///         let someView = UIView()
///         view.addSubview(someView)
///
///         // .. set auto layout constraints
///     }
/// }
@MainActor
public protocol PanelPresentable: UIViewController {
	/// Return an instance of `PanelPresenter` that manages the view controller’s presentation
	var panelPresenter: PanelPresenter? { get }

	/// When your content is shown in a vertically scrolling view like a `UITableView`, return that view here so the panel presenter can use its content
	/// for size calculations and apply swipe-to-dismiss logic to the scrollVie
	var panelScrollView: UIScrollView? { get }

	/// Whether the view controller allows the panel to be dismissed, return `false` to (temporarily) disable panel dismissing.
	/// Returns `true` by default
	var panelCanBeDismissed: Bool { get }
}

extension PanelPresentable {
	public var panelPresenter: PanelPresenter? { nil }
	public var panelScrollView: UIScrollView? { nil }
	public var panelCanBeDismissed: Bool { true }
}

extension UIViewController {
	/// The instance of ``PanelPresentationController`` that handles the actual panel presentation
	public var panelPresentationController: PanelPresentationController? {
		presentationController as? PanelPresentationController
	}
}
