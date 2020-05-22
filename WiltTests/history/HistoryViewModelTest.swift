import XCTest

@testable import Wilt

final class HistoryViewModelTest: XCTestCase {
    private var viewModel: HistoryViewModel!
    private var exp: XCTestExpectation!

    enum HistoryViewModelTestError: Error {
        case testError
    }
    private let error = HistoryViewModelTestError.testError

    override class func setUp() {
        NSTimeZone.default = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
    }

    override func setUp() {
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: FakeData.historyItems),
            api: FakeWiltAPI()
        )
        exp = expectation(description: "Should receive view update")
    }

    func testOnViewAppeared() {
        viewModel.onViewUpdate = {
            XCTAssertEqual(HistoryViewState.loadingAtTop, $0)
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
            TrackHistoryData(
                songName: "Angelina",
                artistName: "Pinegrove",
                date: FakeData.formatter.date(from: "2019-02-25")!,
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!,
                externalURL: URL(string: "http://notarealurl1.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            TrackHistoryData(
                songName: "715 Creeks",
                artistName: "Bon Iver",
                date: FakeData.formatter.date(from: "2018-12-05")!.addingTimeInterval(1000),
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            TrackHistoryData(
                songName: "Turned Off",
                artistName: "Death Grips",
                date: FakeData.formatter.date(from: "2018-10-21")!,
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
        ]
        let expected = [
            HistoryItemViewModel(
                songName: "Angelina",
                artistName: "Pinegrove",
                dateText: "25 Feb 2019 00:00",
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!,
                externalURL: URL(string: "http://notarealurl1.notreal.net")!
            ),
            HistoryItemViewModel(
                songName: "715 Creeks",
                artistName: "Bon Iver",
                dateText: "5 Dec 2018 00:16",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!
            ),
            HistoryItemViewModel(
                songName: "Turned Off",
                artistName: "Death Grips",
                dateText: "21 Oct 2018 00:00",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!
            ),
        ]
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: items),
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
            XCTAssertEqual(HistoryViewState.loadingAtTop, $0)
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
            XCTAssertEqual(HistoryViewState.loadingAtBottom, $0)
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
            XCTAssertEqual(HistoryViewState.loadingAtTop, $0)
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
            XCTAssertEqual(HistoryViewState.loadingAtBottom, $0)
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .success(FakeData.historyItems)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.displayingRows {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtTop {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: FakeData.historyItems),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtBottom {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: FakeData.historyItems),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtBottom {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtTop {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtTop {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: FakeData.historyItems),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .success([])
            )
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.displayingRows {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(WiltAPIError.loggedOut)
            )
        )
        final class ListeningDelegate: HistoryViewModelDelegate {
            private let exp: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.exp = expectation
            }
            func loggedOut() {
                exp.fulfill()
            }
            func open(url: URL) {}
            func showDetail(artist: TopArtistData) {}
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
            if $0 == HistoryViewState.loadingAtTop {
                // Disappear the view when in a loading state
                self.viewModel.onViewDisappeared()
            } else if $0 == HistoryViewState.displayingRows {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: FakeWiltAPI(
                getTrackHistoryAnythingResult: .failure(HistoryViewModelTestError.testError)
            )
        )
        // We'll use the variable to check whether we move to the displaying
        // state and we'll fail if it happens
        var stateChangedToDisplayingRows = false
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.errorAtTop {
                // Disappear the view when in an error state
                self.viewModel.onViewDisappeared()
                // Fulfill the expectation since we should've reacted to the
                // disappear by now
                self.exp.fulfill()
            } else if $0 == HistoryViewState.displayingRows {
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
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: FakeData.historyItems),
            api: FakeWiltAPI()
        )
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
        let delegate = ListeningDelegate(index: index, expectation: exp)
        viewModel.delegate = delegate
        viewModel.onRowTapped(rowIndex: index)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUpdateSearchResultsUpdatesDao() {
        let expectedQuery = "Pin"
        let dao = FakeTrackHistoryDao(items: [])
        viewModel = HistoryViewModel(
            historyDao: dao,
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        let controller = UISearchController()
        controller.searchBar.text = expectedQuery
        viewModel.updateSearchResults(for: controller)
        XCTAssertEqual([expectedQuery], dao.setArtistQueryCalls)
        // Have to fulfill expectation since it's not used in this test... Ugly
        exp.fulfill()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUpdateSearchResultsUpdatesDaoForEmptyText() {
        let expectedQuery = ""
        let dao = FakeTrackHistoryDao(items: [])
        viewModel = HistoryViewModel(
            historyDao: dao,
            api: FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        )
        let controller = UISearchController()
        controller.searchBar.text = expectedQuery
        viewModel.updateSearchResults(for: controller)
        XCTAssertEqual([nil], dao.setArtistQueryCalls)
        // Have to fulfill expectation since it's not used in this test... Ugly
        exp.fulfill()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUpdateSearchResultsChangesApiCall() {
        let expectedQuery = "Pin"
        let api = FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: api
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
                XCTAssertEqual(
                    expectedQuery,
                    api.getTrackHistoryBeforeCalls.last?.artistSearchQuery
                )
                self.exp.fulfill()
            }
        }
        let controller = UISearchController()
        controller.searchBar.text = expectedQuery
        viewModel.updateSearchResults(for: controller)
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUpdateSearchResultsChangesApiCallOnEmptyString() {
        let expectedQuery = ""
        let api = FakeWiltAPI(getTrackHistoryAnythingResult: .success([]))
        viewModel = HistoryViewModel(
            historyDao: FakeTrackHistoryDao(items: []),
            api: api
        )
        viewModel.onViewUpdate = {
            if $0 == HistoryViewState.empty {
                XCTAssertEqual(
                    nil,
                    api.getTrackHistoryBeforeCalls.last?.artistSearchQuery
                )
                self.exp.fulfill()
            }
        }
        let controller = UISearchController()
        controller.searchBar.text = expectedQuery
        viewModel.updateSearchResults(for: controller)
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
