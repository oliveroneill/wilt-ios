import UIKit

/// The controller for the entire walkthrough, made up of a page view
/// controller and a button
class WalkthroughViewController: UIViewController {
    private let walkthroughController = WalkthroughIntroViewController()
    weak var delegate: WalkthroughViewControllerDelegate?
    private var walkthroughView: UIView!
    private var signUpButton: UIButton!

    override func loadView() {
        super.loadView()
        // Used for testing with KIF
        view.accessibilityLabel = "walkthrough_view"
        setupWalkthroughView()
        setupSignUpButton()
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSignUpButtonAppearance()
    }

    private func setupSignUpButtonAppearance() {
        // Used for testing with KIF
        signUpButton.accessibilityLabel = "sign_in_button"
        // Set text
        signUpButton.setTitle("sign_in_text".localized, for: .normal)
        signUpButton.titleLabel?.textColor = .white
        // Set background colour
        let darkBlue = UIColor(red: 0, green: 0.41, blue: 0.89, alpha: 1)
        signUpButton.setBackgroundColor(view.tintColor, for: .normal)
        signUpButton.setBackgroundColor(darkBlue, for: .highlighted)
        // Set corner radius
        signUpButton.layer.cornerRadius = 4
        // On tap listener
        signUpButton.addTarget(
            self,
            action: #selector(signUpButtonPressed),
            for: .touchUpInside
        )
    }

    private func setupWalkthroughView() {
        addChild(walkthroughController)
        walkthroughView = walkthroughController.view!
        view.addSubview(walkthroughView)
        walkthroughView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            walkthroughView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            walkthroughView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            walkthroughView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            walkthroughView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -64
            ),
        ])
    }

    private func setupSignUpButton() {
        signUpButton = UIButton(frame: .zero)
        view.addSubview(signUpButton)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(
                equalTo: walkthroughView.bottomAnchor,
                constant: 8
            ),
            signUpButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            signUpButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
            signUpButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
        ])
    }

    @objc private func signUpButtonPressed(sender: UIButton!) {
        delegate?.onSignInButtonPressed()
    }
}

/// The delegate for events that occur within the walkthrough view
protocol WalkthroughViewControllerDelegate: class {
    func onSignInButtonPressed()
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        clipsToBounds = true
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        setBackgroundImage(
            UIGraphicsGetImageFromCurrentImageContext(),
            for: state
        )
        UIGraphicsEndImageContext()
    }
}
