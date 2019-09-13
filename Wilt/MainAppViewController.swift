import Foundation
import CoreData

/// Once logged in, the main app will revolve around this controller and
/// different tabs will be used to navigate
class MainAppViewController: UITabBarController {
    weak var controllerDelegate: MainAppViewControllerDelegate?

    /// Create the main app controller
    ///
    /// - Parameters:
    ///   - database: Where data should be persisted
    ///   - api: Where data should be requested from
    init(database: WiltDatabase, api: WiltAPI) {
        super.init(nibName: nil, bundle: nil)
        database.loadContext { [unowned self] in
            switch ($0) {
            case .success(let context):
                do {
                    try self.setupTabs(
                        context: context,
                        api: api
                    )
                } catch {
                    // This is most likely a developer error that means the
                    // cache is broken with no option of recovery
                    fatalError("Unexpected error setting up app: \(error)")
                }
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

    private func setupTabs(context: NSManagedObjectContext,
                           api: WiltAPI) throws {
        let viewModel = FeedViewModel(
            dao: try PlayHistoryCache(viewContext: context),
            api: api
        )
        viewModel.delegate = self
        let feedViewController = FeedViewController(viewModel: viewModel)
        feedViewController.tabBarItem = UITabBarItem(
            tabBarSystemItem: .recents,
            tag: 0
        )
        viewControllers = [feedViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
    }
}

extension MainAppViewController: FeedViewModelDelegate {
    func loggedOut() {
        controllerDelegate?.loggedOut()
    }
}

/// Delegate for the `MainAppViewController` for events that occur in the
/// main app
protocol MainAppViewControllerDelegate: class {
    func loggedOut()
}
