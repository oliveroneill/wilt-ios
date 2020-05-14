@testable import Wilt

final class FakeTrackHistoryDao: TrackHistoryDao {
    var items: [TrackHistoryData]
    var batchInsertCalls = [[TrackHistoryData]]()

    init(items: [TrackHistoryData]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func batchInsert(items: [TrackHistoryData]) throws {
        batchInsertCalls.append(items)
    }
}
