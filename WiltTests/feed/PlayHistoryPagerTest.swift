import XCTest

@testable import Wilt

final class PlayHistoryPagerTest: XCTestCase {
    private let pageSize = 11
    private var pager: PlayHistoryPager!
    private var api: FakeWiltAPI!
    private var dao: FakePlayHistoryDao!
    enum PlayHistoryPagerTestError: Error {
        case testError
    }
    private let error = PlayHistoryPagerTestError.testError

    override func setUp() {
        api = FakeWiltAPI()
        dao = FakePlayHistoryDao(items: [])
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: pageSize)
    }

    func testLoadEarlierPageConvertingTimestamps() {
        let earliestItem = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2019-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        pager.loadEarlierPage(earliestItem: earliestItem) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1543795200, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1550448000, api.topArtistsPerWeekCalls.first?.to)
    }

    func testLoadEarlierPageUsesPageSize() {
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: 4)
        let earliestItem = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2019-03-25")!,
            week: "13-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        pager.loadEarlierPage(earliestItem: earliestItem) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1550448000, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1552867200, api.topArtistsPerWeekCalls.first?.to)
    }

    func testLoadLaterPageDoesUpsert() {
        // Given
        let expected = [
            TopArtistData(
                topArtist: "Pinegrove",
                count: 99,
                date: FakeData.formatter.date(from: "2019-02-25")!,
                week: "09-2019",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Bon Iver",
                count: 12,
                date: FakeData.formatter.date(from: "2018-12-25")!,
                week: "52-2018",
                imageURL: URL(string: "http://anothernotrealone.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            )
        ]
        api = FakeWiltAPI(
            topArtistPerWeekResult: [
                Timespan(from: 1542585600, to: 1549238400): .success(expected)
            ]
        )
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: pageSize)
        let item = TopArtistData(
            topArtist: "Tyler, The Creator",
            count: 10,
            date: FakeData.formatter.date(from: "2018-11-25")!,
            week: "47-2018",
            imageURL: URL(string: "http://arandomurl.net/img.png")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        // When
        let exp = expectation(
            description: "Should respond when insert completes"
        )
        pager.loadLaterPage(latestItem: item) {
            defer { exp.fulfill() }
            guard case let .success(upsertCount) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected.count, upsertCount)
        }
        // Then
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(1, self.dao.batchUpsertCalls.count)
            XCTAssertEqual(expected, self.dao.batchUpsertCalls.first)
        }
    }

    func testLoadLaterPageError() {
        // Given
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2019-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        let expected = error
        api = FakeWiltAPI(
            topArtistPerWeekResult: [
                Timespan(from: 1551052800, to: 1557705600): .failure(expected)
            ]
        )
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: pageSize)
        // When
        let exp = expectation(
            description: "Should respond with error"
        )
        // Then
        pager.loadLaterPage(latestItem: item) {
            defer { exp.fulfill() }
            guard case let .failure(error) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, error as? PlayHistoryPagerTestError)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testLoadEarlierPageError() {
        // Given
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2019-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        let expected = error
        api = FakeWiltAPI(
            topArtistPerWeekResult: [
                Timespan(from: 1543795200, to: 1550448000): .failure(expected)
            ]
        )
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: pageSize)
        // When
        let exp = expectation(
            description: "Should respond with error"
        )
        // Then
        pager.loadEarlierPage(earliestItem: item) {
            defer { exp.fulfill() }
            guard case let .failure(error) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, error as? PlayHistoryPagerTestError)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnZeroItemsLoaded() {
        pager.onZeroItemsLoaded {_ in }
        // I should mock the date somehow, but I think if I just test that it
        // still actually makes a request then that should be good enough for
        // now...
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
    }

    func testLoadLaterPageConvertingTimestamps() {
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2018-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1518998400, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1525651200, api.topArtistsPerWeekCalls.first?.to)
    }

    func testLoadLaterPageShouldNotRefreshTwice() {
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2018-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1518998400, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1525651200, api.topArtistsPerWeekCalls.first?.to)
        // Now we won't bother updating again since this loadLaterPage would
        // be triggered from the refresh of the above response
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
    }

    func testLoadLaterPageShouldNotRefreshCurrentWeekTwice() {
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2018-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1518998400, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1525651200, api.topArtistsPerWeekCalls.first?.to)
        // Now we won't bother updating again since this loadLaterPage would
        // be triggered from the refresh of the above response
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        // If we call again it will now skip the current week
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(2, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1519603200, api.topArtistsPerWeekCalls.last?.from)
        XCTAssertEqual(1526256000, api.topArtistsPerWeekCalls.last?.to)
    }

    func testLoadLaterPageShouldSkipToNextPageIfItsBehind() {
        let item = TopArtistData(
            topArtist: "Pinegrove",
            count: 99,
            date: FakeData.formatter.date(from: "2018-02-25")!,
            week: "09-2019",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        api = FakeWiltAPI(
            topArtistPerWeekResult: [
                Timespan(from: 1518998400, to: 1525651200): .success([item, item])
            ]
        )
        pager = PlayHistoryPager(api: api, dao: dao, pageSize: pageSize)
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(1, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1518998400, api.topArtistsPerWeekCalls.first?.from)
        XCTAssertEqual(1525651200, api.topArtistsPerWeekCalls.first?.to)
        // If we call again it will now skip the current week
        pager.loadLaterPage(latestItem: item) { _ in }
        XCTAssertEqual(2, api.topArtistsPerWeekCalls.count)
        XCTAssertEqual(1519603200, api.topArtistsPerWeekCalls.last?.from)
        XCTAssertEqual(1526256000, api.topArtistsPerWeekCalls.last?.to)
    }
}
