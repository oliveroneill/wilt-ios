@testable import Wilt

final class FakePlayHistoryDao: PlayHistoryDao {
    var items: [TopArtistData]
    var batchUpsertCalls = [[TopArtistData]]()

    init(items: [TopArtistData]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func batchUpsert(items: [TopArtistData]) throws {
        batchUpsertCalls.append(items)
    }
}
