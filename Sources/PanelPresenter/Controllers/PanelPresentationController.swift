import UIKit
import ConstraintBuilder

extension PanelPresentationController {
	class PanelContainerView: UIView { }
	class PanelDimmingView: UIView { }
	class PanelContainerScrollView: UIScrollView { }
	class PanelContentView: UIView { }
	class PanelBackgroundView: UIVisualEffectView { }
	class PanelHeaderView: UIView { }
	class PanelHeaderBackgroundView: UIVisualEffectView { }
	class PanelHeaderBorderView: UIView { }
}

/// Presentation controller that actually controls the panel behavior. Accessible through the `panelPresentationController` property in
/// your view controller. Use this object to configure the behavior of the panel presentation.
public class PanelPresentationController: UIPresentationController {

	/// Opacity of the dimming view behind the panel
	public var dimOpacity: CGFloat = 0.45 { didSet {
		panelDimmingView.backgroundColor = UIColor(white: 0, alpha: dimOpacity)
	}}

	/// Whether the ``headerView`` should be shown, defaults to `false`
	public var showsHeader: Bool = false { didSet {
		guard isViewLoaded, showsHeader != oldValue else { return }
		updateHeaderViewVisibility()
	}}

	/// Height of the ``panelHeaderView``
	public var headerHeight: CGFloat = 50 { didSet {
		guard isViewLoaded else { return }
		headerHeightConstraint?.constant = headerHeight
		presentedViewController.additionalSafeAreaInsets.top = headerHeight
	}}

	/// Whether the background of the ``panelHeaderView`` should be fully transparent while content is scrolled to top.
	/// The default value is `true`.
	public var fadeInHeaderBackgroundWhileScrolling: Bool = true { didSet {
		updateHeaderBackgroundVisibility()
	}}

	/// Corner radius of two top edges of the header and the masking of the containing scrollView.
	public var cornerRadius: CGFloat = 16 { didSet {
		guard isViewLoaded else { return }
		updateCornerRadii()
	}}

	/// Set an additional inset from the screen’s top safe area
	public var topInset: CGFloat = 10 { didSet {
		guard isViewLoaded else { return }
		updateTopInsetIfNeeded()
	}}

	/// Whether the presented view should take up all the available height.
	/// The default value is `false`. Setting to `true` disables auto-resizing and keeps the panel’s top below ``topInset``.
	public var extendsToFullHeight: Bool = false { didSet {
		guard isViewLoaded else { return }
		updateTopInsetIfNeeded()
	}}

	/// Whether the tint mode of the presenting view controller’s view should be changed when presented.
	/// The default value is `true`.
	public var shouldAdjustPresenterTintMode: Bool = true { didSet {
		guard shouldAdjustPresenterTintMode != oldValue, !presentedViewController.isBeingPresented else {
			return
		}
		if shouldAdjustPresenterTintMode {
			presenterTintAdjustingMode = presentingViewController.view.tintAdjustmentMode
			presentingViewController.view.tintAdjustmentMode = .dimmed
		} else {
			if presentingViewController.isViewLoaded {
				presentingViewController.view.tintAdjustmentMode = presenterTintAdjustingMode
			}
		}
	}}

	private struct ScrollSession: Equatable {
		let scrollView: UIScrollView
	}

	private var panelPresenter: PanelPresenter?
	private var isViewLoaded: Bool = false
	private var presenterTintAdjustingMode: UIView.TintAdjustmentMode = .automatic

	private var scrollSession: ScrollSession?
	var dismissVelocity: CGFloat = 0

	private let scrollViewObserver: ScrollViewObserver = ScrollViewObserver()
	private let contentScrollViewObserver: ScrollViewObserver = ScrollViewObserver()
	private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
	private lazy var dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))

	private var containerScrollViewTopConstraint: NSLayoutConstraint?
	private var headerHeightConstraint: NSLayoutConstraint?
	private var contentScrollViewHeightConstraint: NSLayoutConstraint? { didSet {
		oldValue?.isActive = false
		contentScrollViewHeightConstraint?.isActive = true
	}}
	private var contentHeightConstraint: NSLayoutConstraint? { didSet {
		oldValue?.isActive = false
		contentHeightConstraint?.isActive = true
	}}

	private var keyboardFrame: CGRect?
	private var keyboardFrameObserver: AnyObject?

	private lazy var panelDimmingView: UIView = {
		let view = PanelDimmingView()
		view.backgroundColor = UIColor(white: 0, alpha: dimOpacity)
		return view
	}()
	private(set) lazy var panelContainerView = PanelContainerView()

	/// Main scrollView your view is placed in
	public private(set) lazy var containerScrollView: UIScrollView = {
		let scrollView = PanelScrollView()
		scrollView.alwaysBounceVertical = true
		scrollView.contentInsetAdjustmentBehavior = .never
		setUpTopCornerMasking(for: scrollView)
		return scrollView
	}()

	private lazy var contentView: UIView = {
		let view = PanelContentView()
		view.clipsToBounds = true
		setUpTopCornerMasking(for: view)
		return view
	}()

	/// Header shown when ``showsHeader`` is set to `true`. Add any controls to display above your view’s contents
	public private(set) lazy var headerView: UIView = {
		let view = PanelHeaderView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.insetsLayoutMarginsFromSafeArea = false
		setUpTopCornerMasking(for: view)

		headerHeightConstraint = view.heightAnchor.constraint(equalToConstant: headerHeight)
		headerHeightConstraint?.isActive = true

		view.addSubview(panelHeaderBackgroundView)
		panelHeaderBackgroundView.extendToSuperview()

		panelHeaderBackgroundView.contentView.addSubview(panelHeaderBorderView)
		panelHeaderBorderView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: panelHeaderBackgroundView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: panelHeaderBackgroundView.trailingAnchor)
			$0.bottomAnchor.constraint(equalTo: panelHeaderBackgroundView.bottomAnchor)
			$0.heightAnchor.constraint(equalToConstant: 1)
		}
		return view
	}()

	/// Background of ``headerView``, can be configured with any ``UIVisualEffect``
	public private(set) lazy var panelHeaderBackgroundView: UIVisualEffectView = {
		let view = PanelHeaderBackgroundView()
		view.effect = UIBlurEffect(style: .regular)
		return view
	}()

	/// Bottom border of ``headerView``, can be used to configure with any color.
	/// Uses `UIColor.separator` by default
	public private(set) lazy var panelHeaderBorderView: UIView = {
		let view = PanelHeaderBorderView()
		view.backgroundColor = .separator
		return view
	}()

	/// Panel’s full background, can be configured with any ``UIVisualEffect`` or background color.
	/// Uses `UIColor.secondarySystemBackground` by default
	public private(set) lazy var panelBackgroundView: UIVisualEffectView = {
		let view = PanelBackgroundView()
		view.backgroundColor = .secondarySystemBackground
		setUpTopCornerMasking(for: view)
		return view
	}()

	init(
		panelPresenter: PanelPresenter,
		presentedViewController: UIViewController,
		presenting presentingViewController: UIViewController?
	) {
		// Store a reference to `PanelPresenter` by default
		self.panelPresenter = panelPresenter
		super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
	}
}

// MARK: Updating the panel’s presentation
extension PanelPresentationController {

	/// Call this method when the returned value of ``PanelPresentable/panelScrollView-9s4qr`` has changed
	public func setNeedsScrollViewUpdate() {
		updateContentScrollViewIfNeeded()
	}

	/// Attempts to update the panel's layout, allowing the caller to perform this logic with an animation
	public func layoutIfNeeded() {
		containerView?.setNeedsLayout()
		containerView?.layoutIfNeeded()
	}

	/// Update your panel’s configuration and animates the changes. Any other layout happening in the `changes` closure will be animated too
	/// - Parameter changes: Any layout updates that need to happen while animating the panel’s dimensions
	/// - Parameter completion: Optional closure called when animation completes
	public func animateChanges(_ changes: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
		containerView?.setNeedsLayout()
		UIView.animate(
			withDuration: 0.42,
			delay: 0,
			usingSpringWithDamping: 0.86,
			initialSpringVelocity: 0,
			options: [.allowUserInteraction, .beginFromCurrentState],
			animations: {
				changes()
				self.layoutIfNeeded()
			},
			completion: completion
		)
	}
}

extension PanelPresentationController {

	public override func containerViewWillLayoutSubviews() {
		updateKeyboardBottomInsetIfNeeded()
		super.containerViewWillLayoutSubviews()
	}

	public override func presentationTransitionWillBegin() {
		setUpInteraction()
		setUpViews()
		contentScrollViewObserver.scrollView?.layoutIfNeeded()

		presenterTintAdjustingMode = presentingViewController.view.tintAdjustmentMode
		panelDimmingView.alpha = 0
		presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
			self.panelDimmingView.alpha = 1
			if self.shouldAdjustPresenterTintMode {
				self.presentingViewController.view.tintAdjustmentMode = .dimmed
			}
		})
	}

	public override func dismissalTransitionWillBegin() {
		presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
			self.panelDimmingView.alpha = 0
			if self.shouldAdjustPresenterTintMode {
				self.presentingViewController.view.tintAdjustmentMode = self.presenterTintAdjustingMode
			}
		})
	}
}

extension PanelPresentationController {
	/// Configures the scrollView observers and gesture recognizers
	private func setUpInteraction() {
		scrollViewObserver.didUpdate = { [weak self] scrollView in
			self?.containerScrollViewDidUpdate(scrollView)
		}
		contentScrollViewObserver.didUpdate = { [weak self] scrollView in
			self?.contentScrollViewDidUpdate(scrollView)
		}
		panGestureRecognizer.delegate = self
		panGestureRecognizer.delaysTouchesBegan = true
		panGestureRecognizer.delaysTouchesEnded = false
		dismissTapGestureRecognizer.delegate = self

		keyboardFrameObserver = NotificationCenter.default.addObserver(
			forName: UIApplication.keyboardWillChangeFrameNotification,
			object: nil,
			queue: nil,
			using: { [weak self] notification in
				guard
					let self, let userInfo = notification.userInfo,
					let keyboardFrame = userInfo[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect,
					let containerView = self.containerView,
					let screen = notification.object as? UIScreen ?? containerView.window?.windowScene?.screen
				else {
					return
				}
				if keyboardFrame.intersects(screen.bounds) {
					self.keyboardFrame = containerView.convert(keyboardFrame, from: screen.coordinateSpace)
				} else {
					self.keyboardFrame = nil
				}
				self.layoutIfNeeded()
			}
		)
	}

	/// Adds all the views and sets all the appropriate constraints
	private func setUpViews() {
		guard !isViewLoaded, let containerView, let presentedView else { return }
		// Extra overlap on the bottom when whole container bounces up
		let backgroundBottomOutset: CGFloat = 200

		containerView.addSubview(panelDimmingView)
		panelDimmingView.extendToSuperview()

		containerView.addSubview(panelContainerView)
		panelContainerView.addGestureRecognizer(panGestureRecognizer)
		panelContainerView.addGestureRecognizer(dismissTapGestureRecognizer)
		panelContainerView.extendToSuperview()

		panelContainerView.addSubview(panelBackgroundView)

		// containerScrollView defines total scrollable area. From bottom of view top top safe area inset + topInset
		panelContainerView.addSubview(containerScrollView)
		containerScrollViewTopConstraint = containerScrollView.topAnchor
			.constraint(equalTo: panelContainerView.safeAreaLayoutGuide.topAnchor, constant: topInset)
		containerScrollView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: panelContainerView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: panelContainerView.trailingAnchor)
			containerScrollViewTopConstraint!
			$0.bottomAnchor.constraint(equalTo: panelContainerView.bottomAnchor)
		}
		scrollViewObserver.scrollView = containerScrollView
		panelContainerView.addGestureRecognizer(containerScrollView.panGestureRecognizer)

		// ContentView holds the presented view and plays nicely with the container scrollView’s content size
		containerScrollView.addSubview(contentView)
		contentView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: panelContainerView.safeAreaLayoutGuide.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: panelContainerView.safeAreaLayoutGuide.trailingAnchor)
			$0.topAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.topAnchor)
			$0.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor)
			$0.heightAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.heightAnchor)
				.withPriority(.defaultHigh)
			$0.widthAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.widthAnchor)
		}

		// presentView should dictate size of contentView
		contentView.addSubview(presentedView)
		presentedView.extendToSuperview()

		// Background aligns to top of view and bottom of container
		panelBackgroundView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: panelContainerView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: panelContainerView.trailingAnchor)
			$0.topAnchor.constraint(greaterThanOrEqualTo: containerScrollView.topAnchor)
			$0.topAnchor.constraint(equalTo: presentedView.topAnchor)
				.withPriority(.defaultHigh)
			$0.bottomAnchor.constraint(equalTo: panelContainerView.bottomAnchor, constant: backgroundBottomOutset)
		}

		// Header is placed on top of scrollView and aligned to top of panel background
		panelContainerView.addSubview(headerView)
		headerView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: panelBackgroundView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: panelBackgroundView.trailingAnchor)
			$0.topAnchor.constraint(equalTo: panelBackgroundView.topAnchor)
		}
		isViewLoaded = true

		updateHeaderViewVisibility()
		updateContentScrollViewIfNeeded()
		updateCornerRadii()
	}

	private func updateTopInsetIfNeeded() {
		let topInset = extendsToFullHeight ? 0 : topInset
		guard containerScrollViewTopConstraint?.constant != topInset else {
			return
		}
		containerScrollViewTopConstraint?.constant = topInset
	}

	private func updateHeaderViewVisibility() {
		if showsHeader {
			headerView.alpha = 1
			presentedViewController.additionalSafeAreaInsets.top = headerHeight
		} else {
			headerView.alpha = 0
			presentedViewController.additionalSafeAreaInsets.top = 0
		}
	}

	private func updateHeaderBackgroundVisibility() {
		guard fadeInHeaderBackgroundWhileScrolling else {
			panelHeaderBackgroundView.alpha = 1
			return
		}
		let contentOffset: CGPoint
		if let scrollView = panelPresentable?.panelScrollView {
			contentOffset = scrollView.relativeContentOffset
		} else {
			contentOffset = containerScrollView.contentOffset
		}
		let opacity = max(0, min(1, contentOffset.y / 20))
		panelHeaderBackgroundView.alpha = opacity
	}

	/// Checks the viewController’s `panelScrollView` property and configures the panel behavior accordingly
	private func updateContentScrollViewIfNeeded() {
		guard let scrollView = panelPresentable?.panelScrollView else {
			contentScrollViewHeightConstraint = nil
			contentHeightConstraint = nil
			containerScrollView.alwaysBounceVertical = true
			return
		}
		scrollView.contentInsetAdjustmentBehavior = .always
		contentScrollViewObserver.scrollView = scrollView
		contentHeightConstraint = presentedViewController.view.heightAnchor
			.constraint(lessThanOrEqualTo: containerScrollView.heightAnchor)
		contentScrollViewHeightConstraint = scrollView.safeAreaLayoutGuide.heightAnchor
			.constraint(equalToConstant: 10)
			.withPriority(.defaultHigh)
		NSLayoutConstraint.build {
			contentHeightConstraint!
			contentScrollViewHeightConstraint!
		}
	}

	private func updateKeyboardBottomInsetIfNeeded() {
		var bottomInset: CGFloat = 0
		if let keyboardFrame, let containerView {
			let keyboardHeight = containerView
				.bounds
				.inset(by: containerView.safeAreaInsets)
				.intersection(keyboardFrame)
				.height
			if keyboardHeight > 0 {
				bottomInset = 8 + keyboardHeight
			}
		}
		if presentedViewController.additionalSafeAreaInsets.bottom != bottomInset {
			presentedViewController.additionalSafeAreaInsets.bottom = bottomInset
		}
	}
}

extension PanelPresentationController {
	private func setUpTopCornerMasking(for view: UIView) {
		view.layer.masksToBounds = true
		view.layer.cornerCurve = .continuous
		view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
	}

	private func updateCornerRadii() {
		containerScrollView.layer.cornerRadius = cornerRadius
		panelBackgroundView.layer.cornerRadius = cornerRadius
		headerView.layer.cornerRadius = cornerRadius
		contentView.layer.cornerRadius = cornerRadius
	}
}

extension PanelPresentationController {
	private var panelPresentable: PanelPresentable? {
		presentedViewController as? PanelPresentable
	}

	private func containerScrollViewDidUpdate(_ scrollView: UIScrollView) {
		let scrollViewHeight = scrollView.frame.height
		let contentHeight = scrollView.contentSize.height
		let topInset = max(0, scrollViewHeight - contentHeight)
		let contentInset = UIEdgeInsets(
			top: topInset,
			left: 0,
			bottom: 0,
			right: 0)
		if scrollView.contentInset != contentInset {
			scrollView.contentInset = contentInset
		}
		if scrollView.contentExceedsBounds {
			scrollView.addGestureRecognizer(scrollView.panGestureRecognizer)
		} else {
			panelContainerView.addGestureRecognizer(scrollView.panGestureRecognizer)
		}
		// Bounce scrollIndicator along with top bounce animation
		let bounceOvershoot = max(0, -scrollView.relativeContentOffset.y)
		let extraTopInset: CGFloat = showsHeader ? headerHeight : 8
		scrollView.verticalScrollIndicatorInsets.top = extraTopInset + bounceOvershoot
		updateHeaderBackgroundVisibility()
	}

	private func contentScrollViewDidUpdate(_ scrollView: UIScrollView) {
		if scrollView.contentExceedsBounds {
			scrollView.isScrollEnabled = true
			containerScrollView.alwaysBounceVertical = false
		} else {
			scrollView.isScrollEnabled = false
			containerScrollView.alwaysBounceVertical = true
		}
		contentScrollViewHeightConstraint?.constant = scrollView.contentSize.height
		// Bounce along with top bounce animation
		let bounceOvershoot = max(0, -scrollView.relativeContentOffset.y)
		if panelBackgroundView.transform.ty != bounceOvershoot {
			panelBackgroundView.transform.ty = bounceOvershoot
			headerView.transform.ty = bounceOvershoot
		}
		scrollView.verticalScrollIndicatorInsets.top = 8 + bounceOvershoot
		updateHeaderBackgroundVisibility()
	}
}

extension PanelPresentationController: UIGestureRecognizerDelegate {
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if panelPresentable?.panelCanBeDismissed == false {
			// Panel doesn’t want to be dismissed, don’t allow any gestures
			return false
		}
		if gestureRecognizer == panGestureRecognizer {
			return true
		} else if gestureRecognizer == dismissTapGestureRecognizer {
			let tapLocation = gestureRecognizer.location(in: panelBackgroundView)
			return !panelBackgroundView.point(inside: tapLocation, with: nil)
		}
		return true
	}

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer == panGestureRecognizer
	}

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
}

extension PanelPresentationController {
	@objc func dismiss() {
		presentingViewController.dismiss(animated: true)
	}

	private func startScrollSession(at location: CGPoint) {
		let scrollView: UIScrollView
		if let contentScrollView = contentScrollViewObserver.scrollView, contentScrollView.isTracking {
			scrollView = contentScrollView
		} else {
			scrollView = containerScrollView
		}
		let startedOutsideScrollView = !containerScrollView.frame.contains(location)
		let canDismiss = startedOutsideScrollView || scrollView.isAtTop || !scrollView.contentExceedsBounds
		guard canDismiss else {
			return
		}
		scrollSession = ScrollSession(scrollView: scrollView)
		containerScrollView.stopVerticalScrolling()
		contentScrollViewObserver.scrollView?.stopVerticalScrolling()
	}

	@objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: panelContainerView)
		let translation = recognizer.translation(in: panelContainerView)

		if recognizer.state == .began {
			startScrollSession(at: location)
		}

		guard let scrollSession else {
			return
		}
		let scrollView = scrollSession.scrollView

		switch recognizer.state {
		case .changed:
			scrollView.bounces = scrollView.relativeContentOffset.y > 0 || translation.y < 0
			let offset = max(0, translation.y)
			if panelContainerView.transform.ty != offset {
				panelContainerView.transform.ty = offset
			}
			scrollView.showsVerticalScrollIndicator = offset <= 0
		case .ended, .cancelled, .failed:
			defer {
				self.scrollSession = nil
			}
			let velocity = recognizer.velocity(in: panelContainerView)
			if recognizer.state == .ended && translation.y > 0 && velocity.y > 0 {
				dismissVelocity = velocity.y
				dismiss()
			} else {
				scrollView.bounces = true
				guard panelContainerView.transform.ty != 0 else {
					return
				}
				CFRunLoopPerformBlock(CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue) {
					// Trick to make sure scrollView doesn’t start scrolling after lifting touch
					// and panel should just bounce back up
					scrollView.stopVerticalScrolling()
					scrollView.isAtTop = true
				}
				let velocity = recognizer.velocity(in: panelContainerView)
				let springVelocity = -(velocity.y / translation.y)
				UIView.animate(
					withDuration: 0.42,
					delay: 0,
					usingSpringWithDamping: 0.86,
					initialSpringVelocity: springVelocity) {
						self.panelContainerView.transform = .identity
					}
			}
		default:
			break
		}
	}
}
