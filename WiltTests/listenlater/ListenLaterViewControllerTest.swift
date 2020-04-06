import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class ListenLaterViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: ListenLaterViewController!
    private var viewModel: ListenLaterViewModel!
    private var dao: FakeListenLaterDao!


    /// Seup the controller under test. By default the store has a bunch of random data in it.
    ///
    /// - Parameters:
    ///   - dao: The database access object for the listen later store
    private func setupController(dao: FakeListenLaterDao = FakeListenLaterDao(
        items: FakeData.listenLaterItems
        )
    ) {
        self.dao = dao
        viewModel = ListenLaterViewModel(dao: dao)
        controller = ListenLaterViewController(viewModel: viewModel)
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

    func testEmptyData() {
        setupController(dao: FakeListenLaterDao(items: []))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOnRowTapped() {
        let index = 8
        setupController()
        tester().waitForAnimationsToFinish()
        final class ListeningDelegate: ListenLaterViewModelDelegate {
            private let exp: XCTestExpectation
            private let index: Int
            init(index: Int, expectation: XCTestExpectation) {
                self.index = index
                self.exp = expectation
            }
            func loggedOut() {}
            func onSearchButtonPressed() {}
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
            inTableViewWithAccessibilityIdentifier: "listen_later_table_view"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnRowDeleted() {
        setupController()
        tester().waitForAnimationsToFinish()
        let exp = expectation(description: "Should trigger delete")
        dao.onDelete = {
            XCTAssertEqual(FakeData.listenLaterItems[0].name, $0)
            exp.fulfill()
        }
        tester().swipeRow(
            at: IndexPath(row: 0, section: 0),
            in: controller.tableView,
            in: .left
        )
        tester().waitForAnimationsToFinish()
        // This is a hack because the UIContextualAction is not a tappable
        // view and I can't figure out how to put an accessibilityLabel on
        // the actual button :(
        tester().tapScreen(
            at: CGPoint(
                x: UIScreen.main.bounds.size.width - 10,
                y: UIApplication.shared.statusBarFrame.height + 10
            )
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnRowDeletedSnapshot() {
        setupController()
        tester().waitForAnimationsToFinish()
        tester().swipeRow(
            at: IndexPath(row: 0, section: 0),
            in: controller.tableView,
            in: .left
        )
        tester().waitForAnimationsToFinish()
        // This is a hack because the UIContextualAction is not a tappable
        // view and I can't figure out how to put an accessibilityLabel on
        // the actual button :(
        tester().tapScreen(
            at: CGPoint(
                x: UIScreen.main.bounds.size.width - 10,
                y: UIApplication.shared.statusBarFrame.height + 10
            )
        )
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }
}
