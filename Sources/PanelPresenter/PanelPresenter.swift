import UIKit
import ConstraintBuilder

public class PanelPresenter: NSObject {
	
	public weak var viewController: UIViewController? { didSet {
		setupViewController()
	}}
	
	public var dimOpactity: CGFloat = 0.45 { didSet {
		dimmingView.backgroundColor = UIColor(white: 0, alpha: dimOpactity)
	}}
	
	public var headerShadowOpactity: CGFloat = 0.15 { didSet {
		headerShadowView.backgroundColor = UIColor(white: 0, alpha: headerShadowOpactity)
	}}
	
	public var headerContentView: UIView {
		headerView
	}
	
	let backgroundViewEffect: UIVisualEffect?
	
	public init(backgroundViewEffect: UIVisualEffect? = UIBlurEffect(style: .regular)) {
		self.backgroundViewEffect = backgroundViewEffect
		super.init()
		commonInit()
	}
	
	public init(viewController: UIViewController, backgroundViewEffect: UIVisualEffect? = UIBlurEffect(style: .regular)) {
		self.viewController = viewController
		self.backgroundViewEffect = backgroundViewEffect
		super.init()
		commonInit()
	}
	
	private func commonInit() {
		setupViewController()
		setupViews()
		scrollViewObserver.didUpdate = { [weak self] scrollView in
			self?.updateScrollView(scrollView)
		}
	}
	
	/// Default scrollView used to display contents
	private(set) lazy var panelScrollView: PanelScrollView = {
		let scrollView = PanelScrollView()
		scrollView.alwaysBounceVertical = true
		scrollView.canCancelContentTouches = true
		scrollView.panGestureRecognizer.cancelsTouchesInView = true
		scrollViewObserver.scrollView = scrollView
		return scrollView
	}()
	
	/// Immediatley updates panel height when content has changed. When `animated` is set to `true`, this just wraps ``layoutIfNeeded()`` in a spring-based animation.
	/// - Parameter animated: Wether the height change should be animated
	public func updatePanelHeight(animated: Bool = true) {
		if animated {
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0, options: .allowUserInteraction) {
				self.layoutIfNeeded()
			}
		} else {
			self.layoutIfNeeded()
		}
	}
	
	/// Call this method from a UIView animation to animate height changes
	public func layoutIfNeeded() {
		viewController?.view.layoutIfNeeded()
		backgroundView.superview?.layoutIfNeeded()
	}
	
	/// Presents attached view controller
	/// - Parameter presentingViewController: View controller to present from
	/// This method is provided as a convenience to present from an externally created `PanelPresenter` (instead of the presented view controller comforming to ``PanelPresentable``.
	/// Because until the view controller is presented, nothing is retaining the instance of `PanelPresenter`.
	public func present(from presentingViewController: UIViewController) {
		guard let viewController = viewController else {
			preconditionFailure()
		}
		
		presentingViewController.present(viewController, animated: true)
	}
	
	/// Height of view placed above scrollView
	private let headerViewHeight: CGFloat = 65
	/// Can be updated from ``viewController``'s protocol method `panelTopInset`
	private var panelTopInset: CGFloat = 10
	private let headerShadowHeight: CGFloat = 2
	/// Extend scrollView height allowing for views bouncing up
	private let bottomBounceAllowance: CGFloat = 100
	/// Inset
	private var backgroundTopConstraint: NSLayoutConstraint?
	/// multiplier to use for transform when bouncing back after pulling down
	private var bounceBackScrollViewMultiplier: CGFloat?
	
	private var viewObserver: NSKeyValueObservation?
	private var scrollViewObserver = ScrollViewObserver()
	private var panelPresentable: PanelPresentable? {
		viewController as? PanelPresentable
	}
	
	private var isScrollViewCustom: Bool {
		scrollView is PanelScrollView == false
	}
	
	private var scrollView: UIScrollView {
		panelPresentable?.panelScrollView ?? panelScrollView
	}
	
	private var startedGestureInHeaderView: Bool = false
	private var dismissGestureVelocity: CGFloat = 0
	private var presenterTintAdjustmentMode: UIView.TintAdjustmentMode = .automatic
	
	private var shouldAdjustPresenterTintMode: Bool {
		panelPresentable?.shouldAdjustPresenterTintMode ?? true
	}
	
	private lazy var dismissPanGestureRecognizer: UIPanGestureRecognizer = {
		let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGestureRecognizer(recognizer:)))
		recognizer.delegate = self
		return recognizer
	}()
	
	private lazy var dismissTapGestureRecognizer: UITapGestureRecognizer = {
		let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDismissTapGestureRecognizer(recognizer:)))
		recognizer.delegate = self
		return recognizer
	}()
	
	private lazy var containerView: UIView = {
		let view = PanelContrainerView()
		view.insetsLayoutMarginsFromSafeArea = false
		return view
	}()
	
	private lazy var scrollContentView: UIView = {
		let view = PanelScrollContentView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()
	
	private lazy var dimmingView: UIView = {
		let view = PanelDimmingView()
		view.backgroundColor = .black.withAlphaComponent(dimOpactity)
		return view
	}()
	
	private lazy var headerView: UIView = {
		let view = PanelHeaderContentView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.insetsLayoutMarginsFromSafeArea = false
		view.directionalLayoutMargins.leading = headerViewHeight * 0.4
		view.directionalLayoutMargins.trailing = headerViewHeight * 0.4
		return view
	}()
	
	private(set) lazy var headerShadowView: UIView = {
		let view = PanelHeaderShadowView()
		view.isUserInteractionEnabled = false
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .black.withAlphaComponent(headerShadowOpactity)
		view.alpha = 0
		return view
	}()
	
	private(set) lazy var backgroundView: UIView = {
		let view = PanelBackgroundView(effect: backgroundViewEffect)
		
		let cornerRadius = headerViewHeight / 2
		view.layer.cornerRadius = cornerRadius
		view.layer.cornerCurve = .continuous
		view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		view.layer.masksToBounds = true
		view.contentMode = .redraw
		return view
	}()
}

// MARK: Custom class names (mostly for view inspection)
extension PanelPresenter {
	private class PanelContrainerView: UIView { }
	private class PanelDimmingView: UIView { }
	private class PanelScrollContentView: UIView { }
	private class PanelHeaderContentView: UIView { }
	private class PanelHeaderShadowView: UIView { }
	private class PanelBackgroundView: UIVisualEffectView { }
	private class PanelPresentationController: UIPresentationController {
		var panelPresenter: PanelPresenter?
	}
}

// MARK: - Setting up view controller
private extension PanelPresenter {
	
	func setupViewController() {
		viewController?.modalPresentationStyle = .custom
		viewController?.transitioningDelegate = self
		
		ensureViewHierarchy()
	}
	
	/// Makes sure containerView is added to the view hierarchy
	func ensureViewHierarchy(forceViewLoaded: Bool = false) {
		guard let viewController = viewController else {
			return
		}
		if viewController.isViewLoaded == true || forceViewLoaded {
			setupViewControllerView()
		} else if viewObserver != nil {
			// Wait for `viewController.view` to be loaded
			viewObserver = viewController.observe(\.view, options: [.new], changeHandler: { viewController, change in
				self.ensureViewHierarchy()
				self.viewObserver = nil
			})
		}
	}
	
	func setupViewControllerView() {
		guard let viewController = viewController, viewController.view.superview == nil else {
			return
		}
		if let viewController = panelPresentable {
			panelTopInset = viewController.panelTopInset
		}
		containerView.layoutMargins.top = headerViewHeight + panelTopInset
		if isScrollViewCustom {
			panelScrollView.removeFromSuperview()
			prepareCustomScrollView(scrollView)
			containerView.insertSubview(scrollView, at: 0)
			containerView.insertSubview(viewController.view, belowSubview: scrollView)
		} else {
			scrollContentView.addSubview(viewController.view)
			viewController.view.extendToSuperview()
		}
		
		setupGestureRecognizers()
	}
	
	func prepareCustomScrollView(_ scrollView: UIScrollView) {
		NSLayoutConstraint.deactivate(scrollView.constraints)
		scrollView.backgroundColor = .clear
		scrollView.alwaysBounceVertical = true
		scrollView.canCancelContentTouches = true
		scrollView.panGestureRecognizer.cancelsTouchesInView = true
		scrollViewObserver.scrollView = scrollView
	}
}

// MARK: - View setup
private extension PanelPresenter {
	
	func setupViews() {
		containerView.layoutMargins.top = headerViewHeight + panelTopInset
		
		scrollView.addSubview(scrollContentView)
		
		containerView.addSubview(scrollView)
		containerView.addSubview(headerView)
		containerView.addSubview(headerShadowView)
	}
	
	func setupViewConstraints() {
		let topHeight = headerViewHeight
		
		scrollView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor)
			$0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottomBounceAllowance)
			$0.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor)
		}
		
		if !isScrollViewCustom {
			scrollContentView.applyConstraints {
				$0.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor)
				$0.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor)
				$0.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
				$0.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
				$0.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
			}
		}
		
		headerView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
			$0.heightAnchor.constraint(equalToConstant: topHeight)
		}
		
		headerShadowView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
			$0.heightAnchor.constraint(equalToConstant: headerShadowHeight)
			$0.topAnchor.constraint(equalTo: headerView.bottomAnchor)
		}
		updateScrollView(scrollView)
	}
	
	func setupBackgroundViews(in containerView: UIView) {
		containerView.addSubview(dimmingView)
		containerView.addSubview(backgroundView)
	}
	
	func setupBackgroundViewConstraints() {
		dimmingView.extendToSuperview()
		
		// Align to bottom of screen when possible
		let bottomAnchor = containerView.bottomAnchor
		// Align to scrollView‘s top inset. Constraint will be updated when scrollView updates
		backgroundTopConstraint = backgroundView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor)
		backgroundTopConstraint?.priority = .defaultLow
		
		backgroundView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor)
			$0.topAnchor.constraint(greaterThanOrEqualTo: containerView.layoutMarginsGuide.topAnchor, constant: -headerViewHeight)
			
			$0.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomBounceAllowance)
			backgroundTopConstraint!
		}
		
		headerView.applyConstraints {
			$0.topAnchor.constraint(equalTo: backgroundView.topAnchor)
		}
		updateScrollView(scrollView)
	}
	
	func setupGestureRecognizers() {
		containerView.addGestureRecognizer(scrollView.panGestureRecognizer)
		containerView.addGestureRecognizer(dismissTapGestureRecognizer)
		containerView.addGestureRecognizer(dismissPanGestureRecognizer)
	}
}

// MARK: - UIScrollView handling
private extension PanelPresenter {
	
	/// Called whenever any layout properties of `scrollView` changes
	func updateScrollView(_ scrollView: UIScrollView) {
		// ScrollView‘s bottom extends by `bottomBounceAllowance`
		scrollView.contentInset.bottom = bottomBounceAllowance
		let scrollViewHeight = scrollView.frame.inset(by: scrollView.safeAreaInsets).height - bottomBounceAllowance
		let contentHeight = scrollView.contentSize.height
		// Set top inset so content is always aligned to bottom
		scrollView.contentInset.top = max(0, scrollViewHeight - contentHeight)
		
		let scrollOffset = scrollView.relativeContentOffset.y
		
		if let transformMultiplier = bounceBackScrollViewMultiplier {
			// When bouncing back from being dragged down, reset the transform as scrollview bounces back up
			if scrollOffset >= 0 {
				translateViews(withOffset: nil)
				bounceBackScrollViewMultiplier = nil
			} else {
				let multipliedOffset = -scrollOffset * transformMultiplier
				translateViews(withOffset: multipliedOffset)
			}
		}
		
		backgroundTopConstraint?.constant = scrollView.contentInset.top - scrollOffset - headerViewHeight
		
		// Make top of scroll indicator never extend beyond top of content
		let topScrollOvershoot = min(0, scrollOffset)
		scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
			top: max(0, scrollView.adjustedContentInset.top - topScrollOvershoot) + headerShadowHeight,
			left: 0,
			bottom: scrollView.contentInset.bottom,
			right: 0
		)
		
		// Show or hide shadowView based on content offset
		let shadowAlpha: CGFloat = scrollView.contentOffset.y > 0 ? 1 : 0
		if headerShadowView.alpha != shadowAlpha {
			UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
				self.headerShadowView.alpha = shadowAlpha
			}
		}
	}
}

// MARK: - Handling gesture recognizers
extension PanelPresenter: UIGestureRecognizerDelegate {
	
	private func isGestureRecognizer(_ recognizer: UIGestureRecognizer, inView view: UIView) -> Bool {
		view.point(inside: recognizer.location(in: view), with: nil)
	}
	
	private func isGestureRecognizerInScrollContent(_ recognizer: UIGestureRecognizer) -> Bool {
		if isScrollViewCustom {
			let point = recognizer.location(in: scrollView)
			return scrollView.isPointInScrollContent(point)
		} else {
			return isGestureRecognizer(recognizer, inView: scrollContentView)
		}
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard otherGestureRecognizer == scrollView.panGestureRecognizer else {
			return false
		}
		if isGestureRecognizer(gestureRecognizer, inView: headerView) && scrollView.contentExeedsBounds {
			// Draggin from headerView should not allow scrolling when content can actually scroll
			// Disable `otherGestureRecognizer`, so header drag overrules scroll gesture
			otherGestureRecognizer.isEnabled = false
			otherGestureRecognizer.isEnabled = true
			return true
		}
		return otherGestureRecognizer == scrollView.panGestureRecognizer
	}
	
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Set initial state
		startedGestureInHeaderView = false
		
		let isGestureInContent = isGestureRecognizerInScrollContent(gestureRecognizer)
		let isGestureInHeaderView = isGestureRecognizer(gestureRecognizer, inView: headerView)
		
		if gestureRecognizer == dismissTapGestureRecognizer {
			// Allow dismiss taps outside panel
			return !isGestureInContent && !isGestureInHeaderView
		} else if gestureRecognizer == dismissPanGestureRecognizer {
			if isGestureInHeaderView {
				// Always allow drags from headerView
				startedGestureInHeaderView = true
				return true
			}
			if isGestureInContent {
				// Drag along with scrollView when content is at top or panel content shouldn‘t scroll
				return scrollView.isAtTop
			}
		}
		
		return true
	}
	
	@objc func handleDismissTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
		animateDismissal(velocity: 0)
	}
	
	@objc func handleDismissGestureRecognizer(recognizer: UIPanGestureRecognizer) {
		if recognizer.state == .began {
			// Manually set translation when catching the scrollView‘s content while it‘s bouncing down
			let scrollOffset = scrollView.relativeContentOffset.y
			if scrollOffset < 0 {
				let translation = recognizer.translation(in: containerView).y
				recognizer.setTranslation(CGPoint(x: 0, y: translation - scrollOffset), in: containerView)
				scrollView.stopVerticalScrolling()
			}
		}
		
		let velocity = recognizer.velocity(in: containerView).y
		let offset = recognizer.translation(in: containerView).y
		
		let endStates: [UIGestureRecognizer.State] = [.cancelled, .failed, .ended]
		let recognizerEnded = endStates.contains(recognizer.state)
		
		let canDragWithScrollViewBounce = !scrollView.contentExeedsBounds || !startedGestureInHeaderView
		
		if recognizerEnded {
			// How far scrollView is rubber-banding down
			let scrollOvershoot = max(0, -scrollView.relativeContentOffset.y)
			scrollView.bounces = true
			
			func resetScrollViewBounce() {
				// Clamp scrollView‘s offset to scrollable range
				scrollView.stopVerticalScrolling()
				// Translate views with scrollView‘s original overshoot
				translateViews(withOffsetTransformer: { $0 + scrollOvershoot })
			}
			
			if recognizer.state == .ended && velocity > 0 && offset > 0 {
				// Actually dismiss the panel
				scrollView.showsVerticalScrollIndicator = false
				resetScrollViewBounce()
				animateDismissal(velocity: velocity)
			} else if currentViewTranslation != 0 {
				guard scrollView.contentExeedsBounds else {
					// Bounce back along with scrollView (see `updateScrollView(_:)` for more)
					bounceBackScrollViewMultiplier = currentViewTranslation / -scrollView.relativeContentOffset.y
					return
				}
				
				// Animate view bounce back when scrollView won‘t
				let bounceBackLength = currentViewTranslation + scrollOvershoot
				let bounceBackpringVelocity = -(velocity / bounceBackLength)
				resetScrollViewBounce()
				UIView.animate(
					withDuration: 0.6, delay: 0,
					usingSpringWithDamping: 0.94, initialSpringVelocity: bounceBackpringVelocity,
					options: [.beginFromCurrentState, .allowUserInteraction]
				) {
					self.translateViews(withOffset: nil)
				}
			}
		} else {
			var translation = max(0, offset)
			if canDragWithScrollViewBounce {
				translation += min(0, scrollView.relativeContentOffset.y)
			}
			translateViews(withOffset: translation)
			scrollView.bounces = canDragWithScrollViewBounce
		}
	}
}

// MARK: - Setting view offset transforms
private extension PanelPresenter {
	/// Views that should move when translating along with dismiss gesture or scrollView bounce
	var viewsToTranslate: [UIView] { [containerView, backgroundView] }
	
	var currentViewTranslation: CGFloat {
		viewsToTranslate.first!.transform.ty
	}
	
	func translateViews(withOffsetTransformer transformer: (CGFloat) -> CGFloat?) {
		viewsToTranslate.forEach {
			let offset = transformer($0.transform.ty) ?? 0
			$0.transform = CGAffineTransform(translationX: 0, y: offset)
		}
	}
	
	func translateViews(withOffset offset: CGFloat?) {
		let transform = offset.map { CGAffineTransform(translationX: 0, y: $0) } ?? .identity
		viewsToTranslate.forEach {
			$0.transform = transform
		}
	}
}

// MARK: - Animate presentation and dismissal
private extension PanelPresenter {
	func animateDismissal(velocity: CGFloat = 0) {
		dismissGestureVelocity = velocity
		viewController?.presentingViewController?.dismiss(animated: true)
	}
}

extension PanelPresenter: UIViewControllerTransitioningDelegate {
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		let controller = PanelPresentationController(presentedViewController: presented, presenting: presenting)
		// Trick to retain panelPresenter when not set through `PanelPresentable`
		controller.panelPresenter = self
		return controller
	}
}

extension PanelPresenter: UIViewControllerAnimatedTransitioning {
	
	func isPresenting(using context: UIViewControllerContextTransitioning?) -> Bool {
		context?.viewController(forKey: .to)?.isBeingPresented == true
	}
	
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		if isPresenting(using: transitionContext) {
			return 0.62
		} else {
			return 0.32
		}
	}
	
	public func animateTransition(using context: UIViewControllerContextTransitioning) {
		
		let isPresenting = isPresenting(using: context)
		let presenterViewKey: UITransitionContextViewKey = isPresenting ? .from : .to
		let presenterViewControllerKey: UITransitionContextViewControllerKey = isPresenting ? .from : .to
		let presenterView = context.view(forKey: presenterViewKey) ?? context.viewController(forKey: presenterViewControllerKey)?.view
		
		if isPresenting {
			if let view = presenterView {
				presenterTintAdjustmentMode = view.tintAdjustmentMode
			}
			setupBackgroundViews(in: context.containerView)
			
			context.containerView.addSubview(containerView)
			containerView.applyConstraints {
				$0.topAnchor.constraint(equalTo: context.containerView.safeAreaLayoutGuide.topAnchor)
				$0.leadingAnchor.constraint(equalTo: context.containerView.leadingAnchor)
				$0.trailingAnchor.constraint(equalTo: context.containerView.trailingAnchor)
				$0.bottomAnchor.constraint(equalTo: context.containerView.bottomAnchor)
			}
			ensureViewHierarchy(forceViewLoaded: true)
			setupViewConstraints()
			setupBackgroundViewConstraints()
			
			context.containerView.setNeedsLayout()
			context.containerView.layoutIfNeeded()
		}
		
		let visibleContainerViewFrame = containerView.bounds.inset(by: containerView.layoutMargins)
		let fullOffset = min(visibleContainerViewFrame.height, scrollView.contentSize.height + headerViewHeight) + containerView.safeAreaInsets.bottom
		let fullDuration = transitionDuration(using: context)
		let duration = max(0.15, fullDuration * ((fullOffset / containerView.bounds.height) * 0.75))
		
		if isPresenting {
			dimmingView.alpha = 0
			translateViews(withOffset: fullOffset)
			
			UIView.animate(withDuration: fullDuration * 0.35, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
				presenterView?.tintAdjustmentMode = .dimmed
				self.dimmingView.alpha = 1
			}
			
			UIView.animate(
				withDuration: fullDuration, delay: 0,
				usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
				options: .allowUserInteraction
			) {
				self.dimmingView.alpha = 1
				self.translateViews(withOffset: nil)
			} completion: { finished in
				context.completeTransition(finished)
			}
		} else {
			let options: UIView.AnimationOptions = dismissGestureVelocity > 5 ? .curveLinear : .curveEaseIn
			let distanceToCover = fullOffset - currentViewTranslation
			let dismissDuration = min(duration, distanceToCover / dismissGestureVelocity)
			
			UIView.animate(withDuration: dismissDuration, delay: 0, options: options) {
				presenterView?.tintAdjustmentMode = self.presenterTintAdjustmentMode
				self.dimmingView.alpha = 0
				self.translateViews(withOffset: fullOffset)
			} completion: { finished in
				context.completeTransition(finished)
			}
		}
	}
}
