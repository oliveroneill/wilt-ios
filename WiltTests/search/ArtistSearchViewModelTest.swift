import XCTest

@testable import Wilt

final class ArtistSearchViewModelTest: XCTestCase {
    class ListeningDelegate: ArtistSearchViewModelDelegate {
        private let expectation: XCTestExpectation
        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func onSearchExit() {
            expectation.fulfill()
        }

        func loggedOut() {}
    }

    private var viewModel: ArtistSearchViewModel!
    private var dao: FakeListenLaterDao!
    private var api: FakeSearchAPI!

    override func setUp() {
        dao = FakeListenLaterDao(items: [])
        api = FakeSearchAPI()
        viewModel = ArtistSearchViewModel(dao: dao, api: api)
    }

    func testOnViewAppeared() {
        let exp = expectation(description: "Should change state to empty list")
        viewModel.onStateChange = {
            if case .loaded([]) = $0 {
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

    func testOnSearchExit() {
        let exp = expectation(description: "Should send exit event to delegate")
        let listeningDelegate = ListeningDelegate(expectation: exp)
        viewModel.delegate = listeningDelegate
        viewModel.onSearchExit()
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnSearchTextChanged() {
        let exp = expectation(description: "Should insert item")
        viewModel.onStateChange = {
            if case .loading = $0 {
                exp.fulfill()
            }
        }
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnSearchTextChangedError() {
        let exp = expectation(description: "Should send error to view")
        api.onSearch = { _ in
            return .failure(FakeError.testError)
        }
        viewModel.onStateChange = {
            if case .error(let errorMessage) = $0 {
                XCTAssertEqual(
                    "Your search failed! Maybe check your internet connection?",
                    errorMessage
                )
                exp.fulfill()
            }
        }
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnSearchTextChangedIgnoresEmptyText() {
        // When text is search, the state change will be triggered before
        // returning from `onSearchTextChanged` so this would fail
        viewModel.onStateChange = { _ in
            XCTFail("We entered the loading state when searching for nothing")
        }
        viewModel.onSearchTextChanged(text: "")
    }

    func testOnSearchTextChangedCancelsPreviousSearch() {
        let exp = expectation(description: "Should insert item")
        api.cancellable.onCancel = {
            exp.fulfill()
        }
        viewModel.onSearchTextChanged(text: "random_band")
        // Wait for 0.2 seconds to get passed the debounce period
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewModel.onSearchTextChanged(text: "a_different band")
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnSearchTextChangedDebounce() {
        let exp = expectation(description: "Should insert item")
        let expected = "a_different band"
        api.onSearch = {
            XCTAssertEqual(expected, $0)
            exp.fulfill()
            return .success([])
        }
        viewModel.onSearchTextChanged(text: "random_band")
        viewModel.onSearchTextChanged(text: expected)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnSearchTextChangedLoadsItems() {
        let exp = expectation(description: "Should load items")
        api.onSearch = { _ in
            return .success(
                [
                    ArtistSearchResult(
                        artistName: "Pinegrove",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Bon Iver",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Death Grips",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Twin Peaks",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                ]
            )
        }
        let expected = [
            ArtistViewModel(
                artistName: "Pinegrove",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            ArtistViewModel(
                artistName: "Bon Iver",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            ArtistViewModel(
                artistName: "Death Grips",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            ArtistViewModel(
                artistName: "Twin Peaks",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
        ]
        viewModel.onStateChange = {
            if case .loaded(let items) = $0 {
                XCTAssertEqual(expected, items)
                exp.fulfill()
            }
        }
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnItemPressedInsertsItem() {
        let exp = expectation(description: "Should insert item")
        api.onSearch = { _ in
            return .success(
                [
                    ArtistSearchResult(
                        artistName: "Pinegrove",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Bon Iver",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Death Grips",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                    ArtistSearchResult(
                        artistName: "Twin Peaks",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                ]
            )
        }
        let itemPressed = ArtistViewModel(
            artistName: "Death Grips",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        viewModel.onStateChange = {
            if case .loaded(_) = $0 {
                self.viewModel.onItemPressed(artist: itemPressed)
            }
        }
        let expected = ListenLaterArtist(
            name: "Death Grips",
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        dao.onInsert = {
            XCTAssertEqual(expected, $0)
            exp.fulfill()
        }
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnItemPressedExitsSearch() {
        let exp = expectation(description: "Should insert item")
        api.onSearch = { _ in
            return .success(
                [
                    ArtistSearchResult(
                        artistName: "Pinegrove",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                ]
            )
        }
        let itemPressed = ArtistViewModel(
            artistName: "Pinegrove",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        viewModel.onStateChange = {
            if case .loaded(_) = $0 {
                self.viewModel.onItemPressed(artist: itemPressed)
            }
        }
        let listeningDelegate = ListeningDelegate(expectation: exp)
        viewModel.delegate = listeningDelegate
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnItemPressedError() {
        let exp = expectation(description: "Should send error to view")
        api.onSearch = { _ in
            return .success(
                [
                    ArtistSearchResult(
                        artistName: "Pinegrove",
                        imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                        externalURL: URL(string: "http://notarealimageurl.notreal.net")!
                    ),
                ]
            )
        }
        let itemPressed = ArtistViewModel(
            artistName: "Death Grips",
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        viewModel.onStateChange = {
            if case .loaded(_) = $0 {
                self.viewModel.onItemPressed(artist: itemPressed)
            } else if case .error(let message) = $0 {
                XCTAssertEqual(
                    "There was an error saving Death Grips to your list. Maybe try again later?",
                    message
                )
                exp.fulfill()
            }
        }
        dao.onInsert = { _ in
            throw FakeError.testError
        }
        viewModel.onSearchTextChanged(text: "random_band")
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
