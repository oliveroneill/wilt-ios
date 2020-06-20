import Foundation

/// Errors that occur when parsing the response from Wilt API
///
/// - unexpectedNil: A value was nil when it shouldn't be
enum TrackHistoryError: Error {
    case unexpectedNil
}

struct TrackHistoryData: Equatable {
    let songName: String
    let artistName: String
    let date: Date
    let imageURL: URL
    let externalURL: URL
    let trackID: String

    /// Convert a network response into a `TrackHistoryData` struct
    ///
    /// - Parameter dict: A dictionary that should represent a TrackHistoryData value
    /// - Returns: The created TrackHistoryData value
    /// - Throws: If we couldn't parse this data
    static func from(dict: [String:Any]) throws -> TrackHistoryData {
        guard let songName = dict["song_name"] as? String,
            let artistName = dict["artist_name"] as? String,
            let trackID = dict["track_id"] as? String,
            let imageURL = URL(string: dict["imageUrl"] as? String ?? ""),
            let externalURL = URL(string: dict["externalUrl"] as? String ?? ""),
            let dateDict = dict["date"] as? [String:Any],
            let dateString = dateDict["value"] as? String,
            let date = WiltAPIDateFormatters.formatter.date(from: dateString) else {
                throw TrackHistoryError.unexpectedNil
        }
        return TrackHistoryData(
            songName: songName,
            artistName: artistName,
            date: date,
            imageURL: imageURL,
            externalURL: externalURL,
            trackID: trackID
        )
    }
}

extension TrackHistoryEntity {
    /// A helper function to convert the Core Data representation into a plain
    /// Swift object format
    ///
    /// - Returns: A struct representation of the Core Data format
    func toData() -> TrackHistoryData {
        // We'll error if any of the values are nil. This shouldn't occur but
        // I wonder if there's a better way to handle this
        guard let songName = songName,
            let artistName = artistName,
            let date = date,
            let trackID = trackID,
            let imageURL = imageURL,
            let externalURL = externalURL else {
                fatalError("Unexpected nil stored in Core Data")
        }
        return TrackHistoryData(
            songName: songName,
            artistName: artistName,
            date: date,
            imageURL: imageURL,
            externalURL: externalURL,
            trackID: trackID
        )
    }
}
