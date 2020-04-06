import XCTest

@testable import Wilt

final class SpotifyAPITest: XCTestCase {
    func testParse() {
        let response = """
        {
          "artists": {
            "href": "https://api.spotify.com/v1/search?query=tania+bowra&offset=0&limit=20&type=artist",
            "items": [ {
              "external_urls": {
                "spotify": "https://open.spotify.com/artist/08td7MxkoHQkXnWAYD8d6Q"
              },
              "genres": [ ],
              "href": "https://api.spotify.com/v1/artists/08td7MxkoHQkXnWAYD8d6Q",
              "id": "08td7MxkoHQkXnWAYD8d6Q",
              "images": [ {
                "height": 640,
                "url": "https://i.scdn.co/image/f2798ddab0c7b76dc2d270b65c4f67ddef7f6718",
                "width": 640
              } ],
              "name": "Tania Bowra",
              "popularity": 0,
              "type": "artist",
              "uri": "spotify:artist:08td7MxkoHQkXnWAYD8d6Q"
            } ],
            "limit": 20,
            "next": null,
            "offset": 0,
            "previous": null,
            "total": 1
          }
        }
        """.data(using: .utf8)!
        let expected = SpotifyAPISearchResult(
            artists: SpotifyArtists(
                items: [
                    SpotifyArtist(
                        name: "Tania Bowra",
                        images: [
                            SpotifyArtistImage(
                                url: "https://i.scdn.co/image/f2798ddab0c7b76dc2d270b65c4f67ddef7f6718"
                            )
                        ],
                        externalUrls: SpotifyURLs(
                            spotify: "https://open.spotify.com/artist/08td7MxkoHQkXnWAYD8d6Q"
                        )
                    )
                ]
            )
        )
        do {
            let results = try SpotifyAPISearchResult.parse(data: response)
            XCTAssertEqual(expected, results)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testParseWithMissingValues() {
        // Valid JSON but missing necessary entries
        let response = """
        {
          "artists": {
            "href": "https://api.spotify.com/v1/search?query=tania+bowra&offset=0&limit=20&type=artist",
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try SpotifyAPISearchResult.parse(data: response))
    }

    func testParseWithInvalidJSON() {
        // Incomplete
        let response = """
        {
          "artists": {
            "href": "https://api.spotify.com/v1/search?query=tania+bowra&offset=0&limit=20&type=artist",
            "items": [
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try SpotifyAPISearchResult.parse(data: response))
    }
}
