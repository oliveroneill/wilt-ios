@testable import Wilt

final class FakeListenLaterDao: ListenLaterDao {
    var items: [ListenLaterArtist]
    var onInsert: ((ListenLaterArtist) throws -> Void)?
    var onDelete: ((String) throws -> Void)?

    init(items: [ListenLaterArtist]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func insert(item: ListenLaterArtist) throws {
        try onInsert?(item)
    }

    func contains(name: String) throws -> Bool {
        items.contains { $0.name == name }
    }

    func delete(name: String) throws {
        items.removeAll { $0.name == name }
        try onDelete?(name)
    }
}
