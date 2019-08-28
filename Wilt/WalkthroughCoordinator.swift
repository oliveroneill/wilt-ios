import UIKit

/// Coordinating navigation for the walkthrough
class WalkthroughCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()
    private let spotifyAuthoriser: SpotifyAuthoriser
    weak var delegate: WalkthroughCoordinatorDelegate?

    init(navigationController: UINavigationController,
         spotifyAuthoriser: SpotifyAuthoriser = SpotifyAppAuthoriser()) {
        self.navigationController = navigationController
        self.spotifyAuthoriser = spotifyAuthoriser
    }

    func start() {
        let controller = WalkthroughViewController()
        controller.delegate = self
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
}

extension WalkthroughCoordinator: WalkthroughViewControllerDelegate {
    func onSignInButtonPressed() {
        spotifyAuthoriser.authorise { _ in
            // TODO: firebase auth but different since we already have
            // the token and stuff
        }
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol WalkthroughCoordinatorDelegate: class {
    func loggedIn()
}
