import Foundation

/// View model for a single artist view
struct ArtistViewModel: Equatable {
    let artistName: String
    let imageURL: URL?
    let externalURL: URL
}

