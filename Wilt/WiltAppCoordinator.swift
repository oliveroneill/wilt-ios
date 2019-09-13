import Foundation
import UIKit

/// The coordinator for the entire app
class WiltAppCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()
    private let auth = FirebaseAuthentication()
    private let api = FirebaseAPI()
    private let database = WiltDatabase()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        if let _ = auth.currentUser {
            showContent(database: database)
        } else {
            showWalkthrough()
        }
    }

    func spotifyAuthComplete(application: UIApplication, url: URL,
                             options: [UIApplication.OpenURLOptionsKey : Any]) {
        // We need to return this response back to the SpotifyAuthoriser,
        // which should be stored in the first child coordinator in the ideal
        // case
        if let coordinator = childCoordinators.first as? WalkthroughCoordinator {
            coordinator.spotifyAuthComplete(
                application: application,
                url: url,
                options: options
            )
        }
    }
    
    private func showContent(database: WiltDatabase) {
        let loggedInCoordinator = LoggedInCoordinator(
            navigationController: navigationController,
            database: database,
            api: api
        )
        childCoordinators.append(loggedInCoordinator)
        loggedInCoordinator.delegate = self
        loggedInCoordinator.start()
    }

    private func showWalkthrough() {
        let walkthroughCoordinator = WalkthroughCoordinator(
            navigationController: navigationController,
            auth: auth
        )
        childCoordinators.append(walkthroughCoordinator)
        walkthroughCoordinator.delegate = self
        walkthroughCoordinator.start()
    }
}

extension WiltAppCoordinator: WalkthroughCoordinatorDelegate {
    func loggedIn(userID: String) {
        showContent(database: database)
    }
}

extension WiltAppCoordinator: LoggedInCoordinatorDelegate {
    func loggedOut() {
        showWalkthrough()
    }
}
