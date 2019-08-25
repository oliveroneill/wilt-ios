import UIKit

/// Coordinating navigation for the walkthrough
class WalkthroughCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    internal var childCoordinators = [Coordinator]()
    weak var delegate: WalkthroughCoordinatorDelegate?

    required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let controller = WalkthroughViewController()
        controller.delegate = self
        navigationController.pushViewController(controller, animated: false)
    }
}

extension WalkthroughCoordinator: WalkthroughViewControllerDelegate {
    func onSignInButtonPressed() {
        // TODO
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol WalkthroughCoordinatorDelegate: class {
    func loggedIn()
}
