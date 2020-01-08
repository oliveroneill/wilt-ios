import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class FakeLastListenDao: ListenLaterDao {
    var items: [ListenLaterArtist]

    init(items: [ListenLaterArtist]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?

    func insert(item: ListenLaterArtist) throws {}
}

final class ListenLaterViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: ListenLaterViewController!
    private var viewModel: ListenLaterViewModel!
    

    /// Seup the controller under test. By default the store has a bunch of random data in it.
    ///
    /// - Parameters:
    ///   - dao: The database access object for the listen later store
    private func setupController(dao: ListenLaterDao = FakeLastListenDao(
        items: FakeData.lastListenItems + FakeData.lastListenItems + FakeData.lastListenItems
        )
    ) {
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
        setupController(dao: FakeLastListenDao(items: []))
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }


    func testOnRowsUpdated() {
        // Create a dao that we can change the underlying items and ensure
        // the view updates
        final class ChangingItemsDao: ListenLaterDao {
            var items: [ListenLaterArtist] = []
            var onDataChange: (() -> Void)?
            func insert(item: ListenLaterArtist) throws {}
        }
        let dao = ChangingItemsDao()
        // Start with an empty dataset
        setupController(dao: dao)
        tester().waitForAnimationsToFinish()
        // Change the dao to now display some data
        dao.items = FakeData.lastListenItems
        // Alert the view
        dao.onDataChange?()
        // Ensure that the table view now displays everything
        tester().waitForAnimationsToFinish()
        controller.tableView.contentOffset = .zero
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
}
