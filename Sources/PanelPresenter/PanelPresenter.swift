import UIKit
import ConstraintBuilder

public final class PanelPresenter: NSObject {
	/// Set the view controller to apply panel behavior to
	public weak var viewController: UIViewController? { didSet {
		if oldValue?.transitioningDelegate === self {
			oldValue?.transitioningDelegate = nil
		}
		viewController?.modalPresentationStyle = .custom
		viewController?.transitioningDelegate = self
	}}

	/// Presents attached view controller
	/// - Parameter presentingViewController: View controller to present from
	/// This method is provided as a convenience to present from an externally created `PanelPresenter` (instead of the presented view controller conforming to ``PanelPresentable``).
	/// Because until the view controller is presented, nothing is retaining the instance of `PanelPresenter`.
	public func present(from presentingViewController: UIViewController, animated: Bool = true) {
		guard let viewController else { return }
		presentingViewController.present(viewController, animated: animated)
	}

	/// Create a new instance of `PanelPresenter`, applying its behavior to the provided view controller
	/// - Parameter viewController: View controller to apply panel behavior to
	public init(viewController: UIViewController? = nil) {
		self.viewController = viewController
	}
}

extension PanelPresenter: UIViewControllerTransitioningDelegate {
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		PanelAnimationController()
	}
	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		PanelAnimationController()
	}
	public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		PanelPresentationController(
			panelPresenter: self,
			presentedViewController: presented,
			presenting: presenting
		)
	}
}
