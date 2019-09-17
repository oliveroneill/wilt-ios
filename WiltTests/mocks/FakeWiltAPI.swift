@testable import Wilt

struct Timespan: Hashable {
    let from: Int64
    let to: Int64
}

struct TopSomethingRequest: Hashable {
    let timeRange: String
    let index: Int
}

class FakeWiltAPI: WiltAPI {
    private let topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>]
    private let topArtistPerWeekAnythingResponse: Result<[TopArtistData], Error>?
    private let topArtistResult: [TopSomethingRequest:Result<TopArtistInfo, Error>]
    private let topTrackResult: [TopSomethingRequest:Result<TopTrackInfo, Error>]
    var topArtistsPerWeekCalls = [(from: Int64, to: Int64)]()
    var topArtistCalls = [(timeRange: String, index: Int)]()
    var topTrackCalls = [(timeRange: String, index: Int)]()

    init(topArtistPerWeekResult: [Timespan:Result<[TopArtistData], Error>] = [:],
         topArtistResult: [TopSomethingRequest:Result<TopArtistInfo, Error>] = [:],
         topTrackResult: [TopSomethingRequest:Result<TopTrackInfo, Error>] = [:],
         topArtistPerWeekAnythingResponse: Result<[TopArtistData], Error>? = nil) {
        self.topArtistPerWeekResult = topArtistPerWeekResult
        self.topArtistPerWeekAnythingResponse = topArtistPerWeekAnythingResponse
        self.topArtistResult = topArtistResult
        self.topTrackResult = topTrackResult
    }

    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void) {
        topArtistsPerWeekCalls.append((from: from, to: to))
        guard let response = topArtistPerWeekAnythingResponse else {
            if let result = topArtistPerWeekResult[Timespan(from: from, to: to)] {
                completion(result)
            }
            return
        }
        completion(response)
    }

    func topArtist(timeRange: String, index: Int,
                   completion: @escaping (Result<TopArtistInfo, Error>) -> Void) {
        topArtistCalls.append((timeRange: timeRange, index: index))
        if let result = topArtistResult[TopSomethingRequest(timeRange: timeRange, index: index)] {
            completion(result)
        }

    }

    func topTrack(timeRange: String, index: Int,
                  completion: @escaping (Result<TopTrackInfo, Error>) -> Void) {
        topTrackCalls.append((timeRange: timeRange, index: index))
        if let result = topTrackResult[TopSomethingRequest(timeRange: timeRange, index: index)] {
            completion(result)
        }
    }
}
