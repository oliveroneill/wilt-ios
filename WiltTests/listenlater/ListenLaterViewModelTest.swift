import XCTest

@testable import Wilt

final class ListenLaterViewModelTest: XCTestCase {
    private var viewModel: ListenLaterViewModel!
    private var dao: FakeListenLaterDao!

    override func setUp() {
        dao = FakeListenLaterDao(items: FakeData.listenLaterItems)
        viewModel = ListenLaterViewModel(dao: dao)
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
        viewModel = ListenLaterViewModel(dao: FakeListenLaterDao(items: items))
        XCTAssertEqual(expected, viewModel.items)
    }

    func testOnRowTapped() {
        let exp = expectation(description: "Should trigger open")
        let index = 8
        viewModel = ListenLaterViewModel(
            dao: FakeListenLaterDao(items: FakeData.listenLaterItems)
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

    func testOnDeletePressed() {
        let exp = expectation(description: "Should trigger delete")
        viewModel.onRowsDeleted = {
            XCTAssertEqual([3], $0)
            exp.fulfill()
        }
        viewModel.onDeletePressed(rowIndex: 3)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testOnDeletePressedTriggersDelete() {
        let exp = expectation(description: "Should trigger delete")
        dao.onDelete = {
            XCTAssertEqual(FakeData.listenLaterItems[3].name, $0)
            exp.fulfill()
        }
        viewModel.onDeletePressed(rowIndex: 3)
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
