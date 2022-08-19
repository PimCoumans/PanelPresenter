//
//  SimpleViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class SimpleViewController: UIViewController, PanelPresentable {
	
	let panelPresenter = PanelPresenter()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		panelPresenter.viewController = self
	}
	
	private lazy var simpleView: UIView = {
		let view = UIView()
		if #available(iOS 15.0, *) {
			view.backgroundColor = .systemMint.withAlphaComponent(0.25)
		} else {
			view.backgroundColor = .green.withAlphaComponent(0.25)
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
		super.viewDidLoad()
		
		view.addSubview(simpleView)
		simpleView.extendToSuperview()
		simpleView.heightAnchor.constraint(equalToConstant: 400).isActive = true
		
		headerContentView.addSubview(cancelButton)
		cancelButton.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.leadingAnchor)
			$0.centerYAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.centerYAnchor)
		}
	}
}
