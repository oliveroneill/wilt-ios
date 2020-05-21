@testable import Wilt

final class FakeTrackHistoryDao: TrackHistoryDao {
    var items: [TrackHistoryData]
    var batchInsertCalls = [[TrackHistoryData]]()
    var setArtistQueryCalls = [String?]()

    init(items: [TrackHistoryData]) {
        self.items = items
    }

    var onDataChange: (() -> Void)?
    func batchInsert(items: [TrackHistoryData]) throws {
        batchInsertCalls.append(items)
    }

    func setArtistQuery(artistQuery: String?) throws {
        setArtistQueryCalls.append(artistQuery)
    }
}
