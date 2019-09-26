/// Errors that occur when parsing the response from Wilt API
///
/// - unexpectedNil: A value was nil when it shouldn't be
enum TopArtistError: Error {
    case unexpectedNil
}

struct TopArtistData: Equatable {
    let topArtist: String
    let count: Int64
    let date: Date
    let week: String
    let imageURL: URL
    let externalURL: URL

    /// Convert a network response into a `TopArtistData` struct
    ///
    /// - Parameter dict: A dictionary that should represent to a TopArtist
    /// - Returns: The created TopArtist value
    /// - Throws: If we couldn't parse this data
    static func from(dict: [String:Any]) throws -> TopArtistData {
        guard let topArtist = dict["top_artist"] as? String,
            let week = dict["week"] as? String,
            let count = dict["count"] as? Int64,
            let dateString = dict["date"] as? String,
            let imageURL = URL(string: dict["imageUrl"] as? String ?? ""),
            let externalURL = URL(string: dict["externalUrl"] as? String ?? ""),
            let date = WiltAPIDateFormatters.dateStringFormatter.date(
                from: dateString
            ) else {
                throw TopArtistError.unexpectedNil
        }
        return TopArtistData(
            topArtist: topArtist,
            count: count,
            date: date,
            week: week,
            imageURL: imageURL,
            externalURL: externalURL
        )
    }
}

extension TopArtist {
    /// A helper function to convert the Core Data representation into a plain
    /// Swift object format
    ///
    /// - Returns: A struct representation of the Core Data format
    func toData() -> TopArtistData {
        // We'll error if any of the values are nil. This shouldn't occur but
        // I wonder if there's a better way to handle this
        guard let topArtist = topArtist, let date = date,
            let week = week, let imageURL = imageURL,
            let externalURL = externalURL else {
                fatalError("Unexpected nil stored in Core Data")
        }
        return TopArtistData(
            topArtist: topArtist,
            count: count,
            date: date,
            week: week,
            imageURL: imageURL,
            externalURL: externalURL
        )
    }
}
