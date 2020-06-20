import Foundation

/// A protocol for requests made for artist activity graph
protocol ArtistActivityAPI {
    func getArtistActivity(artistName: String,
                           completion: @escaping (Result<[ArtistActivity], Error>) -> Void)
}

/// A cache for the artist activity screen. This will used cached values when possible
/// and make calls to the underlying network when the cache is expired or is
/// empty. The max cache time is 10 days
final class ArtistActivityCache: ArtistActivityAPI {
    private static let cacheDirectoryName = "artist_activity_cache"
    // We'll let things sit in cache for ten days maximum
    private static let maxCacheIntervalSeconds = TimeInterval(
        60 * 60 * 24 * 10
    )
    private let networkAPI: ArtistActivityAPI
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(
        label: "com.oliveroneill.Wilt.ArtistActivityCache.queue"
    )

    private lazy var cacheDirectoryURL: URL = {
        let directoryURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        let path = directoryURLs[0].appendingPathComponent(
            ArtistActivityCache.cacheDirectoryName
        )
        try? fileManager.createDirectory(
            at: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return path
    }()

    /// Create an ArtistActivityCache
    ///
    /// - Parameters:
    ///   - networkAPI: Where to make requests when the cache is no good
    init(networkAPI: ArtistActivityAPI) {
        self.networkAPI = networkAPI
    }

    private func cacheFileURL(_ artistName: String) -> URL {
        // TODO: the artist name should be hashed or encoded in some way to
        // avoid invalid file paths being created
        cacheDirectoryURL.appendingPathComponent(artistName + ".cache")
    }

    private func upsert(artistName: String, data: Data) throws {
        let fileURL = cacheFileURL(artistName)
        try data.write(to: fileURL)
    }

    func getArtistActivity(artistName: String,
                           completion: @escaping (Result<[ArtistActivity], Error>) -> Void) {
        queue.async {
            let fileURL = self.cacheFileURL(artistName)
            // Use cache if possible
            if let cachedData = try? Data(contentsOf: fileURL),
                let data = try? JSONDecoder().decode(
                    [ArtistActivity].self,
                    from: cachedData
                ) {
                completion(.success(data))
                return
            }
            self.networkAPI.getArtistActivity(artistName: artistName) { [weak self] in
                guard let self = self else { return }
                // Attempt to insert the response into cache
                do {
                    let activity = try $0.get()
                    let data = try JSONEncoder().encode(activity)
                    try self.upsert(artistName: artistName, data: data)
                } catch {
                    print("cache error: \(error)")
                }
                completion($0)
            }
        }
    }

    /// Clear all elements from the cache
    ///
    /// This will block the calling thread until the operation is complete
    func clear() throws {
        // Use the queue to ensure that we wait for items to finish being
        // written before clearing them
        try queue.sync {
            let directoryContents = try fileManager.contentsOfDirectory(
                at: cacheDirectoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsSubdirectoryDescendants
            )
            for path in directoryContents {
                try fileManager.removeItem(at: path)
            }
        }
    }
}
