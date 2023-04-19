//
//  UnsuspectingTableViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 21/07/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class ResizingViewController: UIViewController, PanelPresentable {

	var showingTableView: Bool = true
	var panelScrollView: UIScrollView? {
		showingTableView ? tableView : nil
	}

	private lazy var contentView: UIView = {
		let view = UIView()
		let multilineLabel = UILabel()
		multilineLabel.text = "To make use of the behavior that PanelPresenter provides, make sure your view controller conforms to PanelPresentable and set the presenter’s viewController property to self in your initializer. Doing this at a later stage will result in weird stuff.\nJust add your views to your view, which will be added to panelPresenter's scroll view. And any navigation-type views can be placed in the headerContentView which will be displayed above your content and will stick to the top of the screen when scrolling."
		multilineLabel.numberOfLines = 0
		multilineLabel.textColor = .label
		multilineLabel.contentMode = .top
		view.addSubview(multilineLabel)
		multilineLabel.extendToSuperviewLayoutMargins()
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleView)))
		return view
	}()
	
	let numberOfCells: Int

	init(cellCount: Int = 8) {
		numberOfCells = cellCount
		super.init(nibName: nil, bundle: nil)
	}

	private lazy var tableView: UITableView = {
		let tableView = UITableView(frame: self.view.bounds, style: .plain)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		tableView.delegate = self
		tableView.dataSource = self
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

	@objc func toggleView() {
		showingTableView.toggle()
		if showingTableView {
			contentView.removeFromSuperview()
			view.addSubview(tableView)
			tableView.extendToSuperview()
		} else {
			tableView.removeFromSuperview()
			if contentView.bounds.isEmpty {
				let safeAreaRect = view.bounds.inset(by: view.safeAreaInsets)
				let size = contentView.systemLayoutSizeFitting(
					safeAreaRect.size,
					withHorizontalFittingPriority: .defaultHigh,
					verticalFittingPriority: .defaultHigh
				)
				contentView.frame = CGRect(
					origin: safeAreaRect.origin,
					size: size
				)
				contentView.layoutIfNeeded()
			}
			view.addSubview(contentView)
			contentView.extendToSuperviewSafeArea()
		}
		let transition = CATransition()
		transition.type = .fade
		transition.duration = 0.15
		transition.timingFunction = CAMediaTimingFunction(name: .easeIn)
		view.layer.add(transition, forKey: "crossFade")
		panelPresentationController?.animateChanges {
			self.panelPresentationController?.setNeedsScrollViewUpdate()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		panelPresentationController?.showsHeader = true
		let titleLabel = UILabel()
		titleLabel.text = "Tap anywhere to toggle content"
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.textAlignment = .center
		panelPresentationController?.headerView.addSubview(titleLabel)
		titleLabel.extendToSuperviewLayoutMargins()

		view.addSubview(tableView)
		tableView.backgroundColor = .clear
		tableView.extendToSuperview()
		panelPresentationController?.topInset = 20
	}
}

extension ResizingViewController {
	@objc func didPressDoneButton(button: UIButton) {
		presentingViewController?.dismiss(animated: true)
	}
}

extension ResizingViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		toggleView()
		return nil
	}
}

extension ResizingViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		numberOfCells
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		cell.textLabel?.text = "Table Cell \(indexPath.row)"
		cell.backgroundColor = .clear
		cell.textLabel?.textColor = .label

		return cell
	}
}
