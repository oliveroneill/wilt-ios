import UIKit

/// A protocol for navigating between controllers. Based on Soroush Khanlou's
/// talk on Coordinators
protocol Coordinator {
    /// Used for navigating within a coordinator
    var navigationController: UINavigationController { get }

    /// We keep a list of subcoordinators in order to avoid losing reference
    /// to them
    var childCoordinators: [Coordinator] { get }

    /// Called to start the coordinator. This should navigate to the
    /// first controller in this coordinator's state
    func start()

    /// Dismiss the coordinator. This should remove any controllers on screen
    func dismiss()
}
