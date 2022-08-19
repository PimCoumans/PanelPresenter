//
//  UnsuspectingViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 15/08/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class UnsuspectingViewController: UIViewController {
	
	init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	private lazy var simpleView: UIView = {
		let view = UIView()
		view.backgroundColor = .systemRed
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
		
		if let headerContentView = presentingPanelPresenter?.headerContentView {
			headerContentView.addSubview(cancelButton)
			cancelButton.applyConstraints {
				$0.leadingAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.leadingAnchor)
				$0.centerYAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.centerYAnchor)
			}
		}
	}
}
