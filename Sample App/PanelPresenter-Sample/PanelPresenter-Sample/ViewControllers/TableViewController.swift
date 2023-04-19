//
//  TableViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 21/07/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class TableViewController: UIViewController, PanelPresentable {

	let panelPresenter = PanelPresenter()

	var panelScrollView: UIScrollView? {
		tableView
	}
	
	let numberOfCells: Int

	init(cellCount: Int = 8) {
		numberOfCells = cellCount
		super.init(nibName: nil, bundle: nil)
		panelPresenter.viewController = self
	}

	private lazy var tableView: UITableView = {
		let tableView = UITableView(frame: self.view.bounds, style: .plain)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		tableView.dataSource = self
		tableView.backgroundColor = .clear
		return tableView
	}()

	private lazy var titleView: UILabel = {
		let label = UILabel()
		label.text = "Some TableView"
		label.textColor = .label
		label.font = .preferredFont(forTextStyle: .title2)
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	private lazy var doneButton: UIButton = compatibleButton(title: "Done", selector: #selector(didPressDoneButton))

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(tableView)
		tableView.extendToSuperview()

		guard let headerView = panelPresentationController?.headerView else {
			return
		}
		headerView.addSubview(titleView)
		headerView.addSubview(doneButton)
		doneButton.applyConstraints {
			$0.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor)
			$0.topAnchor.constraint(equalTo: headerView.layoutMarginsGuide.topAnchor)
			$0.bottomAnchor.constraint(equalTo: headerView.layoutMarginsGuide.bottomAnchor)
		}

		titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		let centerX = titleView.centerXAnchor.constraint(equalTo: headerView.layoutMarginsGuide.centerXAnchor)
		centerX.priority = .defaultLow
		titleView.applyConstraints {
			$0.topAnchor.constraint(equalTo: headerView.layoutMarginsGuide.topAnchor)
			$0.bottomAnchor.constraint(equalTo: headerView.layoutMarginsGuide.bottomAnchor)
			$0.trailingAnchor.constraint(lessThanOrEqualTo: doneButton.leadingAnchor, constant: 10)
			$0.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.layoutMarginsGuide.leadingAnchor)
			centerX
		}
	}
}

extension TableViewController {
	@objc func didPressDoneButton(button: UIButton) {
		presentingViewController?.dismiss(animated: true)
	}
}

extension TableViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		numberOfCells
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.backgroundColor = .clear
		let textField = cell.contentView.subviews.lazy.compactMap { $0 as? UITextField }.first ?? UITextField()
		textField.setContentHuggingPriority(.defaultLow, for: .vertical)
		textField.text = "Table Cell \(indexPath.row)"
		cell.contentView.addSubview(textField)
		textField.extendToSuperviewLayoutMargins()

		return cell
	}
}
