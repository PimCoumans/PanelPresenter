//
//  StackViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 09/07/2022.
//

import UIKit
import PanelPresenter
import ConstraintBuilder

class StackViewController: UIViewController, PanelPresentable {
	
	let panelPresenter = PanelPresenter()
	
	private lazy var addButton: UIButton = compatibleButton(title: "Add", selector: #selector(didPressAddButton))
	private lazy var addALotButton: UIButton = compatibleButton(title: "Add a lot", selector: #selector(didPressAddALotButton))
	private lazy var removeButton: UIButton =  compatibleButton(title: "Remove", selector: #selector(didPressRemoveButton))
	
	private lazy var buttonStackView: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [addButton, addALotButton, removeButton])
		stackView.axis = .horizontal
		stackView.alignment = .fill
		stackView.distribution = .equalSpacing
		stackView.spacing = 20
		stackView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
		stackView.setContentHuggingPriority(.defaultLow, for: .vertical)
		return stackView
	}()
	
	private lazy var stackView: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.alignment = .leading
		stackView.distribution = .fill
		return stackView
	}()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		panelPresenter.viewController = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(stackView)
		stackView.extendToSuperviewLayoutMargins()

		panelPresentationController?.showsHeader = true
		panelPresentationController?.headerView.addSubview(buttonStackView)
		buttonStackView.extendToSuperviewLayoutMargins()
		
		addLabel(initialAlpha: 1)
	}
}

extension UIFont.Weight: CaseIterable {
	public static var allCases: [UIFont.Weight] {
		[
			.ultraLight,
			.thin,
			.light,
			.regular,
			.medium,
			.semibold,
			.bold,
			.heavy,
			.black
		]
	}
}

extension UIFont.TextStyle: CaseIterable {
	public static var allCases: [UIFont.TextStyle] {
		[
			.largeTitle,
			.title1,
			.title2,
			.title3,
			.headline,
			.subheadline,
			.body,
			.callout,
			.footnote,
			.caption1,
			.caption2
		]
	}
}

private extension StackViewController {
	
	var randomWord: String {
		[
			"enjoy",
			"great",
			"cat",
			"powerful",
			"awesome",
			"dismiss me",
			"auto",
			"layout",
			"what a world",
			"hello",
			"smells like wrongdog in here",
			"i like snacks",
			"so much words",
			"forgot translatesAutoresizingMaskIntoConstraints again",
			"this is pretty nifty",
			"yes, okay, well",
			"can’t get enough of this"
		].randomElement()!
	}
	
	var randomFontSize: CGFloat {
		.random(in: 24...64)
	}
	
	var randomTextStyle: UIFont.TextStyle {
		.allCases.randomElement()!
	}
	
	var randomFontWeight: UIFont.Weight {
		.allCases.randomElement()!
	}
	
	@objc func didPressAddButton() {
		addLabel()
		animateChanges()
		scrollToBottom()
	}
	
	@objc func didPressRemoveButton() {
		let animations = removeLabel()
		animateChanges(with: animations.change, completion: animations.completion)
	}
	
	@objc func didPressAddALotButton() {
		for _ in 0..<5 {
			addLabel()
		}
		animateChanges()
		scrollToBottom()
	}
	
	func animateChanges(with animation: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
		panelPresentationController?.animateChanges {
			self.stackView.arrangedSubviews.forEach { if !$0.isHidden { $0.alpha = 1 } }
			animation?()
		} completion: { _ in
			completion?()
		}
	}
	
	func scrollToBottom() {
		guard let scrollView = panelPresentationController?.containerScrollView else { return }
		let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
		scrollView.setContentOffset(bottomOffset, animated: true)
	}
	
	func addLabel(initialAlpha: CGFloat = 0) {
		
		let maxViewCount = 40
		
		guard stackView.arrangedSubviews.count <= maxViewCount else {
			return
		}
		
		let label = UILabel()
		let lastRandomWord = (stackView.arrangedSubviews.last as? UILabel)?.text
		var randomWord = lastRandomWord
		
		if stackView.arrangedSubviews.count == maxViewCount {
			randomWord = "let’s not get carried away"
		}
		
		while randomWord == lastRandomWord {
			randomWord = self.randomWord
		}
		
		label.text = randomWord
		label.numberOfLines = 0
		label.textColor = .label
		let fontMetrics = UIFontMetrics(forTextStyle: .body)
		
		label.font = fontMetrics.scaledFont(for: .systemFont(ofSize: randomFontSize, weight: randomFontWeight))
		label.adjustsFontForContentSizeCategory = true
		stackView.addArrangedSubview(label)
		
		// Calculate approximate initial frame to fix in-animation
		label.frame.size = label.sizeThatFits(CGSize(width: stackView.bounds.width, height: .greatestFiniteMagnitude))
		label.frame.origin.y = stackView.bounds.maxY
		label.alpha = initialAlpha
		
		label.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
		}
		
		removeButton.isEnabled = true
	}
	
	func removeLabel() -> (change: () -> Void, completion: () -> Void) {
		var result = (change: {}, completion: {})
		
		if let label = stackView.arrangedSubviews.last(where: { $0.isHidden == false }) {
			result.change = {
				label.transform = CGAffineTransform(translationX: label.frame.minX, y: label.frame.minY)
				self.stackView.removeArrangedSubview(label)
				label.alpha = 0
			}
			result.completion = {
				label.removeFromSuperview()
			}
		}
		
		if stackView.arrangedSubviews.filter({ $0.isHidden == false }).isEmpty {
			removeButton.isEnabled = false
		}
		return result
	}
}
