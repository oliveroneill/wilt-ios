import UIKit
import Keys

/// Coordinating navigation for the onboarding
final class OnboardingCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()
    private let spotifyAuthoriser: SpotifyAuthoriser
    private let auth: Authenticator
    weak var delegate: OnboardingCoordinatorDelegate?
    // Will be non-nil if the settings page is being presented and nil when
    // not visible
    private var settingsController: UINavigationController?

    init(navigationController: UINavigationController,
         auth: Authenticator = FirebaseAuthentication(),
         spotifyAuthoriser: SpotifyAuthoriser = SpotifyAppAuthoriser()) {
        self.navigationController = navigationController
        self.auth = auth
        self.spotifyAuthoriser = spotifyAuthoriser
    }

    func start() {
        let viewModel = OnboardingViewModel(userAuthenticator: auth)
        let controller = OnboardingViewController(viewModel: viewModel)
        viewModel.delegate = self
        navigationController.pushViewController(controller, animated: false)
    }

    /// Called when `AppDelegate` gets called when Spotify returns from
    /// auth process
    func spotifyAuthComplete(application: UIApplication, url: URL,
                             options: [UIApplication.OpenURLOptionsKey : Any]) {
        spotifyAuthoriser.authorisationComplete(
            application: application,
            url: url,
            options: options
        )
    }

    func dismiss() {
        navigationController.popViewController(animated: false)
        _ = childCoordinators.popLast()
    }
}

extension OnboardingCoordinator: OnboardingViewModelDelegate {
    func showLogin(onComplete: @escaping ((Result<String, Error>) -> Void)) {
        spotifyAuthoriser.authorise(
            from: navigationController,
            onComplete: onComplete
        )
    }

    func showInfo() {
        let controller = SettingsViewController(loggedIn: false)
        controller.delegate = self
        let toPresent = UINavigationController(rootViewController: controller)
        toPresent.modalPresentationStyle = .popover
        settingsController = toPresent
        navigationController.present(
            toPresent,
            animated: true,
            completion: nil
        )
    }

    func loggedIn(userID: String) {
        delegate?.loggedIn(userID: userID)
    }
}

extension OnboardingCoordinator: SettingsViewControllerDelegate {
    func contactUs() {
        delegate?.contactUs()
    }

    func close() {
        guard let controller = settingsController else { return }
        controller.dismiss(animated: true, completion: nil)
        settingsController = nil
    }

    // This shouldn't be called
    func logOut() {}
}

/// Delegate for the `OnboardingCoordinator` for events that occur during
/// onboarding
protocol OnboardingCoordinatorDelegate: class {
    func loggedIn(userID: String)
    func contactUs()
}
