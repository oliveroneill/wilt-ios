import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class FeedViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: FeedViewController!

    override func setUp() {
        setupController()
    }

    /// Seup the controller under test. By default these tests will have
    /// a controller that will respond to expected API calls with empty data.
    ///
    /// - Parameter apiResponds: Set this to false so that the API never
    /// responds. This is useful to avoid the loading spinners disappearing
    /// before the snapshot is taken
    private func setupController(apiResponds: Bool = true) {
        let result: [Timespan:Result<[TopArtistData], Error>]
        if apiResponds {
            result = [
                Timespan(from: 1567346400, to: 1573390800): .success([]),
                Timespan(from: 1551013200, to: 1557064800): .success([])
            ]
        } else {
            result = [:]
        }
        let viewModel = FeedViewModel(
            dao: FakeDao(
                items: FakeData.items + FakeData.items + FakeData.items
            ),
            api: FakeWiltAPI(
                topArtistPerWeekResult: result
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
        tester().waitForAnimationsToFinish()
        controller.tableView.scrollToRow(
            at: IndexPath(
                row: controller.tableView.numberOfRows(inSection: 0) - 1,
                section: 0
            ),
            at: .bottom,
            animated: true
        )
        tester().waitForAnimationsToFinish()
        controller.view.layoutIfNeeded()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testShowSpinnerAtTopOnLoad() {
        setupController(apiResponds: false)
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testShowSpinnerAtTopOnSwipeUp() {
        setupController(apiResponds: false)
        // I attempted to use KIF's pullToRefreshView but was unable to
        // get the scroll animation to stop predictably
        controller.tableView.refreshControl?.refresh(animate: true)
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    // TODO: test empty data
    // TODO: test error
}
