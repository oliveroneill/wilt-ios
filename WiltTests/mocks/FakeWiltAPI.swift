@testable import Wilt

struct Timespan: Hashable {
    let from: Int64
    let to: Int64
}

class FakeWiltAPI: WiltAPI {
    private let topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>]
    private let sameResponseToAnything: Result<[TopArtistData], Error>?
    var topArtistsPerWeekCalls = [(from: Int64, to: Int64)]()

    init(topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>] = [:],
         sameResponseToAnything: Result<[TopArtistData], Error>? = nil) {
        self.topArtistPerWeekResult = topArtistPerWeekResult
        self.sameResponseToAnything = sameResponseToAnything
    }

    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void) {
        topArtistsPerWeekCalls.append((from: from, to: to))
        guard let response = sameResponseToAnything else {
            if let result = topArtistPerWeekResult[Timespan(from: from, to: to)] {
                completion(result)
            }
            return
        }
        completion(response)
    }
}
