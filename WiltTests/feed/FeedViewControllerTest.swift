import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class FeedViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: FeedViewController!
    enum FeedViewControllerTestError: Error {
        case testError
    }
    private let error = FeedViewControllerTestError.testError

    override func setUp() {
        setupController()
    }

    /// Seup the controller under test. By default these tests will have
    /// a controller that will respond to expected API calls with empty data.
    ///
    /// - Parameter apiResponds: Set this to false so that the API never
    /// responds. This is useful to avoid the loading spinners disappearing
    /// before the snapshot is taken
    private func setupController(apiResponse: Result<[TopArtistData], Error>? = .success([]),
                                 dao: PlayHistoryDao = FakeDao(items: FakeData.items + FakeData.items + FakeData.items)) {
        let viewModel = FeedViewModel(
            dao: dao,
            api: FakeWiltAPI(
                sameResponseToAnything: apiResponse
            )
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
        setupController(dao: FakeDao(items: []))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }


    func testOnRowsUpdated() {
        // Create a dao that we can change the underlying items and ensure
        // the view updates
        class ChangingItemsDao: PlayHistoryDao {
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
}
