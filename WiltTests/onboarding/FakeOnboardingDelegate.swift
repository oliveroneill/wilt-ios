@testable import Wilt

final class FakeOnboardingDelegate: OnboardingViewModelDelegate {
    var loggedInCalls = [String]()
    var showLoginCallCount = 0
    var showInfoCallCount = 0
    private var showLoginResult: Result<String, Error>?

    init(showLoginResult: Result<String, Error>? = nil) {
        self.showLoginResult = showLoginResult
    }

    func loggedIn(userID: String) {
        loggedInCalls.append(userID)
    }

    func showLogin(onComplete: @escaping ((Result<String, Error>) -> Void)) {
        showLoginCallCount += 1
        if let showLoginResult = showLoginResult {
            onComplete(showLoginResult)
        }
    }

    func showInfo() {
        showInfoCallCount += 1
    }
}
