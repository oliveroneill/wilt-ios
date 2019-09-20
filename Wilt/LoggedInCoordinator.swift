/// A coordinator to handle the flow once the user is logged in
class LoggedInCoordinator: Coordinator {
    private let database: WiltDatabase
    private let api: WiltAPI
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    weak var delegate: LoggedInCoordinatorDelegate?
    // Will be non-nil if the settings page is being presented and nil when
    // not visible
    private var settingsController: UINavigationController?

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
    func showSettings() {
        let controller = SettingsViewController()
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

    func loggedOut() {
        delegate?.logOut()
    }
}

extension LoggedInCoordinator: SettingsViewControllerDelegate {
    func contactUs() {
        delegate?.contactUs()
    }

    private func closeSettings(completionHandler: @escaping () -> Void) {
        guard let controller = settingsController else { return }
        controller.dismiss(animated: false, completion: completionHandler)
        settingsController = nil
    }

    func close() {
        closeSettings { }
    }

    func logOut() {
        closeSettings { [unowned self] in
            self.delegate?.logOut()
        }
    }
}

/// Delegate for the `WalkthroughCoordinator` for events that occur during the
/// walkthrough
protocol LoggedInCoordinatorDelegate: class {
    func contactUs()
    func logOut()
}
