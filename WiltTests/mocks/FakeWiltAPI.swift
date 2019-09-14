@testable import Wilt

struct Timespan: Hashable {
    let from: Int64
    let to: Int64
}

class FakeWiltAPI: WiltAPI {
    private let topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>]
    private let respondEmptyToEverything: Bool
    var topArtistsPerWeekCalls = [(from: Int64, to: Int64)]()

    init(topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>] = [:],
         respondEmptyToEverything: Bool = false) {
        self.topArtistPerWeekResult = topArtistPerWeekResult
        self.respondEmptyToEverything = respondEmptyToEverything
    }

    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void) {
        topArtistsPerWeekCalls.append((from: from, to: to))
        guard !respondEmptyToEverything else {
            completion(.success([]))
            return
        }
        if let result = topArtistPerWeekResult[Timespan(from: from, to: to)] {
            completion(result)
        }
    }
}
