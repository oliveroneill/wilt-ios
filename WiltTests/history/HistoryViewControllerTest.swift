import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class HistoryViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: HistoryViewController!
    private var viewModel: HistoryViewModel!
    private var api: FakeWiltAPI!
    enum HistoryViewControllerTestError: Error {
        case testError
    }
    private let error = HistoryViewControllerTestError.testError

    /// Seup the controller under test. By default these tests will have
    /// a controller that will respond to expected API calls with empty data.
    ///
    /// - Parameters:
    ///   - apiResponse: response to be returned to getTrackHistory API call
    ///   - dao: The database access object for the play history cache
    private func setupController(apiResponse: Result<[TrackHistoryData], Error>? = .success([]),
                                 dao: TrackHistoryDao = FakeTrackHistoryDao(items: FakeData.historyItems + FakeData.historyItems + FakeData.historyItems)) {
        api = FakeWiltAPI(getTrackHistoryAnythingResult: apiResponse)
        viewModel = HistoryViewModel(
            historyDao: dao,
            api: api
        )
        controller = HistoryViewController(viewModel: viewModel)
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
        setupController(dao: FakeTrackHistoryDao(items: []))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }


    func testOnRowsUpdated() {
        // Create a dao that we can change the underlying items and ensure
        // the view updates
        final class ChangingItemsDao: TrackHistoryDao {
            var items: [TrackHistoryData] = []
            var onDataChange: (() -> Void)?
            func batchInsert(items: [TrackHistoryData]) throws {}
        }
        let dao = ChangingItemsDao()
        // Start with an empty dataset
        setupController(dao: dao)
        tester().waitForAnimationsToFinish()
        // Change the dao to now display some data
        dao.items = FakeData.historyItems
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
        tester().tapView(
            withAccessibilityLabel: "feed_error_header_text".localized
        )
        XCTAssertEqual(2, api.getTrackHistoryAfterCalls.count)
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
        tester().tapView(
            withAccessibilityLabel: "feed_error_footer_text".localized
        )
        XCTAssertEqual(2, api.getTrackHistoryBeforeCalls.count)
    }

    func testOnRowTapped() {
        let index = 8
        setupController()
        tester().waitForAnimationsToFinish()
        final class ListeningDelegate: HistoryViewModelDelegate {
            private let exp: XCTestExpectation
            private let index: Int
            init(index: Int, expectation: XCTestExpectation) {
                self.index = index
                self.exp = expectation
            }
            func loggedOut() {}
            func open(url: URL) {
                exp.fulfill()
            }
        }
        let exp = expectation(description: "Should trigger delegate")
        let delegate = ListeningDelegate(index: index, expectation: exp)
        viewModel.delegate = delegate
        tester().tapRow(
            at: IndexPath(row: index, section: 0),
            inTableViewWithAccessibilityIdentifier: "history_table_view"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
