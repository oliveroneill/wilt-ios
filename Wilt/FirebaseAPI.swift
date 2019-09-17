import Firebase

protocol WiltAPI {
    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void)
    func topArtist(timeRange: String, index: Int,
                   completion: @escaping (Result<TopArtistInfo, Error>) -> Void)
    func topTrack(timeRange: String, index: Int,
                  completion: @escaping (Result<TopTrackInfo, Error>) -> Void)
}

/// Special errors from network calls
///
/// - loggedOut: If the user is logged out
enum WiltAPIError: Error {
    case loggedOut
}

class FirebaseAPI: WiltAPI {
    private lazy var functions = Functions.functions(region: "asia-northeast1")
    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void) {
        let data: [String:Any] = [
            "start": from,
            "end": to
        ]
        functions
            .httpsCallable("getTopArtistPerWeek")
            .call(data) {
                guard let data = $0?.data as? [[String: Any]] else {
                    guard let error = $1 else {
                        fatalError("No error and no response?")
                    }
                    // Handle unauthenticated error specifically, so that we
                    // can replace this with our own error to easily verify
                    if let error = error as NSError?,
                        error.domain == FunctionsErrorDomain,
                        error.code == FunctionsErrorCode.unauthenticated.rawValue {
                        completion(.failure(WiltAPIError.loggedOut))
                        return
                    }
                    completion(.failure(error))
                    return
                }
                do {
                    let items = try data.map {
                        try TopArtistData.from(dict: $0)
                    }
                    completion(.success(items))
                } catch {
                    completion(.failure(error))
                }
        }
    }

    func topArtist(timeRange: String, index: Int,
                   completion: @escaping (Result<TopArtistInfo, Error>) -> Void) {
        let data: [String:Any] = [
            "timeRange": timeRange,
            "index": index
        ]
        functions
            .httpsCallable("topArtist")
            .call(data) {
                guard let data = $0?.data as? [String: Any] else {
                    guard let error = $1 else {
                        fatalError("No error and no response?")
                    }
                    // Handle unauthenticated error specifically, so that we
                    // can replace this with our own error to easily verify
                    if let error = error as NSError?,
                        error.domain == FunctionsErrorDomain,
                        error.code == FunctionsErrorCode.unauthenticated.rawValue {
                        completion(.failure(WiltAPIError.loggedOut))
                        return
                    }
                    completion(.failure(error))
                    return
                }
                do {
                    let info = try TopArtistInfo.from(dict: data)
                    completion(.success(info))
                } catch {
                    completion(.failure(error))
                }
        }
    }

    func topTrack(timeRange: String, index: Int,
                  completion: @escaping (Result<TopTrackInfo, Error>) -> Void) {
        let data: [String:Any] = [
            "timeRange": timeRange,
            "index": index
        ]
        functions
            .httpsCallable("topTrack")
            .call(data) {
                guard let data = $0?.data as? [String: Any] else {
                    guard let error = $1 else {
                        fatalError("No error and no response?")
                    }
                    // Handle unauthenticated error specifically, so that we
                    // can replace this with our own error to easily verify
                    if let error = error as NSError?,
                        error.domain == FunctionsErrorDomain,
                        error.code == FunctionsErrorCode.unauthenticated.rawValue {
                        completion(.failure(WiltAPIError.loggedOut))
                        return
                    }
                    completion(.failure(error))
                    return
                }
                do {
                    let info = try TopTrackInfo.from(dict: data)
                    completion(.success(info))
                } catch {
                    completion(.failure(error))
                }
        }
    }
}

/// Useful date formatters due to responses from the Wilt API
enum WiltAPIDateFormatters {
    /// For dates of the format yyyy-MM-dd
    static var dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// For ISO 8601 date formatter
    static var formatter: ISO8601DateFormatter = {
        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }()
}

/// For specififying time range for `topArtist` and `topTrack` for Wilt API
enum TimeRange {
    case shortTerm
    case mediumTerm
    case longTerm

    public var description: String {
        switch (self) {
        case .shortTerm:
            return "short_term"
        case .mediumTerm:
            return "medium_term"
        case .longTerm:
            return "long_term"
        }
    }
}

struct TopArtistInfo {
    let name: String
    let count: Int
    /// Will be nil if it hasn't been played since joining Wilt
    let lastPlayed: Date?
    let imageURL: URL

    static func from(dict: [String:Any]) throws -> TopArtistInfo {
        guard let name = dict["name"] as? String,
            let count = dict["count"] as? Int,
            let dateDict = dict["lastPlay"] as? [String:Any]?,
            let imageURL = URL(string: dict["imageUrl"] as? String ?? "") else {
                throw TopArtistError.unexpectedNil
        }
        let date: Date?
        if let dateString = dateDict?["value"] as? String {
            date = WiltAPIDateFormatters.formatter.date(from: dateString)
            // If the date exists and doesn't match format then we should fail
            guard date != nil else {
                throw TopArtistError.unexpectedNil
            }
        } else {
            date = nil
        }
        return TopArtistInfo(
            name: name,
            count: count,
            lastPlayed: date,
            imageURL: imageURL
        )
    }
}

struct TopTrackInfo {
    let name: String
    let totalPlayTime: TimeInterval
    /// Will be nil if it hasn't been played since joining Wilt
    let lastPlayed: Date?
    let imageURL: URL

    static func from(dict: [String:Any]) throws -> TopTrackInfo {
        guard let name = dict["name"] as? String,
            let totalPlayTimeMs = dict["totalPlayTimeMs"] as? Int64,
            let dateDict = dict["lastPlay"] as? [String:Any]?,
            let imageURL = URL(string: dict["imageUrl"] as? String ?? "") else {
                throw TopArtistError.unexpectedNil
        }
        let date: Date?
        if let dateString = dateDict?["value"] as? String {
            date = WiltAPIDateFormatters.formatter.date(from: dateString)
            // If the date exists and doesn't match format then we should fail
            guard date != nil else {
                throw TopArtistError.unexpectedNil
            }
        } else {
            date = nil
        }
        return TopTrackInfo(
            name: name,
            totalPlayTime: TimeInterval(totalPlayTimeMs / 1000),
            lastPlayed: date,
            imageURL: imageURL
        )
    }
}
