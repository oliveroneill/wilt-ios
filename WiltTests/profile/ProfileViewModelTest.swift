import XCTest
// Needed to test specific missing data error
import Firebase

@testable import Wilt

final class ProfileViewModelTest: XCTestCase {
    private var viewModel: ProfileViewModel!
    enum ProfileViewModelTestError: Error {
        case testError
    }
    private let error = ProfileViewModelTestError.testError

    override func setUp() {
        viewModel = ProfileViewModel(api: FakeWiltAPI())
    }

    func testOnViewAppeared() {
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loading(tagTitle: "Your favourite artist in recent months"),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            XCTAssertEqual(expected, $0)
            exp.fulfill()
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedLoadedTrack() {
        let trackInfo = TopTrackInfo(
            name: "EARFQUAKE by Tyler, The Creator",
            totalPlayTime: TimeInterval(7200),
            lastPlayed: Date().minusWeeks(3),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .success(trackInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loaded(
                tagTitle: "Your favourite song ever",
                title: "EARFQUAKE by Tyler, The Creator",
                subtitleFirstLine: "2 hours spent listening since joining Wilt",
                subtitleSecondLine: "Last listened to 3 weeks ago",
                imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
                externalURL: URL(string: "http://notarealdomainok.com/x/y")!
            ),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loading(tagTitle: "Your favourite artist in recent months"),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedLoadedArtist() {
        let artistInfo = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .success(artistInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loaded(
                tagTitle: "Your favourite artist in recent months",
                title: "(Sandy) Alex G",
                subtitleFirstLine: "354 plays since joining Wilt",
                subtitleSecondLine: "Last listened to last month",
                imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
                externalURL: URL(string: "http://notarealdomainok.com/x/y")!
            ),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedLoadedTrackMissingDate() {
        let trackInfo = TopTrackInfo(
            name: "EARFQUAKE by Tyler, The Creator",
            totalPlayTime: TimeInterval(0),
            lastPlayed: nil,
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .success(trackInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loaded(
                tagTitle: "Your favourite song ever",
                title: "EARFQUAKE by Tyler, The Creator",
                subtitleFirstLine: "0 seconds spent listening since joining Wilt",
                subtitleSecondLine: "",
                imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
                externalURL: URL(string: "http://notarealdomainok.com/x/y")!
            ),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loading(tagTitle: "Your favourite artist in recent months"),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedLoadedArtistMissingDate() {
        let artistInfo = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 0,
            lastPlayed: nil,
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .success(artistInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loaded(
                tagTitle: "Your favourite artist in recent months",
                title: "(Sandy) Alex G",
                subtitleFirstLine: "0 plays since joining Wilt",
                subtitleSecondLine: "",
                imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
                externalURL: URL(string: "http://notarealdomainok.com/x/y")!
            ),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedTrackError() {
        let error = ProfileViewModelTestError.testError
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: "long_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .error,
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loading(tagTitle: "Your favourite artist in recent months"),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedArtistError() {
        let error = ProfileViewModelTestError.testError
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .error,
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedArtistLoggedOut() {
        let error = WiltAPIError.loggedOut
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        final class TestDelegate: ProfileViewModelDelegate {
            private let exp: XCTestExpectation
            init(exp: XCTestExpectation) {
                self.exp = exp
            }
            func loggedOut() {
                exp.fulfill()
            }
            func open(url: URL) {}
        }
        let delegate = TestDelegate(exp: exp)
        viewModel.delegate = delegate
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedTrackLoggedOut() {
        let error = WiltAPIError.loggedOut
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        final class TestDelegate: ProfileViewModelDelegate {
            private let exp: XCTestExpectation
            init(exp: XCTestExpectation) {
                self.exp = exp
            }
            func loggedOut() {
                exp.fulfill()
            }
            func open(url: URL) {}
        }
        let delegate = TestDelegate(exp: exp)
        viewModel.delegate = delegate
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnCardTapped() {
        let index = 4
        let artistInfo = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 0,
            lastPlayed: nil,
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .success(artistInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        final class TestDelegate: ProfileViewModelDelegate {
            private let expectedURL: URL
            private let exp: XCTestExpectation
            init(expectedURL: URL, exp: XCTestExpectation) {
                self.expectedURL = expectedURL
                self.exp = exp
            }
            func loggedOut() {}
            func open(url: URL) {
                XCTAssertEqual(expectedURL, url)
                exp.fulfill()
            }
        }
        let delegate = TestDelegate(
            expectedURL: artistInfo.externalURL,
            exp: exp
        )
        viewModel.delegate = delegate
        viewModel.onViewUpdate = { _ in
            self.viewModel.onCardTapped(cardIndex: index)
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnCardTappedWhileStillLoading() {
        let index = 4
        let artistInfo = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 0,
            lastPlayed: nil,
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .success(artistInfo)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        final class TestDelegate: ProfileViewModelDelegate {
            var openCallCount = 0
            func loggedOut() {}
            func open(url: URL) {
                openCallCount += 1
            }
        }
        let delegate = TestDelegate()
        viewModel.delegate = delegate
        self.viewModel.onCardTapped(cardIndex: index)
        XCTAssertEqual(0, delegate.openCallCount)
    }

    func testOnViewAppearedArtistMissingData() {
        let error = NSError(
            domain: FunctionsErrorDomain,
            code: FunctionsErrorCode.notFound.rawValue,
            userInfo: [:]
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .missingData(
                tagTitle: "Uh oh!",
                title: "???",
                subtitleFirstLine: "Are you new to Spotify? There are no records here yet."
            ),
            .loading(tagTitle: "Your favourite song in recent months"),
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnViewAppearedTrackMissingData() {
        let error = NSError(
            domain: FunctionsErrorDomain,
            code: FunctionsErrorCode.notFound.rawValue,
            userInfo: [:]
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: "medium_term", index: 0): .failure(error)
            ]
        )
        viewModel = ProfileViewModel(api: api)
        let exp = expectation(description: "Should receive update")
        let expected: [CardViewModelState] = [
            .loading(tagTitle: "Your favourite artist ever"),
            .loading(tagTitle: "Your favourite song ever"),
            .loading(tagTitle: "Your favourite artist recently"),
            .loading(tagTitle: "Your favourite song recently"),
            .loading(tagTitle: "Your favourite artist in recent months"),
            .missingData(
                tagTitle: "Uh oh!",
                title: "???",
                subtitleFirstLine: "Are you new to Spotify? There are no records here yet."
            )
        ]
        viewModel.onViewUpdate = {
            if expected == $0 {
                exp.fulfill()
            }
        }
        viewModel.onViewAppeared()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}


extension Date {
    func minusWeeks(_ increment: Int) -> Date {
        return Calendar(identifier: .gregorian).date(
            byAdding: .weekOfYear,
            value: -increment,
            to: self
        )!
    }
}

