import XCTest

@testable import Wilt

class WalkthroughCoordinatorTest: XCTestCase {
    class FakeAuthoriser: SpotifyAuthoriser {
        var authoriseCallCount = 0
        var authorisationCompleteCallCount = 0

        func authorise(onComplete: @escaping ((Result<AuthInfo, Error>) -> Void)) {
            authoriseCallCount += 1
        }

        func authorisationComplete(application: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
            authorisationCompleteCallCount += 1
        }
    }

    func testOnSignInButtonPressed() {
        let mockAuthoriser = FakeAuthoriser()
        let coordinator = WalkthroughCoordinator(
            navigationController: UINavigationController(),
            spotifyAuthoriser: mockAuthoriser
        )
        coordinator.onSignInButtonPressed()
        XCTAssertEqual(1, mockAuthoriser.authoriseCallCount)
    }

    func testSpotifyAuthComplete() {
        let mockAuthoriser = FakeAuthoriser()
        let coordinator = WalkthroughCoordinator(
            navigationController: UINavigationController(),
            spotifyAuthoriser: mockAuthoriser
        )
        coordinator.spotifyAuthComplete(
            application: UIApplication.shared,
            url: URL(string: "http://notarealdomainok.com/")!,
            options: [:]
        )
        XCTAssertEqual(1, mockAuthoriser.authorisationCompleteCallCount)
    }
}
