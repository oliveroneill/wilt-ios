import Foundation
import UIKit

/// The coordinator for the entire app
class WiltAppCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showWalkthrough()
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
    
    private func showContent() {

    }

    private func showWalkthrough() {
        let walkthroughCoordinator = WalkthroughCoordinator(
            navigationController: navigationController
        )
        childCoordinators.append(walkthroughCoordinator)
        walkthroughCoordinator.delegate = self
        walkthroughCoordinator.start()
    }
}

extension WiltAppCoordinator: WalkthroughCoordinatorDelegate {
    func loggedIn() {
        showContent()
    }
}
