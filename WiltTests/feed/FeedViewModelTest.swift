import XCTest

@testable import Wilt

class FeedViewModelTest: XCTestCase {
    private var viewModel: FeedViewModel!
    private var exp: XCTestExpectation!

    enum FeedViewModelTestError: Error {
        case testError
    }
    private let error = FeedViewModelTestError.testError

    override func setUp() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: FakeData.items),
            api: FakeWiltAPI()
        )
        exp = expectation(description: "Should receive view update")
    }

    func testOnViewAppeared() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtTop, $0)
            self.exp.fulfill()
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testItems() {
        let items = [
            TopArtistData(
                topArtist: "Pinegrove",
                count: 99,
                date: FakeData.formatter.date(from: "2019-02-25")!,
                week: "09-2019",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Bon Iver",
                count: 12,
                date: FakeData.formatter.date(from: "2018-12-25")!,
                week: "52-2018",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Death Grips",
                count: 78,
                date: FakeData.formatter.date(from: "2018-10-21")!,
                week: "43-2018",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
        ]
        let expected = [
            FeedItemViewModel(
                artistName: "Pinegrove",
                playsText: "99 plays",
                dateText: "Feb 2019"
            ),
            FeedItemViewModel(
                artistName: "Bon Iver",
                playsText: "12 plays",
                dateText: "Dec 2018"
            ),
            FeedItemViewModel(
                artistName: "Death Grips",
                playsText: "78 plays",
                dateText: "Oct 2018"
            ),
        ]
        viewModel = FeedViewModel(
            dao: FakeDao(items: items),
            api: FakeWiltAPI()
        )
        XCTAssertEqual(expected, viewModel.items)
        // We need to fulfill the expectation since we declare it in setUp
        // A small sacrifice so that I don't have to redeclare it in all of the
        // other tests
        exp.fulfill()
        waitForExpectations(timeout: 1) {_ in}
    }

    func testRefresh() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtTop, $0)
            self.exp.fulfill()
        }
        viewModel.refresh()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToBottom() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtBottom, $0)
            self.exp.fulfill()
        }
        viewModel.onScrolledToBottom()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToTop() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtTop, $0)
            self.exp.fulfill()
        }
        viewModel.onScrolledToTop()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToTopEmpty() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .success([]),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.onScrolledToTop()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToBottomEmpty() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .success([]),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.onScrolledToBottom()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedEmpty() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .success([]),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRefreshEmpty() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .success([]),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.refresh()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToTopError() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .failure(
                    FeedViewModelTestError.testError
                ),
            ])
        )
        viewModel.onViewUpdate = {
            print($0)
            if $0 == FeedViewState.errorAtTop {
                self.exp.fulfill()
            }
        }
        viewModel.onScrolledToTop()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToBottomError() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: FakeData.items),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1508716800, to: 1514764800): .failure(
                    FeedViewModelTestError.testError
                ),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtBottom {
                self.exp.fulfill()
            }
        }
        viewModel.onScrolledToBottom()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedError() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .failure(
                    FeedViewModelTestError.testError
                ),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtTop {
                self.exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRefreshError() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .failure(
                    FeedViewModelTestError.testError
                ),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtTop {
                self.exp.fulfill()
            }
        }
        viewModel.refresh()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedDisplayingRows() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: FakeData.items),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1551052800, to: 1557100800): .success([]),
            ])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.displayingRows {
                self.exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedLoggedOut() {
        viewModel = FeedViewModel(
            dao: FakeDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekResult: [
                Timespan(from: 1556496000, to: 1568592000): .failure(
                    WiltAPIError.loggedOut
                ),
            ])
        )
        class ListeningDelegate: FeedViewModelDelegate {
            private let exp: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.exp = expectation
            }
            func loggedOut() {
                exp.fulfill()
            }
        }
        let delegate = ListeningDelegate(expectation: exp)
        viewModel.delegate = delegate
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
