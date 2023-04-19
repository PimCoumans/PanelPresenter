import UIKit

import PanelPresenter
import ConstraintBuilder

extension UIViewController {
	private func compatibleButton(title: String, isBig: Bool = false) -> UIButton {
		let button: UIButton
		if #available(iOS 15.0, *) {
			var configuration: UIButton.Configuration = isBig ? .borderedProminent() : .plain()
			configuration.buttonSize = isBig ? .large : .medium
			configuration.title = title
			button = UIButton(configuration: configuration)
			if !isBig {
				button.maximumContentSizeCategory = .accessibilityMedium
			}
		} else {
			button = UIButton(type: .roundedRect)
			button.setTitle(title, for: .normal)
			let textStyle: UIFont.TextStyle = isBig ? .title3 : .callout
			button.titleLabel?.font = UIFont.preferredFont(forTextStyle: textStyle)
			button.titleLabel?.adjustsFontForContentSizeCategory = true
			button.titleLabel?.adjustsFontSizeToFitWidth = true
			if isBig {
				let inset: CGFloat = 12
				button.contentEdgeInsets = .init(top: inset, left: inset * 2, bottom: inset, right: inset * 2)
				button.backgroundColor = view.tintColor
				button.layer.cornerRadius = 8
				button.layer.cornerCurve = .continuous
				button.setTitleColor(.white, for: .normal)
			}
			if isBig {
			}
		}
		return button
	}
	
	func compatibleButton(title: String, isBig: Bool = false, action: @escaping () -> Void) -> UIButton {
		let button = compatibleButton(title: title, isBig: isBig)
		button.addAction(UIAction { _ in action() }, for: .touchUpInside)
		return button
	}
	
	func compatibleButton(title: String, selector: Selector) -> UIButton {
		let button: UIButton = compatibleButton(title: title)
		button.addTarget(self, action: selector, for: .touchUpInside)
		return button
	}
}

class ViewController: UIViewController {
	
	enum ViewControllerType: CaseIterable {
		case unsuspecting
		case simple
		case stack
		case smallTableView
		case bigTableView
		case newSimple
		case resizingView
		case bigResizingView
		case newSimpleNav
	}
	
	let stackView = UIStackView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemGray
		
		stackView.axis = .vertical
		stackView.alignment = .fill
		stackView.distribution = .fillEqually
		stackView.spacing = 8
		
		view.addSubview(stackView)
		
		stackView.applyConstraints {
			$0.centerXAnchor.constraint(equalTo: view.centerXAnchor)
			$0.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		}
		
		ViewControllerType.allCases.forEach { type in
			let button = compatibleButton(title: "Show \(type) panel", isBig: true) { [unowned self] in
				present(type: type)
			}
			stackView.addArrangedSubview(button)
		}
	}
	
	func present(type: ViewControllerType) {
		let viewController: UIViewController
		switch type {
		case .unsuspecting:
			viewController = UnsuspectingViewController()
			let panelPresenter = PanelPresenter(viewController: viewController)
			panelPresenter.viewController = viewController
			return panelPresenter.present(from: self)
			// Make sure panelPresenter is still in memory when presenting the view controller
		case .simple: viewController = SimpleViewController()
		case .stack: viewController = StackViewController()
		case .smallTableView: viewController = TableViewController()
		case .bigTableView: viewController = TableViewController(cellCount: 86)
		case .newSimple: viewController = NewSimpleViewController()
		case .resizingView:
			viewController = ResizingViewController(cellCount: 8)
			let panelPresenter = PanelPresenter(viewController: viewController)
			panelPresenter.viewController = viewController
			panelPresenter.present(from: self)
			return
		case .bigResizingView:
			viewController = ResizingViewController(cellCount: 86)
			let panelPresenter = PanelPresenter(viewController: viewController)
			panelPresenter.viewController = viewController
			panelPresenter.present(from: self)
			return
		case .newSimpleNav:
			viewController = UINavigationController(rootViewController: NewSimpleViewController())
			let panelPresenter = PanelPresenter(viewController: viewController)
			panelPresenter.viewController = viewController
			panelPresenter.present(from: self)
			return
		}
		present(viewController, animated: true)
	}
}

