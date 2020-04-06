/// Structs to outline the JSON format of the response from the Spotify Web API
/// See: https://developer.spotify.com/documentation/web-api/reference/search/search/
struct SpotifyAPISearchResult: Decodable, Equatable {
    let artists: SpotifyArtists

    static func parse(data: Data) throws -> SpotifyAPISearchResult {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(
            SpotifyAPISearchResult.self,
            from: data
        )
    }
}

struct SpotifyArtists: Decodable, Equatable {
    let items: [SpotifyArtist]
}

struct SpotifyArtistImage: Decodable, Equatable {
    let url: String
}

struct SpotifyArtist: Decodable, Equatable {
    let name: String
    let images: [SpotifyArtistImage]
    let externalUrls: SpotifyURLs
}

struct SpotifyURLs: Decodable, Equatable {
    let spotify: String
}

