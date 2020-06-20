import Foundation
import UIKit

/// The coordinator for the entire app
final class WiltAppCoordinator: Coordinator {
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
            showOnboarding()
        }
    }

    func dismiss() {
        // This is the root coordinator, so dismissing would mean closing the
        // app
        fatalError("The root coordinator should not be dismissed")
    }

    func spotifyAuthComplete(application: UIApplication, url: URL,
                             options: [UIApplication.OpenURLOptionsKey : Any]) {
        // We need to return this response back to the SpotifyAuthoriser,
        // which should be stored in the first child coordinator in the ideal
        // case
        if let coordinator = childCoordinators.last as? OnboardingCoordinator {
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

    private func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(
            navigationController: navigationController,
            auth: auth
        )
        childCoordinators.append(onboardingCoordinator)
        onboardingCoordinator.delegate = self
        onboardingCoordinator.start()
    }
}

extension WiltAppCoordinator: OnboardingCoordinatorDelegate {
    func loggedIn(userID: String) {
        childCoordinators.last?.dismiss()
        showContent(database: database)
    }
}

extension WiltAppCoordinator: LoggedInCoordinatorDelegate {
    func contactUs() {
        UIApplication.shared.open(
            URL(string: "mailto:contact.wiltapp@gmail.com")!,
            options: [:],
            completionHandler: nil
        )
    }

    func logOut() {
        defer {
            childCoordinators.last?.dismiss()
            showOnboarding()
        }
        do {
            try auth.logOut()
        } catch {
            print("Failed to logout:", error)
            // TODO: not sure what to do here
        }
    }
}
