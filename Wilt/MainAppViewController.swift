import Foundation
import CoreData
import SwiftIcons

/// Once logged in, the main app will revolve around this controller and
/// different tabs will be used to navigate
class MainAppViewController: UITabBarController {
    weak var controllerDelegate: MainAppViewControllerDelegate?
    private var tabs = [(controller: UIViewController, title: String)]()
    private var container: NSPersistentContainer

    private lazy var profileTabItem: UITabBarItem = {
        let item = UITabBarItem(
            title: "profile_tab_title".localized,
            image: nil,
            selectedImage: nil
        )
        item.setIcon(
            icon: .emoji(.user),
            textColor: .lightGray,
            selectedTextColor: view.tintColor
        )
        item.tag = 0
        return item
    }()

    private lazy var feedTabItem: UITabBarItem = {
        let item = UITabBarItem(
            title: "feed_tab_title".localized,
            image: nil,
            selectedImage: nil
        )
        item.setIcon(
            icon: .emoji(.newspaper),
            textColor: .lightGray,
            selectedTextColor: view.tintColor
        )
        item.tag = 1
        return item
    }()

    private lazy var settingsBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(
            title: nil,
            style: .plain,
            target: self,
            action: #selector(onSettingsButtonPressed)
        )
        item.setIcon(
            icon: .emoji(.gearNoHub),
            iconSize: 22,
            color: view.tintColor
        )
        return item
    }()

    /// Create the main app controller
    ///
    /// - Parameters:
    ///   - container: Where data should be persisted
    ///   - api: Where data should be requested from
    init(container: NSPersistentContainer, api: WiltAPI) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
        delegate = self
        do {
            try self.setupTabs(
                container: container,
                api: api
            )
        } catch {
            // This is most likely a developer error that means the
            // cache is broken with no option of recovery
            fatalError("Unexpected error setting up app: \(error)")
        }
        navigationItem.rightBarButtonItem = settingsBarButton
        navigationItem.hidesBackButton = true
    }

    private func setupProfileController(container: NSPersistentContainer,
                                        api: WiltAPI) -> ProfileViewController {
        let cache = ProfileCache(
            backgroundContext: container.newBackgroundContext(),
            networkAPI: api
        )
        let controller = ProfileViewController(
            viewModel: ProfileViewModel(api: cache)
        )
        controller.tabBarItem = profileTabItem
        return controller
    }

    private func setupFeedController(container: NSPersistentContainer,
                                     api: WiltAPI) throws -> FeedViewController {
        let viewModel = FeedViewModel(
            dao: try PlayHistoryCache(viewContext: container.viewContext),
            api: api
        )
        viewModel.delegate = self
        let feedViewController = FeedViewController(viewModel: viewModel)
        feedViewController.tabBarItem = feedTabItem
        return feedViewController
    }

    private func setupTabs(container: NSPersistentContainer,
                           api: WiltAPI) throws {
        tabs = [
            (
                controller: setupProfileController(
                    container: container,
                    api: api
                ),
                title: "profile_title".localized
            ),
            (
                controller: try setupFeedController(
                    container: container,
                    api: api
                ),
                title: "feed_title".localized
            ),
        ]
        title = tabs[0].title
        viewControllers = tabs.map { $0.controller }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
    }

    @objc private func onSettingsButtonPressed() {
        controllerDelegate?.showSettings()
    }
}

extension MainAppViewController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard item.tag < tabs.count else {
            return
        }
        title = tabs[item.tag].title
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
    func showSettings()
    func loggedOut()
}
