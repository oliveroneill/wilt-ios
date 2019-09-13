/// A coordinator to handle the flow once the user is logged in
class LoggedInCoordinator: Coordinator {
    private let database: WiltDatabase
    private let api: WiltAPI
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    weak var delegate: LoggedInCoordinatorDelegate?

    init(navigationController: UINavigationController, database: WiltDatabase,
         api: WiltAPI) {
        self.navigationController = navigationController
        self.database = database
        self.api = api
    }

    func start() {
        let controller = MainAppViewController(
            database: database,
            api: api
        )
        controller.controllerDelegate = self
        navigationController.pushViewController(controller, animated: false)
    }
}

extension LoggedInCoordinator: MainAppViewControllerDelegate {
    func loggedOut() {
        delegate?.loggedOut()
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol LoggedInCoordinatorDelegate: class {
    func loggedOut()
}
