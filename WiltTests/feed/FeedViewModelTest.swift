import XCTest

@testable import Wilt

final class FeedViewModelTest: XCTestCase {
    private var viewModel: FeedViewModel!
    private var exp: XCTestExpectation!

    enum FeedViewModelTestError: Error {
        case testError
    }
    private let error = FeedViewModelTestError.testError
    private var listenLaterDao: FakeListenLaterDao!

    override func setUp() {
        listenLaterDao = FakeListenLaterDao(items: [])
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: FakeData.items),
            api: FakeWiltAPI(),
            listenLaterDao: listenLaterDao
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

    func testOnViewAppearedTriggersStarUpdate() {
        viewModel.onStarsUpdated = {
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
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!,
                externalURL: URL(string: "http://notarealurl1.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Bon Iver",
                count: 12,
                date: FakeData.formatter.date(from: "2018-12-25")!,
                week: "52-2018",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Death Grips",
                count: 78,
                date: FakeData.formatter.date(from: "2018-10-21")!,
                week: "43-2018",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!
            ),
        ]
        let expected = [
            FeedItemViewModel(
                artistName: "Pinegrove",
                playsText: "99 plays",
                dateText: "Feb 2019",
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!,
                externalURL: URL(string: "http://notarealurl1.notreal.net")!,
                isStarred: false
            ),
            FeedItemViewModel(
                artistName: "Bon Iver",
                playsText: "12 plays",
                dateText: "Dec 2018",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!,
                isStarred: false
            ),
            FeedItemViewModel(
                artistName: "Death Grips",
                playsText: "78 plays",
                dateText: "Oct 2018",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!,
                isStarred: false
            ),
        ]
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: items),
            api: FakeWiltAPI(),
            listenLaterDao: FakeListenLaterDao(items: [])
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

    func testonRetryHeaderPressed() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtTop, $0)
            self.exp.fulfill()
        }
        viewModel.onRetryHeaderPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnRetryFooterPressed() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(FeedViewState.loadingAtBottom, $0)
            self.exp.fulfill()
        }
        viewModel.onRetryFooterPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testonRetryHeaderPressedEmpty() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success([])),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.onRetryHeaderPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToBottomEmpty() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success([])),
            listenLaterDao: FakeListenLaterDao(items: [])
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

    func testOnRetryFooterPressedEmpty() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success([])),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.empty {
                self.exp.fulfill()
            }
        }
        viewModel.onRetryFooterPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedEmpty() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success([])),
            listenLaterDao: FakeListenLaterDao(items: [])
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

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success([])),
            listenLaterDao: FakeListenLaterDao(items: [])
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

    func testRefreshDisplaysRowsAfterAPICall() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(topArtistPerWeekAnythingResponse: .success(FakeData.items)),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.displayingRows {
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

    func testonRetryHeaderPressedError() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtTop {
                self.exp.fulfill()
            }
        }
        viewModel.onRetryHeaderPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnScrolledToBottomError() {
        viewModel = FeedViewModel(

            historyDao: FakePlayHistoryDao(items: FakeData.items),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
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

    func testOnRetryFooterPressedError() {
        viewModel = FeedViewModel(
            historyDao: FakePlayHistoryDao(items: FakeData.items),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtBottom {
                self.exp.fulfill()
            }
        }
        viewModel.onRetryFooterPressed()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedError() {
        viewModel = FeedViewModel(
            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
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
            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
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
            historyDao: FakePlayHistoryDao(items: FakeData.items),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .success([])
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
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
            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(WiltAPIError.loggedOut)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        final class ListeningDelegate: FeedViewModelDelegate {
            private let exp: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.exp = expectation
            }
            func loggedOut() {
                exp.fulfill()
            }
            func open(url: URL) {}
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

    func testOnViewDisappeared() {
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.loadingAtTop {
                // Disappear the view when in a loading state
                self.viewModel.onViewDisappeared()
            } else if $0 == FeedViewState.displayingRows {
                // Ensure that we made it to the displaying state
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

    func testOnViewDisappearedWhenNotLoading() {
        viewModel = FeedViewModel(
            historyDao: FakePlayHistoryDao(items: []),
            api: FakeWiltAPI(
                topArtistPerWeekAnythingResponse: .failure(FeedViewModelTestError.testError)
            ),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
        // We'll use the variable to check whether we move to the displaying
        // state and we'll fail if it happens
        var stateChangedToDisplayingRows = false
        viewModel.onViewUpdate = {
            if $0 == FeedViewState.errorAtTop {
                // Disappear the view when in an error state
                self.viewModel.onViewDisappeared()
                // Fulfill the expectation since we should've reacted to the
                // disappear by now
                self.exp.fulfill()
            } else if $0 == FeedViewState.displayingRows {
                // Ensure that we made it to the displaying state
                stateChangedToDisplayingRows = true
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
            XCTAssertFalse(stateChangedToDisplayingRows)
        }
    }

    func testOnRowTapped() {
        let index = 8
        viewModel = FeedViewModel(
            historyDao: FakePlayHistoryDao(items: FakeData.items),
            api: FakeWiltAPI(),
            listenLaterDao: FakeListenLaterDao(items: [])
        )
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
        let delegate = ListeningDelegate(index: index, expectation: exp)
        viewModel.delegate = delegate
        viewModel.onRowTapped(rowIndex: index)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testItemsAreStarred() {
        let items = [
            TopArtistData(
                topArtist: "Bon Iver",
                count: 12,
                date: FakeData.formatter.date(from: "2018-12-25")!,
                week: "52-2018",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Death Grips",
                count: 78,
                date: FakeData.formatter.date(from: "2018-10-21")!,
                week: "43-2018",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!
            ),
        ]
        let starredItems = [
            ListenLaterArtist(
                name: "Bon Iver",
                externalURL: URL(string: "http://notarealurl2.notreal.net")!,
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!
            )
        ]
        let expected = [
            FeedItemViewModel(
                artistName: "Bon Iver",
                playsText: "12 plays",
                dateText: "Dec 2018",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!,
                isStarred: true
            ),
            FeedItemViewModel(
                artistName: "Death Grips",
                playsText: "78 plays",
                dateText: "Oct 2018",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!,
                isStarred: false
            ),
        ]
        viewModel = FeedViewModel(
            historyDao: FakePlayHistoryDao(items: items),
            api: FakeWiltAPI(),
            listenLaterDao: FakeListenLaterDao(items: starredItems)
        )
        XCTAssertEqual(expected, viewModel.items)
        // We need to fulfill the expectation since we declare it in setUp
        // A small sacrifice so that I don't have to redeclare it in all of the
        // other tests
        exp.fulfill()
        waitForExpectations(timeout: 1) {_ in}
    }

    func testOnRowStarred() {
        viewModel.onStarsUpdated = {
            self.exp.fulfill()
        }
        viewModel.onRowStarred(rowIndex: 2)
        waitForExpectations(timeout: 1) {_ in}
    }

    func testOnRowStarredTriggersInsert() {
        listenLaterDao.onInsert = {
            XCTAssertEqual(FakeData.listenLaterItems[2], $0)
            self.exp.fulfill()
        }
        viewModel.onRowStarred(rowIndex: 2)
        waitForExpectations(timeout: 1) {_ in}
    }

    func testOnRowUnstarred() {
        viewModel.onStarsUpdated = {
            self.exp.fulfill()
        }
        viewModel.onRowUnstarred(rowIndex: 2)
        waitForExpectations(timeout: 1) {_ in}
    }

    func testOnRowUnstarredTriggersInsert() {
        listenLaterDao.onDelete = {
            XCTAssertEqual(FakeData.listenLaterItems[2].name, $0)
            self.exp.fulfill()
        }
        viewModel.onRowUnstarred(rowIndex: 2)
        waitForExpectations(timeout: 1) {_ in}
    }
}
