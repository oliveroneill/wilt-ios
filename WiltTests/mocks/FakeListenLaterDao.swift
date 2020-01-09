@testable import Wilt

final class FakeListenLaterDao: ListenLaterDao {
    var items: [ListenLaterArtist]
    var insertCalls = [ListenLaterArtist]()

    init(items: [ListenLaterArtist]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func insert(item: ListenLaterArtist) throws {
        insertCalls.append(item)
    }

    func contains(name: String) throws -> Bool {
        items.contains { $0.name == name }
    }

    func delete(name: String) throws {}
}
