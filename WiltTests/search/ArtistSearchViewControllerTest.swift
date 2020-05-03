import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class ArtistSearchViewControllerTest: KIFTestCase {
    private var window: UIWindow!
    private var controller: ArtistSearchViewController!
    private var viewModel: ArtistSearchViewModel!
    private var listenLaterDao: FakeListenLaterDao!
    private var api: FakeSearchAPI!
    enum ArtistSearchViewControllerTestError: Error {
        case testError
    }
    private let error = ArtistSearchViewControllerTestError.testError

    private func setupController() {
        api = FakeSearchAPI()
        listenLaterDao = FakeListenLaterDao(items: [])
        viewModel = ArtistSearchViewModel(dao: listenLaterDao, api: api)
        controller = ArtistSearchViewController(viewModel: viewModel)
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        let navController = UINavigationController()
        window.rootViewController = navController
        navController.pushViewController(controller, animated: false)
        window.makeKeyAndVisible()
        self.window = window
        tester().waitForAnimationsToFinish()
        tester().waitForAnimationsToFinish()
    }

    func testInitialScreen() {
        setupController()
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot(tolerance: 0.001))
    }

    func testOnSearchLoading() {
        setupController()
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "hey")
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOnSearchSuccess() {
        setupController()
        api.onSearch = { _ in
            .success(
                [
                    ArtistSearchResult(
                        artistName: "The Garden",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Gorillaz",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Good Old War",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    )
                ]
            )
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "g")
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOnSearchSuccessButEmpty() {
        setupController()
        api.onSearch = { _ in
            .success([])
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "g")
        tester().waitForAnimationsToFinish()
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOnSearchFailure() {
        setupController()
        api.onSearch = { _ in
            .failure(ArtistSearchViewControllerTestError.testError)
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "hey")
        tester().waitForAnimationsToFinish()
        // TODO: This screenshot looks a little strange. It seems to just be
        // an artefact of the testing framework
        // expect(self.window).to(recordSnapshot())
        expect(self.window).to(haveValidSnapshot())
    }

    func testOnSearchCallsAPI() {
        let exp = expectation(description: "Should trigger search query")
        let expectedSearch = "hey"
        setupController()
        api.onSearch = {
            if $0 == expectedSearch {
                exp.fulfill()
            }
            return .success([])
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: expectedSearch)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnTapResultTriggersExit() {
        let exp = expectation(description: "Should trigger tapped result")
        setupController()
        final class ListeningDelegate: ArtistSearchViewModelDelegate {
            private let exp: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.exp = expectation
            }

            func onSearchExit() {
                exp.fulfill()
            }

            func loggedOut() {}
        }
        let delegate = ListeningDelegate(expectation: exp)
        viewModel.delegate = delegate
        api.onSearch = { _ in
            .success(
                [
                    ArtistSearchResult(
                        artistName: "The Garden",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Gorillaz",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Good Old War",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    )
                ]
            )
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "g")
        tester().tapRow(
            at: IndexPath(item: 1, section: 0),
            inTableViewWithAccessibilityIdentifier: "search_results_tableview"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnTapResultTriggersInsert() {
        let exp = expectation(description: "Should trigger tapped result")
        setupController()
        let expected = ListenLaterArtist(
            name: "Gorillaz",
            externalURL: URL(string: "http://randomurl.net/x/y")!,
            imageURL: nil
        )
        listenLaterDao.onInsert = {
            XCTAssertEqual(expected, $0)
            exp.fulfill()
        }
        api.onSearch = { _ in
            .success(
                [
                    ArtistSearchResult(
                        artistName: "The Garden",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Gorillaz",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    ),
                    ArtistSearchResult(
                        artistName: "Good Old War",
                        imageURL: nil,
                        externalURL: URL(string: "http://randomurl.net/x/y")!
                    )
                ]
            )
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "g")
        tester().tapRow(
            at: IndexPath(item: 1, section: 0),
            inTableViewWithAccessibilityIdentifier: "search_results_tableview"
        )
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnTapCancel() {
        let exp = expectation(description: "Should trigger tapped result")
        setupController()
        final class ListeningDelegate: ArtistSearchViewModelDelegate {
            private let exp: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.exp = expectation
            }

            func onSearchExit() {
                exp.fulfill()
            }

            func loggedOut() {}
        }
        let delegate = ListeningDelegate(expectation: exp)
        viewModel.delegate = delegate
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "g")
        tester().tapView(withAccessibilityLabel: "Cancel")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
