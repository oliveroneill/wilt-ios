import UIKit

/// The controller for the entire walkthrough, made up of a page view
/// controller and a button
class WalkthroughViewController: UIViewController {
    private let walkthroughController = WalkthroughIntroViewController()
    private let errorPage = WalkthroughPage(
        text: "login_error_text".localized,
        image: #imageLiteral(resourceName: "ErrorScreen")
    )
    private var walkthroughView: UIView!
    private var signUpButton: UIButton!
    private var loadingSpinner: UIActivityIndicatorView!
    private var errorView: UIView!
    private var loadingLabel: UILabel!
    private let viewModel: WalkthroughViewModel

    init(viewModel: WalkthroughViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.onViewUpdate = { [unowned self] in
            self.onViewUpdate(state: $0)
        }
        navigationItem.hidesBackButton = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        // Used for testing with KIF
        view.accessibilityLabel = "walkthrough_view"
        setupWalkthroughView()
        setupSignUpButton()
        setupLoadingSpinner()
        setuploadingLabel()
        setupErrorView()
        // Hide all views until the viewModel tells us to show them
        walkthroughView.isHidden = true
        signUpButton.isHidden = true
        loadingSpinner.stopAnimating()
        errorView.isHidden = true
        loadingLabel.isHidden = true
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSignUpButtonAppearance()
        setupLoadingSpinnerAppearance()
        setupLoadingLabelAppearance()
        // Tell the viewModel that we're ready to receive events
        viewModel.onViewAppeared()
    }

    private func onViewUpdate(state: WalkthroughViewState) {
        DispatchQueue.main.async { [unowned self] in
            switch (state) {
            case .walkthrough:
                self.displayWalkthrough()
            case .loginError:
                self.displayError()
            case .authenticating:
                self.displayLoadingSpinner()
            }
        }
    }

    private func displayWalkthrough() {
        // Hide unused views
        loadingSpinner.stopAnimating()
        loadingLabel.isHidden = true
        errorView.isHidden = true
        // Update visible views
        signUpButton.setTitle("sign_in_text".localized, for: .normal)
        walkthroughView.isHidden = false
        signUpButton.isHidden = false
    }

    private func displayError() {
        // Hide unused views
        loadingSpinner.stopAnimating()
        loadingLabel.isHidden = true
        // Update visible views
        signUpButton.setTitle("try_again_text".localized, for: .normal)
        signUpButton.isHidden = false
        errorView.isHidden = false
    }

    private func displayLoadingSpinner() {
        // Hide unused views
        walkthroughView.isHidden = true
        signUpButton.isHidden = true
        errorView.isHidden = true
        // Update visible views
        loadingSpinner.startAnimating()
        loadingLabel.isHidden = false
    }

    private func setupLoadingSpinner() {
        loadingSpinner = UIActivityIndicatorView(frame: .zero)
        loadingSpinner.hidesWhenStopped = true
        view.addSubview(loadingSpinner)
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingSpinner.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor
            ),
            loadingSpinner.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            ),
        ])
    }

    private func setuploadingLabel() {
        loadingLabel = UILabel(frame: .zero)
        view.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingLabel.topAnchor.constraint(
                equalTo: loadingSpinner.bottomAnchor,
                constant: 8
            ),
            loadingLabel.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            loadingLabel.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
            loadingLabel.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 64
            )
        ])
    }

    private func setupLoadingLabelAppearance() {
        loadingLabel.numberOfLines = 0
        loadingLabel.text = "logging_in_text".localized
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .gray
    }

    private func setupLoadingSpinnerAppearance() {
        loadingSpinner.color = .gray
    }

    private func setupSignUpButtonAppearance() {
        // Used for testing with KIF
        signUpButton.accessibilityLabel = "sign_in_button"
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

    private func setupErrorView() {
        addChild(errorPage)
        errorView = errorPage.view!
        view.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            errorView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            errorView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            errorView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -64
            ),
        ])
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
        viewModel.onSignInButtonPressed()
    }
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
