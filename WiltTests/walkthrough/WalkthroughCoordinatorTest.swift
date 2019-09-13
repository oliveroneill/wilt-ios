import XCTest

@testable import Wilt

class WalkthroughCoordinatorTest: XCTestCase {
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
}
