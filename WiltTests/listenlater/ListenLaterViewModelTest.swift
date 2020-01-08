import XCTest

@testable import Wilt

final class FakeListenLaterStore: ListenLaterDao {
    var items: [ListenLaterArtist]
    var insertCalls = [ListenLaterArtist]()

    init(items: [ListenLaterArtist]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func insert(item: ListenLaterArtist) throws {
        insertCalls.append(item)
    }
}

final class ListenLaterViewModelTest: XCTestCase {
    private var viewModel: ListenLaterViewModel!
    private var exp: XCTestExpectation!

    override func setUp() {
        viewModel = ListenLaterViewModel(
            dao: FakeListenLaterStore(items: FakeData.lastListenItems)
        )
        exp = expectation(description: "Should receive view update")
    }

    func testItems() {
        let items = [
            ListenLaterArtist(
                name: "Pinegrove",
                externalURL: URL(string: "http://notarealurl1.notreal.net")!,
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!
            ),
            ListenLaterArtist(
                name: "Bon Iver",
                externalURL: URL(string: "http://notarealurl2.notreal.net")!,
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!
            ),
            ListenLaterArtist(
                name: "Death Grips",
                externalURL: URL(string: "http://notarealurl3.notreal.net")!,
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!
            ),
        ]
        let expected = [
            ListenLaterItemViewModel(
                artistName: "Pinegrove",
                imageURL: URL(string: "http://notarealimageurl1.notreal.net")!,
                externalURL: URL(string: "http://notarealurl1.notreal.net")!
            ),
            ListenLaterItemViewModel(
                artistName: "Bon Iver",
                imageURL: URL(string: "http://notarealimageurl2.notreal.net")!,
                externalURL: URL(string: "http://notarealurl2.notreal.net")!
            ),
            ListenLaterItemViewModel(
                artistName: "Death Grips",
                imageURL: URL(string: "http://notarealimageurl3.notreal.net")!,
                externalURL: URL(string: "http://notarealurl3.notreal.net")!
            ),
        ]
        viewModel = ListenLaterViewModel(dao: FakeListenLaterStore(items: items))
        XCTAssertEqual(expected, viewModel.items)
        // We need to fulfill the expectation since we declare it in setUp
        // A small sacrifice so that I don't have to redeclare it in all of the
        // other tests
        exp.fulfill()
        waitForExpectations(timeout: 1) {_ in}
    }

    func testOnRowTapped() {
        let index = 8
        viewModel = ListenLaterViewModel(
            dao: FakeListenLaterStore(items: FakeData.lastListenItems)
        )
        final class ListeningDelegate: ListenLaterViewModelDelegate {
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
}
