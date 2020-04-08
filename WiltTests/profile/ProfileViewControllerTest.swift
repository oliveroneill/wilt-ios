import XCTest
import Nimble
import Nimble_Snapshots
import KIF

// Needed to test specific missing data error
import Firebase

@testable import Wilt

final class ProfileViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: ProfileViewController!
    private var viewModel: ProfileViewModel!
    private var api: FakeWiltAPI!
    enum ProfileViewControllerTestError: Error {
        case testError
    }
    private let error = ProfileViewControllerTestError.testError

    private func setupController(topArtistResult: [TopSomethingRequest:Result<TopArtistInfo, Error>] = [:],
                                 topTrackResult: [TopSomethingRequest:Result<TopTrackInfo, Error>] = [:]) {
        api = FakeWiltAPI(
            topArtistResult: topArtistResult,
            topTrackResult: topTrackResult
        )
        viewModel = ProfileViewModel(
            api: api
        )
        controller = ProfileViewController(viewModel: viewModel)
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        tester().waitForAnimationsToFinish()
    }

    func testLoading() {
        setupController()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testLoadedArtist() {
        let artistInfo = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        setupController(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .success(artistInfo)
            ]
        )
        tester().waitForAnimationsToFinish()
        controller.collectionView.scrollToItem(
            at: IndexPath(row: 5, section: 0),
            at: .bottom,
            animated: true
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testLoadedTrack() {
        let trackInfo = TopTrackInfo(
            name: "EARFQUAKE by Tyler, The Creator",
            totalPlayTime: TimeInterval(7200),
            lastPlayed: Date().minusWeeks(3),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        setupController(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .success(trackInfo)
            ]
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testError() {
        setupController(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .failure(error)
            ]
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testRetries() {
        setupController(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .failure(error)
            ]
        )
        tester().waitForAnimationsToFinish()
        // Stop the error from happening again
        api.topTrackResult = [:]
        tester().tapView(
            withAccessibilityLabel: "profile_card_retry_text".localized
        )
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testTapCard() {
        let trackInfo = TopTrackInfo(
            name: "EARFQUAKE by Tyler, The Creator",
            totalPlayTime: TimeInterval(7200),
            lastPlayed: Date().minusWeeks(3),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        setupController(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .success(trackInfo)
            ]
        )
        tester().waitForAnimationsToFinish()
        let exp = expectation(description: "Should open URL")
        final class TestDelegate: ProfileViewModelDelegate {
            private let expectedURL: URL
            private let exp: XCTestExpectation
            init(expectedURL: URL, exp: XCTestExpectation) {
                self.expectedURL = expectedURL
                self.exp = exp
            }
            func loggedOut() {}
            func open(url: URL) {
                XCTAssertEqual(expectedURL, url)
                exp.fulfill()
            }
        }
        let delegate = TestDelegate(
            expectedURL: trackInfo.externalURL,
            exp: exp
        )
        viewModel.delegate = delegate
        tester().tapItem(
            at: IndexPath(row: 1, section: 0),
            inCollectionViewWithAccessibilityIdentifier: "profile_collection_view"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testMissingDataArtist() {
        let error = NSError(
            domain: FunctionsErrorDomain,
            code: FunctionsErrorCode.notFound.rawValue,
            userInfo: [:]
        )
        setupController(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        tester().waitForAnimationsToFinish()
        controller.collectionView.scrollToItem(
            at: IndexPath(row: 5, section: 0),
            at: .bottom,
            animated: true
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testMissingDataTrack() {
        let error = NSError(
            domain: FunctionsErrorDomain,
            code: FunctionsErrorCode.notFound.rawValue,
            userInfo: [:]
        )
        setupController(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .failure(error)
            ]
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }
}
