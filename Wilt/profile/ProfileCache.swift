import CoreData

/// A protocol for requests made for the profile screen
protocol ProfileAPI {
    func topArtist(timeRange: String, index: Int,
                   completion: @escaping (Result<TopArtistInfo, Error>) -> Void)
    func topTrack(timeRange: String, index: Int,
                  completion: @escaping (Result<TopTrackInfo, Error>) -> Void)
}

/// A cache for the profile screen. This will used cached values when possible
/// and make calls to the underlying network when the cache is expired or is
/// empty. The max cache time is 1 day
class ProfileCache: ProfileAPI {
    private let backgroundContext: NSManagedObjectContext
    private let networkAPI: ProfileAPI
    // We'll let things sit in cache for one day maximum
    fileprivate static let maxCacheIntervalSeconds = TimeInterval(60 * 60 * 24)

    /// Create a ProfileCache
    ///
    /// - Parameters:
    ///   - backgroundContext: The context to complete Core Data operations on
    ///   - networkAPI: Where to make requests when the cache is no good
    init(backgroundContext: NSManagedObjectContext, networkAPI: ProfileAPI) {
        self.backgroundContext = backgroundContext
        self.networkAPI = networkAPI
    }

    private func upsert(artist: TopArtistInfo, timeRange: String, index: Int) throws {
        var upsertError: Error?
        backgroundContext.performAndWait {
            let existing = try? getArtist(timeRange: timeRange, index: index)
            let obj = existing ?? TopArtistInfoEntity(context: backgroundContext)
            obj.name = artist.name
            obj.count = artist.count
            obj.lastPlayed = artist.lastPlayed
            obj.imageURL = artist.imageURL
            obj.lastUpdated = Date()
            obj.timeRange = timeRange
            obj.index = Int32(index)
            do {
                try backgroundContext.save()
            } catch {
                upsertError = error
            }
        }
        if let error = upsertError {
            throw error
        }
    }

    private func upsert(track: TopTrackInfo, timeRange: String, index: Int) throws {
        var upsertError: Error?
        backgroundContext.performAndWait {
            let existing = try? getTrack(timeRange: timeRange, index: index)
            let obj = existing ?? TopTrackInfoEntity(context: backgroundContext)
            obj.name = track.name
            obj.totalPlayTimeSeconds = Int64(track.totalPlayTime)
            obj.lastPlayed = track.lastPlayed
            obj.imageURL = track.imageURL
            obj.lastUpdated = Date()
            obj.timeRange = timeRange
            obj.index = Int32(index)
            do {
                try backgroundContext.save()
            } catch {
                upsertError = error
            }
        }
        if let error = upsertError {
            throw error
        }
    }

    private func getArtist(timeRange: String, index: Int) throws -> TopArtistInfoEntity? {
        let fetchRequest: NSFetchRequest<TopArtistInfoEntity> = TopArtistInfoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(timeRange = %@) AND (index = %d)",
            timeRange,
            index
        )
        fetchRequest.fetchLimit = 1
        let fetchResult = try backgroundContext.execute(fetchRequest)
        let result = fetchResult as? NSAsynchronousFetchResult<NSFetchRequestResult>
        return result?.finalResult?.first as? TopArtistInfoEntity
    }

    private func getTrack(timeRange: String, index: Int) throws -> TopTrackInfoEntity? {
        let fetchRequest: NSFetchRequest<TopTrackInfoEntity> = TopTrackInfoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(timeRange = %@) AND (index = %d)",
            timeRange,
            index
        )
        fetchRequest.fetchLimit = 1
        let fetchResult = try backgroundContext.execute(fetchRequest)
        let result = fetchResult as? NSAsynchronousFetchResult<NSFetchRequestResult>
        return result?.finalResult?.first as? TopTrackInfoEntity
    }

    func topArtist(timeRange: String, index: Int,
                   completion: @escaping (Result<TopArtistInfo, Error>) -> Void) {
        var artist: TopArtistInfo?
        backgroundContext.performAndWait {
            let artistEntity = try? getArtist(
                timeRange: timeRange,
                index: index
            )
            // If it's out of date then don't bother using it
            if artistEntity?.isOutOfDate ?? false {
                artist = nil
            } else {
                artist = artistEntity?.toData()
            }
        }
        if let artist = artist {
            completion(.success(artist))
        } else {
            networkAPI.topArtist(timeRange: timeRange, index: index) { [unowned self] in
                switch ($0) {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let artist):
                    // Ignore error on upsert so that we still show the user
                    // the result
                    try? self.upsert(
                        artist: artist,
                        timeRange: timeRange,
                        index: index
                    )
                    completion(.success(artist))
                }
            }
        }
    }

    func topTrack(timeRange: String, index: Int,
                  completion: @escaping (Result<TopTrackInfo, Error>) -> Void) {
        var track: TopTrackInfo?
        backgroundContext.performAndWait {
            let trackEntity = try? getTrack(timeRange: timeRange, index: index)
            // If it's out of date then don't bother using it
            if trackEntity?.isOutOfDate ?? false {
                track = nil
            } else {
                track = trackEntity?.toData()
            }
        }
        if let track = track {
            completion(.success(track))
        } else {
            networkAPI.topTrack(timeRange: timeRange, index: index) { [unowned self] in
                switch ($0) {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let track):
                    // Ignore error on upsert so that we still show the user
                    // the result
                    try? self.upsert(
                        track: track,
                        timeRange: timeRange,
                        index: index
                    )
                    completion(.success(track))
                }
            }
        }
    }
}

extension TopArtistInfoEntity {
    var isOutOfDate: Bool {
        return Date().timeIntervalSince(lastUpdated!) >= ProfileCache.maxCacheIntervalSeconds
    }

    func toData() -> TopArtistInfo {
        // We'll error if any of the values are nil. This shouldn't occur but
        // I wonder if there's a better way to handle this
        guard let name = name, let imageURL = imageURL else {
            fatalError("Unexpected nil stored in Core Data")
        }
        return TopArtistInfo(
            name: name,
            count: count,
            lastPlayed: lastPlayed,
            imageURL: imageURL
        )
    }
}

extension TopTrackInfoEntity {
    var isOutOfDate: Bool {
        return Date().timeIntervalSince(lastUpdated!) >= ProfileCache.maxCacheIntervalSeconds
    }

    func toData() -> TopTrackInfo {
        // We'll error if any of the values are nil. This shouldn't occur but
        // I wonder if there's a better way to handle this
        guard let name = name, let imageURL = imageURL else {
            fatalError("Unexpected nil stored in Core Data")
        }
        return TopTrackInfo(
            name: name,
            totalPlayTime: TimeInterval(totalPlayTimeSeconds),
            lastPlayed: lastPlayed,
            imageURL: imageURL
        )
    }
}
