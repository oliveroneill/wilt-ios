import Foundation
import CoreData
import SwiftIcons

/// Once logged in, the main app will revolve around this controller and
/// different tabs will be used to navigate
final class MainAppViewController: UITabBarController {
    weak var controllerDelegate: MainAppViewControllerDelegate?
    private var tabs = [
        (
            controller: UIViewController,
            title: String,
            leftBarButton: UIBarButtonItem?
        )
    ]()
    private var container: NSPersistentContainer

    private lazy var listenLaterTabItem: UITabBarItem = {
        let item = UITabBarItem(
            title: "listen_later_tab_title".localized,
            image: nil,
            selectedImage: nil
        )
        item.setIcon(
            icon: .emoji(.clock),
            textColor: .lightGray,
            selectedTextColor: view.tintColor
        )
        item.tag = 0
        return item
    }()

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
        item.tag = 1
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
        item.tag = 2
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
        let viewModel = ProfileViewModel(api: cache)
        viewModel.delegate = self
        let controller = ProfileViewController(
            viewModel: viewModel
        )
        controller.tabBarItem = profileTabItem
        return controller
    }

    private func setupFeedController(container: NSPersistentContainer,
                                     api: WiltAPI) throws -> FeedViewController {
        let viewModel = FeedViewModel(
            historyDao: try PlayHistoryCache(viewContext: container.viewContext),
            api: api,
            listenLaterDao: ListenLaterNotifyingStore(
                dao: try ListenLaterStore(viewContext: container.viewContext)
            )
        )
        viewModel.delegate = self
        let feedViewController = FeedViewController(viewModel: viewModel)
        feedViewController.tabBarItem = feedTabItem
        return feedViewController
    }

    private func setupListenLaterController(container: NSPersistentContainer) throws -> ListenLaterViewController {
        let viewModel = ListenLaterViewModel(
            dao: ListenLaterNotifyingStore(
                dao: try ListenLaterStore(viewContext: container.viewContext)
            )
        )
        viewModel.delegate = self
        let listenLaterViewController = ListenLaterViewController(viewModel: viewModel)
        listenLaterViewController.tabBarItem = listenLaterTabItem
        return listenLaterViewController
    }

    private func setupTabs(container: NSPersistentContainer,
                           api: WiltAPI) throws {
        tabs = [
            (
                controller: try setupListenLaterController(container: container),
                title: "listen_later_title".localized,
                leftBarButton: UIBarButtonItem(
                    barButtonSystemItem: .add, target: self,
                    action: #selector(onAddArtistButtonPressed)
                )
            ),
            (
                controller: setupProfileController(
                    container: container,
                    api: api
                ),
                title: "profile_title".localized,
                leftBarButton: nil
            ),
            (
                controller: try setupFeedController(
                    container: container,
                    api: api
                ),
                title: "feed_title".localized,
                leftBarButton: nil
            ),
        ]
        title = tabs[0].title
        navigationItem.leftBarButtonItem = tabs[0].leftBarButton
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

    @objc private func onAddArtistButtonPressed() {
        controllerDelegate?.showSearch()
    }
}

extension MainAppViewController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard item.tag < tabs.count else {
            return
        }
        title = tabs[item.tag].title
        navigationItem.leftBarButtonItem = tabs[item.tag].leftBarButton
    }
}

extension MainAppViewController: FeedViewModelDelegate, ProfileViewModelDelegate, ListenLaterViewModelDelegate {
    func open(url: URL) {
        controllerDelegate?.open(url: url)
    }

    func loggedOut() {
        controllerDelegate?.loggedOut()
    }
}

/// Delegate for the `MainAppViewController` for events that occur in the
/// main app
protocol MainAppViewControllerDelegate: class {
    func open (url: URL)
    func showSettings()
    func showSearch()
    func loggedOut()
}
