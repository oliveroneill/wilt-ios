import XCTest

@testable import Wilt

class ArtistActivityCacheTest: XCTestCase {
    private let artistName = "Girlpool"
    private let activity = [
        ArtistActivity(
            date: Date(year: 2012, month: 5, day: 1, hour: 0, minute: 0),
            numberOfPlays: 324
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 6, day: 1, hour: 0, minute: 0),
            numberOfPlays: 25
        ),
        ArtistActivity(
            date: Date(year: 2012, month: 7, day: 1, hour: 0, minute: 0),
            numberOfPlays: 114
        ),
    ]
    private var cache: ArtistActivityCache!
    private var api: FakeWiltAPI!
    enum ArtistActivityCacheTestError: Error {
        case testError
    }
    private let error = ArtistActivityCacheTestError.testError

    override func setUp() {
        api = FakeWiltAPI()
        cache = ArtistActivityCache(networkAPI: api)
    }

    override func tearDown() {
        // Clear the cache before the tests start
        try! cache.clear()
    }

    func testGetArtistActivityWithEmptyCache() {
        let exp = expectation(description: "Will receive response")
        api.getArtistActivityResult = .success(activity)
        cache.getArtistActivity(artistName: artistName) {
            defer { exp.fulfill() }
            guard case .success(let activity) = $0 else {
                XCTFail("Unexpected response: \($0)")
                return
            }
            XCTAssertEqual(self.activity, activity)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual([self.artistName], self.api.getArtistActivityCalls)
        }
    }

    func testGetArtistActivityDoesNotCacheError() {
        let exp = expectation(description: "Will receive response")
        api.getArtistActivityResult = .failure(error)
        cache.getArtistActivity(artistName: artistName) { _ in
            // Make another call that will succeed
            self.api.getArtistActivityResult = .success(self.activity)
            self.cache.getArtistActivity(artistName: self.artistName) {
                // Ensure we receive a successful response and the failure was
                // not cached
                defer { exp.fulfill() }
                guard case .success(let activity) = $0 else {
                    XCTFail("Unexpected response: \($0)")
                    return
                }
                XCTAssertEqual(self.activity, activity)
            }
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testGetArtistActivityWithFullCache() {
        let exp = expectation(description: "Will receive response")
        api.getArtistActivityResult = .success(activity)
        cache.getArtistActivity(artistName: artistName) { _ in
            // Make another call
            self.cache.getArtistActivity(artistName: self.artistName) {
                defer { exp.fulfill() }
                guard case .success(let activity) = $0 else {
                    XCTFail("Unexpected response: \($0)")
                    return
                }
                XCTAssertEqual(self.activity, activity)
            }
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
            // Ensure that it was only called once
            XCTAssertEqual([self.artistName], self.api.getArtistActivityCalls)
        }
    }

    func testGetArtistActivityWithUnrelatedCacheElement() {
        let secondArtistSearch = "Rosalia"
        let expectedActivity = [
            ArtistActivity(
                date: Date(year: 2016, month: 2, day: 1, hour: 0, minute: 0),
                numberOfPlays: 24
            ),
            ArtistActivity(
                date: Date(year: 2016, month: 3, day: 1, hour: 0, minute: 0),
                numberOfPlays: 253
            ),
            ArtistActivity(
                date: Date(year: 2016, month: 4, day: 1, hour: 0, minute: 0),
                numberOfPlays: 144
            ),
        ]
        let exp = expectation(description: "Will receive response")
        api.getArtistActivityResult = .success(activity)
        // Make a request for one artist name
        cache.getArtistActivity(artistName: artistName) { _ in
            // Setup a new response for a different artist name
            self.api.getArtistActivityResult = .success(expectedActivity)
            self.cache.getArtistActivity(artistName: secondArtistSearch) {
                // Ensure that we receive the expected response from the
                // activity
                guard case .success(let activity) = $0 else {
                    XCTFail("Unexpected response: \($0)")
                    return
                }
                XCTAssertEqual(expectedActivity, activity)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
            // Ensure that we see both searches
            XCTAssertEqual(
                [self.artistName, secondArtistSearch],
                self.api.getArtistActivityCalls
            )
        }
    }
}
