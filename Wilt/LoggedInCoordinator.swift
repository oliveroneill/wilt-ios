import CoreData

/// A coordinator to handle the flow once the user is logged in
final class LoggedInCoordinator: Coordinator {
    private let database: WiltDatabase
    private let api: WiltAPI
    private let artistActivityCache: ArtistActivityCache
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    weak var delegate: LoggedInCoordinatorDelegate?
    // Will be non-nil if there's a modular page being presented and nil when
    // not visible
    private var currentController: UINavigationController?
    private var container: NSPersistentContainer?

    init(navigationController: UINavigationController, database: WiltDatabase,
         api: WiltAPI) {
        self.navigationController = navigationController
        self.database = database
        self.api = api
        self.artistActivityCache = ArtistActivityCache(networkAPI: api)
    }

    func start() {
        // Request notificaton permission. We ignore the result, since the
        // app can function either way
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { _, _ in }
        database.loadContext { [unowned self] in
            switch ($0) {
            case .success(let container):
                self.container = container
                let controller = MainAppViewController(
                    container: container,
                    api: self.api
                )
                controller.controllerDelegate = self
                self.navigationController.pushViewController(
                    controller,
                    animated: false
                )
            case .failure(let error):
                // This error might be recoverable, eg. if the device is out
                // of disk space. However, it's unlikely that clearing the
                // cache would free up enough space and I'm not sure whether
                // the user would care if we displayed an alert an exit vs
                // just exiting
                fatalError("Unexpected Core Data error: \(error)")
                break
            }
        }
    }

    func dismiss() {
        navigationController.popViewController(animated: false)
        _ = childCoordinators.popLast()
    }

    private func clearCacheAndLogOut() {
        // Clear the caches so that we don't cache data of the wrong user once
        // we log back in
        clearCaches()
        delegate?.logOut()
    }

    /// Clear all the data that we've stored in Core Data
    private func clearCaches() {
        _ = try? artistActivityCache.clear()
        guard let container = container else {
            return
        }
        container.viewContext.performAndWait {
            let entities = container.managedObjectModel.entities
            for entity in entities {
                guard let name = entity.name else {
                    // Not sure what to do in this case
                    continue
                }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                    entityName: name
                )
                let deleteRequest = NSBatchDeleteRequest(
                    fetchRequest: fetchRequest
                )
                // Ignore the error since I'm not sure what to do if it fails
                _ = try? container.persistentStoreCoordinator.execute(
                    deleteRequest,
                    with: container.viewContext
                )
            }
            _ = try? container.viewContext.save()
        }
    }
}

extension LoggedInCoordinator: MainAppViewControllerDelegate, ArtistSearchViewModelDelegate, ArtistDetailViewModelDelegate {
    func showDetail(artist: TopArtistData) {
        let viewModel = ArtistDetailViewModel(
            artist: ArtistInfo(
                name: artist.topArtist,
                imageURL: artist.imageURL,
                externalURL: artist.externalURL
            ),
            api: artistActivityCache
        )
        viewModel.delegate = self
        let controller = ArtistDetailViewController(viewModel: viewModel)
        let toPresent = UINavigationController(rootViewController: controller)
        toPresent.modalPresentationStyle = .popover
        currentController = toPresent
        navigationController.present(
            toPresent,
            animated: true,
            completion: nil
        )
    }

    func showSearch() {
        guard let container = container else { return }
        guard let store = try? ListenLaterStore(viewContext: container.viewContext) else {
            return
        }
        let viewModel = ArtistSearchViewModel(
            dao: ListenLaterNotifyingStore(dao: store),
            api: SpotifySearchAPI()
        )
        viewModel.delegate = self
        let controller = ArtistSearchViewController(viewModel: viewModel)
        // controller.delegate = self
        let toPresent = UINavigationController(rootViewController: controller)
        toPresent.modalPresentationStyle = .popover
        currentController = toPresent
        navigationController.present(
            toPresent,
            animated: true,
            completion: nil
        )
    }

    func onSearchExit() {
        closeCurrentController(animated: true) { [weak self] in
            guard let self = self else { return }
            // Since the search controller is a modal this doesn't get
            // triggered, which means that it's view won't be updated with the
            // new value. To fix this, we'll signal that the view is visible
            // ourselves. Not sure whether this should be the coordinator's
            // responsibility...
            let currentController = self.navigationController.visibleViewController
            guard let mainController = currentController as? MainAppViewController else {
                return
            }
            guard let controller = mainController.selectedViewController as? ListenLaterViewController else {
                return
            }
            controller.viewDidAppear(false)
        }
    }

    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func showSettings() {
        let controller = SettingsViewController()
        controller.delegate = self
        let toPresent = UINavigationController(rootViewController: controller)
        toPresent.modalPresentationStyle = .popover
        currentController = toPresent
        navigationController.present(
            toPresent,
            animated: true,
            completion: nil
        )
    }

    func loggedOut() {
        clearCacheAndLogOut()
    }
}

extension LoggedInCoordinator: SettingsViewControllerDelegate {
    func contactUs() {
        delegate?.contactUs()
    }

    private func closeCurrentController(animated: Bool = false,
                                        completionHandler: @escaping () -> Void) {
        guard let controller = currentController else { return }
        controller.dismiss(animated: animated, completion: completionHandler)
        currentController = nil
    }

    func close() {
        closeCurrentController(animated: true) { }
    }

    func logOut() {
        closeCurrentController { [unowned self] in
            self.clearCacheAndLogOut()
        }
    }
}

/// Delegate for the `OnboardingCoordinator` for events that occur during
/// onboarding
protocol LoggedInCoordinatorDelegate: class {
    func contactUs()
    func logOut()
}
