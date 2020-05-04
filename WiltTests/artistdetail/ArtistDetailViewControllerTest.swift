import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class ArtistDetailViewControllerTest: KIFTestCase {
    private let artist = ArtistInfo(
        name: "Yves Tumour",
        imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
        externalURL: URL(string: "http://notarealurl2.notreal.net")!
    )
    private let activity = [
        ArtistActivity(
            date: Date(year: 2012, month: 5, day: 1, hour: 0, minute: 0),
            numberOfPlays: 324
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 6, day: 1, hour: 0, minute: 0),
            numberOfPlays: 25
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 7, day: 1, hour: 0, minute: 0),
            numberOfPlays: 114
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 8, day: 1, hour: 0, minute: 0),
            numberOfPlays: 324
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 9, day: 1, hour: 0, minute: 0),
            numberOfPlays: 22
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 10, day: 1, hour: 0, minute: 0),
            numberOfPlays: 124
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 11, day: 1, hour: 0, minute: 0),
            numberOfPlays: 304
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 12, day: 1, hour: 0, minute: 0),
            numberOfPlays: 225
        ),
        ArtistActivity(
            date: Date(year: 2013, month: 1, day: 1, hour: 0, minute: 0),
            numberOfPlays: 104
        ),
        ArtistActivity(
            date: Date(year: 2013, month: 2, day: 1, hour: 0, minute: 0),
            numberOfPlays: 34
        ),
        ArtistActivity(
            date: Date(year: 2013, month: 3, day: 1, hour: 0, minute: 0),
            numberOfPlays: 295
        ),
        ArtistActivity(
            date: Date(year: 2013, month: 4, day: 1, hour: 0, minute: 0),
            numberOfPlays: 14
        ),
    ]
    private var window: UIWindow!
    private var controller: ArtistDetailViewController!
    private var viewModel: ArtistDetailViewModel!
    private var api: FakeWiltAPI!
    enum ArtistDetailViewControllerTestError: Error {
        case testError
    }
    private let error = ArtistDetailViewControllerTestError.testError

    /// Seup the controller under test. By default these tests will have
    /// a controller that will respond to expected API calls with empty data.
    ///
    /// - Parameters:
    ///   - apiResponse: response to be returned to topArtistPerWeek API call
    ///   - dao: The database access object for the play history cache
    private func setupController(apiResponse: Result<[ArtistActivity], Error>? = .success([])) {
        api = FakeWiltAPI()
        api.getArtistActivityResult = apiResponse
        viewModel = ArtistDetailViewModel(artist: artist, api: api)
        controller = ArtistDetailViewController(viewModel: viewModel)
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        tester().waitForAnimationsToFinish()
        tester().waitForAnimationsToFinish()
    }

    func testLoading() {
        setupController(apiResponse: nil)
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testLoaded() {
        setupController(apiResponse: .success(activity))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testError() {
        setupController(apiResponse: .failure(error))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testNoData() {
        setupController(apiResponse: .success([]))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testSwipingActivityPages() {
        setupController(apiResponse: .success(activity))
        tester().swipeRow(
            at: IndexPath(row: 1, section: 0),
            in: controller.tableView,
            in: .left
        )
        // Swipe twice to ensure we're on the second page
        tester().swipeRow(
            at: IndexPath(row: 1, section: 0),
            in: controller.tableView,
            in: .left
        )
        tester().waitForAnimationsToFinish()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOpenCellTapped() {
        setupController(apiResponse: nil)
        class ListeningDelegate: ArtistDetailViewModelDelegate {
            var openCalls = [URL]()
            func open(url: URL) {
                openCalls.append(url)
            }
            func loggedOut() {}
            func close() {}
        }
        let delegate = ListeningDelegate()
        viewModel.delegate = delegate
        tester().tapRow(
            at: IndexPath(row: 2, section: 0),
            in: controller.tableView
        )
        XCTAssertEqual([artist.externalURL], delegate.openCalls)
    }
}
