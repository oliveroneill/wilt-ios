import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class ProfileViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: ProfileViewController!
    private var api: FakeWiltAPI!

    private func setupController(topArtistResult: [TopSomethingRequest:Result<TopArtistInfo, Error>] = [:],
                                 topTrackResult: [TopSomethingRequest:Result<TopTrackInfo, Error>] = [:]) {
        api = FakeWiltAPI(
            topArtistResult: topArtistResult,
            topTrackResult: topTrackResult
        )
        let viewModel = ProfileViewModel(
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
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!
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
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!
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

}
