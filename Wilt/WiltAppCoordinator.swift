import Foundation
import UIKit

/// The coordinator for the entire app
class WiltAppCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()

    required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showWalkthrough()
    }

    func showContent() {

    }

    func showWalkthrough() {
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
