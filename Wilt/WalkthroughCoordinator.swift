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
        let redirectURI = WiltKeys().spotifyRedirectURI
        spotifyAuthoriser.authorise { [unowned self] in
            guard let authCode = try? $0.get() else {
                print("Spotify error")
                // TODO
                return
            }
            self.auth.signUp(authCode: authCode, redirectURI: redirectURI) { [unowned self] in
                guard let token = try? $0.get() else {
                    print("Sign up error")
                    // TODO
                    return
                }
                self.auth.login(token: token) {
                    guard let userID = try? $0.get() else {
                        print("Login error")
                        // TODO
                        return
                    }
                    print("Logged in", userID)
                }
            }
        }
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol WalkthroughCoordinatorDelegate: class {
    func loggedIn()
}
