import UIKit
import Keys

/// Coordinating navigation for the walkthrough
class WalkthroughCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()
    private let spotifyAuthoriser: SpotifyAuthoriser
    private let auth: Authenticator
    weak var delegate: WalkthroughCoordinatorDelegate?

    init(navigationController: UINavigationController,
         auth: Authenticator = FirebaseAuthentication(),
         spotifyAuthoriser: SpotifyAuthoriser = SpotifyAppAuthoriser()) {
        self.navigationController = navigationController
        self.auth = auth
        self.spotifyAuthoriser = spotifyAuthoriser
    }

    func start() {
        let viewModel = WalkthroughViewModel(
            userAuthenticator: auth,
            spotifyAuthoriser: spotifyAuthoriser
        )
        let controller = WalkthroughViewController(viewModel: viewModel)
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
}

extension WalkthroughCoordinator: WalkthroughViewModelDelegate {
    func loggedIn(userID: String) {
        delegate?.loggedIn(userID: userID)
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol WalkthroughCoordinatorDelegate: class {
    func loggedIn(userID: String)
}
