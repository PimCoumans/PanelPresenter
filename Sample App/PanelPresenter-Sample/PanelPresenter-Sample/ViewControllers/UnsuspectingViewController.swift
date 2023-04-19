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
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(simpleView)
		simpleView.extendToSuperviewSafeArea()
		simpleView.heightAnchor.constraint(equalToConstant: 400).isActive = true
	}
}
