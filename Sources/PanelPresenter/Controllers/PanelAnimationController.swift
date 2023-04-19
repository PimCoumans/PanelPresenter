import UIKit

/// Handles the
class PanelAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	var dismissVelocity: CGFloat = 0

	private enum Transition {
		case presenting
		case dismissing
	}
	private var shouldCrossfade: Bool {
		if #available(iOS 14.0, *) {
			if UIAccessibility.prefersCrossFadeTransitions {
				return true
			}
		}
		return UIAccessibility.isReduceMotionEnabled
	}

	private func transition(for context: UIViewControllerContextTransitioning) -> Transition {
		if context.viewController(forKey: .to)?.isBeingPresented == true {
			return .presenting
		} else {
			return .dismissing
		}
	}

	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		let defaultDuration: TimeInterval = 0.21
		guard let transitionContext else {
			return defaultDuration
		}
		switch transition(for: transitionContext) {
		case .presenting: return shouldCrossfade ? defaultDuration : 0.52
		case .dismissing: return defaultDuration
		}
	}

	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let viewController: UIViewController?
		switch transition(for: transitionContext) {
		case .presenting: viewController = transitionContext.viewController(forKey: .to)
		case .dismissing: viewController = transitionContext.viewController(forKey: .from)
		}
		let containerView: UIView
		if let presentationController = viewController?.presentationController as? PanelPresentationController {
			containerView = presentationController.panelContainerView
			dismissVelocity = presentationController.dismissVelocity
		} else {
			containerView = transitionContext.containerView
		}
		switch transition(for: transitionContext) {
		case .presenting: animatePresentation(of: containerView, using: transitionContext)
		case .dismissing: animateDismissal(of: containerView, using: transitionContext)
		}
	}

	private func animatePresentation(of containerView: UIView, using context: UIViewControllerContextTransitioning) {
		guard let view = context.view(forKey: .to) else {
			return
		}
		let duration = transitionDuration(using: context)
		if context.isAnimated {
			if shouldCrossfade {
				containerView.alpha = 0
				UIView.animate(
					withDuration: duration,
					delay: 0,
					options: .curveEaseOut) {
						containerView.alpha = 1
					} completion: { finished in
						context.completeTransition(true)
					}
			} else {
				let viewHeight = view.systemLayoutSizeFitting(
					context.containerView.bounds.size,
					withHorizontalFittingPriority: .defaultHigh,
					verticalFittingPriority: .defaultHigh
				).height + context.containerView.safeAreaInsets.bottom

				containerView.transform = CGAffineTransform(translationX: 0, y: viewHeight)
				UIView.animate(
					withDuration: duration,
					delay: 0,
					usingSpringWithDamping: 0.86,
					initialSpringVelocity: 0) {
						containerView.transform = .identity
					} completion: { finished in
						context.completeTransition(true)
					}
			}

		} else {
			context.completeTransition(true)
		}
	}

	private func animateDismissal(of containerView: UIView, using context: UIViewControllerContextTransitioning) {
		guard let view = context.view(forKey: .from) else {
			return
		}
		let duration = transitionDuration(using: context)
		if context.isAnimated {
			let offset = view.bounds.height - containerView.transform.ty
			let options: UIView.AnimationOptions = dismissVelocity > 5 ? .curveLinear : .curveEaseIn
			let dismissDuration = min(duration, offset / dismissVelocity)
			UIView.animate(
				withDuration: dismissDuration,
				delay: 0,
				options: options) {
					if self.shouldCrossfade {
						containerView.alpha = 0
					} else {
						containerView.transform.ty = view.bounds.height
					}
				} completion: { finished in
					context.completeTransition(true)
				}
		} else {
			context.completeTransition(true)
		}
	}
}
