# PanelPresenter

Add swipe-dismiss logic to your view controller, supporting Auto Layout and dynamic heights.

<img width="564" alt="image" src="https://user-images.githubusercontent.com/1199454/178160455-00e0d766-f9a1-42c4-bb45-d40f06e87747.png">


## Installation

Add this package to your project by searching `https://github.com/PimCoumans/PanelPresenter`.

To make use of the behavior that `PanelPresenter` provides, make sure your view controller conforms to `PanelPresentable` and set the presenter’s `viewController` property to `self` in your initializer. Doing this at a later stage will result in weird stuff.

```swift
class SimpleViewController: UIViewController, PanelPresentable {
    
    let panelPresenter = PanelPresenter()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        panelPresenter.viewController = self
    }
}
```

Just add your views to your `view`, which will be added to `panelPresenter`'s scroll view. And any navigation-type views can be placed in the `headerContentView` which will be displayed above your content and will stick to the top of the screen when scrolling.

```swift
    private lazy var simpleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemMint
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addAction(UIAction { [unowned self] _ in
            self.presentingViewController?.dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .black
        
        view.addSubview(simpleView)
        topContentView.addSubview(cancelButton)
        
        simpleView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            simpleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            simpleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            simpleView.topAnchor.constraint(equalTo: view.topAnchor),
            simpleView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            simpleView.heightAnchor.constraint(equalToConstant: 200),
            
            cancelButton.leadingAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.leadingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.centerYAnchor)
        ])
    }
```

## Example code

Check the sample app in the repository to see multiple supported scenarios for presenting your view as a panel, the simplest being comparable to the example shown above.
A more complex example is `StackViewController` where a bunch of random, multiline labels are dynamically added to a `UIStackView`. The height animates whenever the a label is added or removed. In the `animateChanges()` method an example is shown how to animate the height change by wrapping `panelPresenter.layoutIfNeeded()` in an animation closure.

## Questions?

Look me up on [twitter](https://twitter.com/pimcoumans)! ✌🏻
