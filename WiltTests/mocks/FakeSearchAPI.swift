@testable import Wilt

class CountingCancellable: Cancellable {
    var onCancel: (() -> Void)? = nil
    private(set) var cancelCount = 0

    func cancel() {
        cancelCount += 1
        onCancel?()
    }
}

class FakeSearchAPI: SearchAPI {
    var onSearch: ((String) -> Result<[ArtistSearchResult], Error>)? = nil
    let cancellable = CountingCancellable()

    func prepare(completion: @escaping (Error?) -> Void) {}

    func search(artistQuery: String,
                completion: @escaping (Result<[ArtistSearchResult], Error>) -> Void) -> Cancellable? {
        if let onSearch = onSearch {
            completion(onSearch(artistQuery))
        }
        return cancellable
    }
}
