import XCTest

@testable import Wilt

final class TrackHistoryPagerTest: XCTestCase {
    private let pageSize = 11
    private var pager: TrackHistoryPager!
    private var api: FakeWiltAPI!
    private var dao: FakeTrackHistoryDao!
    enum TrackHistoryPagerTestError: Error {
        case testError
    }
    private let error = TrackHistoryPagerTestError.testError

    override func setUp() {
        api = FakeWiltAPI()
        dao = FakeTrackHistoryDao(items: [])
        pager = TrackHistoryPager(api: api, dao: dao, pageSize: pageSize)
    }

    func testLoadEarlierPageConvertingTimestamps() {
        let earliestItem = TrackHistoryData(
            songName: "Angelina",
            artistName: "Pinegrove",
            date: FakeData.formatter.date(from: "2019-02-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        )
        pager.loadEarlierPage(earliestItem: earliestItem) { _ in }
        XCTAssertEqual(1, api.getTrackHistoryBeforeCalls.count)
        XCTAssertEqual(1551052800, api.getTrackHistoryBeforeCalls.first?.before)
    }

    func testLoadEarlierPageUsesPageSize() {
        let expectedPageSize = 4
        pager = TrackHistoryPager(
            api: api,
            dao: dao,
            pageSize: expectedPageSize
        )
        let earliestItem = TrackHistoryData(
            songName: "Angelina",
            artistName: "Pinegrove",
            date: FakeData.formatter.date(from: "2019-02-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        )
        pager.loadEarlierPage(earliestItem: earliestItem) { _ in }
        XCTAssertEqual(
            expectedPageSize,
            api.getTrackHistoryBeforeCalls.first?.limit
        )
    }

    func testLoadLaterPageDoesInsert() {
        // Given
        let expected = [
            TrackHistoryData(
                songName: "Angelina",
                artistName: "Pinegrove",
                date: FakeData.formatter.date(from: "2019-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            TrackHistoryData(
                songName: "715 Creeks",
                artistName: "Bon Iver",
                date: FakeData.formatter.date(from: "2018-12-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
        ]
        api = FakeWiltAPI(
            getTrackHistoryAfterResult: [1543104000: .success(expected)]
        )
        pager = TrackHistoryPager(api: api, dao: dao, pageSize: pageSize)
        let item = TrackHistoryData(
            songName: "NEW MAGIC WAND",
            artistName: "Tyler, The Creator",
            date: FakeData.formatter.date(from: "2018-11-25")!,
            imageURL: URL(string: "http://arandomurl.net/img.png")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "justsometrackID"
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
            XCTAssertEqual(1, self.dao.batchInsertCalls.count)
            XCTAssertEqual(expected, self.dao.batchInsertCalls.first)
        }
    }

    func testLoadLaterPageError() {
        // Given
        let item = TrackHistoryData(
            songName: "Angelina",
            artistName: "Pinegrove",
            date: FakeData.formatter.date(from: "2019-02-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        )
        let expected = error
        api = FakeWiltAPI(
            getTrackHistoryAfterResult: [1551052800: .failure(expected)]
        )
        pager = TrackHistoryPager(api: api, dao: dao, pageSize: pageSize)
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
            XCTAssertEqual(expected, error as? TrackHistoryPagerTestError)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testLoadEarlierPageError() {
        // Given
        let item = TrackHistoryData(
            songName: "Angelina",
            artistName: "Pinegrove",
            date: FakeData.formatter.date(from: "2019-02-25")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            trackID: "not_a_real_track_id"
        )
        let expected = error
        api = FakeWiltAPI(
            getTrackHistoryBeforeResult: [1551052800: .failure(expected)]
        )
        pager = TrackHistoryPager(api: api, dao: dao, pageSize: pageSize)
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
            XCTAssertEqual(expected, error as? TrackHistoryPagerTestError)
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
        XCTAssertEqual(1, api.getTrackHistoryBeforeCalls.count)
    }
}
