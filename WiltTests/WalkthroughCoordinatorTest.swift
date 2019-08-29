import XCTest

@testable import Wilt

class WalkthroughCoordinatorTest: XCTestCase {
    class FakeAuthoriser: SpotifyAuthoriser {
        var authoriseCallCount = 0
        var authorisationCompleteCallCount = 0

        func authorise(onComplete: @escaping ((Result<String, Error>) -> Void)) {
            authoriseCallCount += 1
        }

        func authorisationComplete(application: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
            authorisationCompleteCallCount += 1
        }
    }

    class FakeAuthenticator: Authenticator {
        var signUpCallCount = 0
        var loginCallCount = 0

        var currentUser: String? = nil

        func signUp(authCode: String, redirectURI: String, callback: @escaping (Result<String, Error>) -> Void) {
            signUpCallCount += 1
        }

        func login(token: String, callback: @escaping (Result<String, Error>) -> Void) {
            loginCallCount += 1
        }
    }

    func testOnSignInButtonPressed() {
        let mockAuthoriser = FakeAuthoriser()
        let mockAuthenticator = FakeAuthenticator()
        let coordinator = WalkthroughCoordinator(
            navigationController: UINavigationController(),
            auth: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        coordinator.onSignInButtonPressed()
        XCTAssertEqual(1, mockAuthoriser.authoriseCallCount)
    }

    func testSpotifyAuthComplete() {
        let mockAuthoriser = FakeAuthoriser()
        let mockAuthenticator = FakeAuthenticator()
        let coordinator = WalkthroughCoordinator(
            navigationController: UINavigationController(),
            auth: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        coordinator.spotifyAuthComplete(
            application: UIApplication.shared,
            url: URL(string: "http://notarealdomainok.com/")!,
            options: [:]
        )
        XCTAssertEqual(1, mockAuthoriser.authorisationCompleteCallCount)
    }

    // TODO: test all the cases for auth
}
