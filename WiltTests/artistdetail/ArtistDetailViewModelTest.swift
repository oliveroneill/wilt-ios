import XCTest

@testable import Wilt

class ArtistDetailViewModelTest: XCTestCase {
    private let artist = ArtistInfo(
        name: "Yves Tumour",
        imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
        externalURL: URL(string: "http://notarealurl2.notreal.net")!
    )
    private var api: FakeWiltAPI!
    private var viewModel: ArtistDetailViewModel!

    enum ArtistDetailViewModelTestError: Error {
        case testError
    }
    private let error = ArtistDetailViewModelTestError.testError

    override func setUp() {
        api = FakeWiltAPI()
        viewModel = ArtistDetailViewModel(
            artist: artist,
            api: api
        )
    }

    func testOnViewAppeared() {
        let exp = expectation(description: "Will trigger loading state")
        viewModel.onViewUpdate = {
            XCTAssertEqual(.loading(artist: self.artist), $0)
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedTriggersActivityQuery() {
        let exp = expectation(
            description: "Will trigger artist activity update"
        )
        viewModel.onViewUpdate = { _ in
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(
                [self.artist.name],
                self.api.getArtistActivityCalls
            )
        }
    }

    func testOnViewAppearedDoesntReloadMoreThanOnce() {
        let exp = expectation(
            description: "Will trigger loading state only once"
        )
        viewModel.onViewUpdate = { _ in
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        // If the user swipes down the modal view then it will retrigger view
        // events even though everything's already loaded
        viewModel.onViewLoaded()
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewUpdate() {
        let activity = [
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
        let expectedActivity = [
            ActivityPeriodViewData(
                dateText: "May 2012",
                numberOfPlays: 324
            ),
            ActivityPeriodViewData(
                dateText: "Jun 2012",
                numberOfPlays: 25
            ),
            ActivityPeriodViewData(
                dateText: "Jul 2012",
                numberOfPlays: 114
            ),
        ]
        api.getArtistActivityResult = .success(activity)
        let exp = expectation(
            description: "Will trigger update to loaded state"
        )
        viewModel.onViewUpdate = {
            guard case .loaded(let artist, let activity) = $0 else {
                return
            }
            XCTAssertEqual(self.artist, artist)
            XCTAssertEqual(expectedActivity, activity)
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewUpdateWithError() {
        api.getArtistActivityResult = .failure(error)
        let exp = expectation(
            description: "Will trigger update to loaded state"
        )
        viewModel.onViewUpdate = {
            guard case .error(let error) = $0 else {
                return
            }
            XCTAssertEqual("Sorry, something's gone wrong.", error)
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewUpdateWithNoData() {
        api.getArtistActivityResult = .success([])
        let exp = expectation(description: "Will trigger update to error state")
        viewModel.onViewUpdate = {
            guard case .error(let error) = $0 else {
                return
            }
            XCTAssertEqual("Have you listened to this artist before?", error)
            exp.fulfill()
        }
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOpenCellTapped() {
        class ListeningDelegate: ArtistDetailViewModelDelegate {
            var openCalls = [URL]()
            func open(url: URL) {
                openCalls.append(url)
            }

            func loggedOut() {}
            func close() {}
        }
        let delegate = ListeningDelegate()
        viewModel.delegate = delegate
        viewModel.openCellTapped()
        XCTAssertEqual([artist.externalURL], delegate.openCalls)
    }

    func testOnLoggedOut() {
        api.getArtistActivityResult = .failure(WiltAPIError.loggedOut)
        class ExpectingDelegate: ArtistDetailViewModelDelegate {
            private let expectation: XCTestExpectation
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            func open(url: URL) {}
            func close() {}
            func loggedOut() {
                expectation.fulfill()
            }
        }
        let exp = expectation(description: "Will trigger logout event")
        let delegate = ExpectingDelegate(expectation: exp)
        viewModel.delegate = delegate
        viewModel.onViewLoaded()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
