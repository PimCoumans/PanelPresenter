//
//  SimpleViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class NewSimpleViewController: UIViewController, PanelPresentable {

	let panelPresenter: PanelPresenter? = PanelPresenter()

	init() {
		super.init(nibName: nil, bundle: nil)
		panelPresenter?.viewController = self
	}

	private lazy var simpleView: UIView = {
		let view = UIView()
		if #available(iOS 15.0, *) {
			view.backgroundColor = .systemRed.withAlphaComponent(0.5)
		} else {
			view.backgroundColor = .red.withAlphaComponent(0.5)
		}
		return view
	}()

	private lazy var cancelButton: UIButton = compatibleButton(title: "Cancel") { [unowned self] in
		self.presentingViewController?.dismiss(animated: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		panelPresentationController?.shouldAdjustPresenterTintMode = false
		panelPresentationController?.topInset = 200
		view.backgroundColor = .blue.withAlphaComponent(0.25)
		view.addSubview(simpleView)
		simpleView.extendToSuperviewSafeArea()
		simpleView.applyConstraints {
			$0.heightAnchor.constraint(equalToConstant: 200)//.withPriority(UILayoutPriority(999))
		}
		super.viewDidLoad()

	}
}
