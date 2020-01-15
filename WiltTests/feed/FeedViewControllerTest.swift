import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class FeedViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: FeedViewController!
    private var viewModel: FeedViewModel!
    private var api: FakeWiltAPI!
    enum FeedViewControllerTestError: Error {
        case testError
    }
    private let error = FeedViewControllerTestError.testError

    /// Seup the controller under test. By default these tests will have
    /// a controller that will respond to expected API calls with empty data.
    ///
    /// - Parameters:
    ///   - apiResponse: response to be returned to topArtistPerWeek API call
    ///   - dao: The database access object for the play history cache
    private func setupController(apiResponse: Result<[TopArtistData], Error>? = .success([]),
                                 dao: PlayHistoryDao = FakePlayHistoryDao(items: FakeData.items + FakeData.items + FakeData.items)) {
        api = FakeWiltAPI(topArtistPerWeekAnythingResponse: apiResponse)
        viewModel = FeedViewModel(
            dao: dao,
            api: api
        )
        controller = FeedViewController(viewModel: viewModel)
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        tester().waitForAnimationsToFinish()
    }

    func testDisplayRows() {
        setupController()
        tester().waitForAnimationsToFinish()
        controller.tableView.contentOffset = .zero
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testShowSpinnerAtBottom() {
        setupController(apiResponse: nil)
        tester().waitForAnimationsToFinish()
        controller.tableView.scrollToRow(
            at: IndexPath(
                row: controller.tableView.numberOfRows(inSection: 0) - 1,
                section: 0
            ),
            at: .bottom,
            animated: false
        )
        tester().waitForAnimationsToFinish()
        controller.view.layoutIfNeeded()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testShowSpinnerAtTopOnLoad() {
        setupController(apiResponse: nil)
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testShowSpinnerAtTopOnSwipeUp() {
        setupController(apiResponse: nil)
        // I attempted to use KIF's pullToRefreshView but was unable to
        // get the scroll animation to stop predictably
        controller.tableView.refreshControl?.refresh(animate: true)
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testEmptyData() {
        setupController(dao: FakePlayHistoryDao(items: []))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }


    func testOnRowsUpdated() {
        // Create a dao that we can change the underlying items and ensure
        // the view updates
        final class ChangingItemsDao: PlayHistoryDao {
            var items: [TopArtistData] = []
            var onDataChange: (() -> Void)?
            func batchUpsert(items: [TopArtistData]) throws {}
        }
        let dao = ChangingItemsDao()
        // Start with an empty dataset
        setupController(dao: dao)
        tester().waitForAnimationsToFinish()
        // Change the dao to now display some data
        dao.items = FakeData.items
        // Alert the view
        dao.onDataChange?()
        // Ensure that the table view now displays everything
        tester().waitForAnimationsToFinish()
        controller.tableView.contentOffset = .zero
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testErrorAtTop() {
        setupController(apiResponse: .failure(error))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testErrorAtBottom() {
        setupController(apiResponse: .failure(error))
        tester().waitForAnimationsToFinish()
        controller.tableView.scrollToRow(
            at: IndexPath(
                row: controller.tableView.numberOfRows(inSection: 0) - 1,
                section: 0
            ),
            at: .bottom,
            animated: false
        )
        tester().waitForAnimationsToFinish()
        controller.view.layoutIfNeeded()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testErrorAtTopRetry() {
        setupController(apiResponse: .failure(error))
        tester().tapView(withAccessibilityLabel: "feed_error_header_button")
        XCTAssertEqual(2, api.topArtistsPerWeekCalls.count)
    }

    func testErrorAtBottomRetry() {
        setupController(apiResponse: .failure(error))
        tester().waitForAnimationsToFinish()
        controller.tableView.scrollToRow(
            at: IndexPath(
                row: controller.tableView.numberOfRows(inSection: 0) - 1,
                section: 0
            ),
            at: .bottom,
            animated: false
        )
        tester().waitForAnimationsToFinish()
        sleep(5)
        tester().tapView(withAccessibilityLabel: "feed_error_footer_button")
        // It will load the top, then load the bottom and then retry. Therefore
        // 3
        XCTAssertEqual(3, api.topArtistsPerWeekCalls.count)
    }

    func testOnRowTapped() {
        let index = 8
        setupController()
        tester().waitForAnimationsToFinish()
        final class ListeningDelegate: FeedViewModelDelegate {
            private let exp: XCTestExpectation
            private let index: Int
            init(index: Int, expectation: XCTestExpectation) {
                self.index = index
                self.exp = expectation
            }
            func loggedOut() {}
            func open(url: URL) {
                XCTAssertEqual(FakeData.items[index].externalURL, url)
                exp.fulfill()
            }
        }
        let exp = expectation(description: "Should trigger delegate")
        let delegate = ListeningDelegate(index: index, expectation: exp)
        viewModel.delegate = delegate
        tester().tapRow(
            at: IndexPath(row: index, section: 0),
            inTableViewWithAccessibilityIdentifier: "feed_table_view"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
