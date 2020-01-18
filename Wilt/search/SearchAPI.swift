import Keys

/// The search result format from SearchAPI
struct ArtistSearchResult {
    let artistName: String
    let imageURL: URL?
    let externalURL: URL
}

/// A protocol for something that can be cancelled. Used to cancel search requests
protocol Cancellable {
    func cancel()
}

/// Make URLSessionDataTask cancellable since this is what's used for our searches
extension URLSessionDataTask: Cancellable {}

protocol SearchAPI {
    /// Prepare the search API since the user will start searching soon
    /// - Parameter completion: When the API is ready. The argument will be nil if no errors
    /// occurred
    func prepare(completion: @escaping (Error?) -> Void)

    /// Search for an artist. Returns a cancellable operation, in case the user gives up on the search
    /// - Parameters:
    ///   - artistQuery: What to search for
    ///   - completion: Returns the results of the search
    func search(artistQuery: String,
                completion: @escaping (Result<[ArtistSearchResult], Error>) -> Void) -> Cancellable?
}

/// Special errors from network calls
///
/// - unexpectedResponse: If the response is not expected
enum SearchAPIError: Error {
    case badQuery
    case unexpectedStatusCode
    case unexpectedResponse
}

/// A reference to a value that may not be set immediately
class Reference<T> {
    /// This can be set at some later point in time
    var value: T?
}

/// Ensure that `Reference<Callable?>` implements Cancellable
extension Reference: Cancellable where T == Cancellable? {
    func cancel() {
        value??.cancel()
    }
}

/// A Search API implementation using Spotify's Web API for the search. It also uses a Firebase function to
/// retrieve an authorisation token
final class SpotifySearchAPI: SearchAPI {
    private var spotifyAuthToken: String?

    /// Get an authorisation token
    /// - Parameter completion: Called with the token on success. This can return a reference to
    /// the value returned via the completion handler. This is useful for retrieving the cancellable
    /// task from a search request after we've retrieved the token
    private func getToken<T>(completion: @escaping (Result<String, Error>) -> T) -> Reference<T> {
        // We'll return a reference to a value returned from the completion
        // handler. The value won't be set until we've retrieved the auth token
        let ref = Reference<T>()
        NetworkActivityUtil.showNetworkIndicator()
        let keys = WiltKeys()
        URLSession.shared.dataTask(with: URL(string: keys.spotifyAuthTokenURL)!) {
            defer { NetworkActivityUtil.hideNetworkIndicator() }
            if let error = $2 {
                ref.value = completion(.failure(error))
                return
            }
            guard let data = try? JSONSerialization.jsonObject(with: $0 ?? Data()) as? [String:String] else {
                guard let error = $2 else {
                    fatalError("No error and no response?")
                }
                ref.value = completion(.failure(error))
                return
            }
            guard let token = data["token"] else {
                ref.value = completion(
                    .failure(SearchAPIError.unexpectedResponse)
                )
                return
            }
            ref.value = completion(.success(token))
        }.resume()
        return ref
    }

    func prepare(completion: @escaping (Error?) -> Void) {
        guard spotifyAuthToken == nil else { return }
        _ = getToken { [weak self] (result: Result<String, Error>) -> Void in
            guard let self = self else { return }
            do {
                self.spotifyAuthToken = try result.get()
                completion(nil)
            } catch {
                completion(error)
            }
            // Return nil since we aren't doing anything that can be cancelled
            return
        }
    }

    func search(artistQuery: String,
                completion: @escaping (Result<[ArtistSearchResult], Error>) -> Void) -> Cancellable? {
        guard let token = spotifyAuthToken else {
            // If there's no token then let's retrieve one now and use
            // that
            return getToken { [weak self] in
                guard let self = self else { return nil }
                do {
                    let token = try $0.get()
                    self.spotifyAuthToken = token
                    return self.search(
                        artistQuery: artistQuery,
                        token: token,
                        completion: completion
                    )
                } catch {
                    completion(.failure(error))
                    return nil
                }
            }
        }
        return search(
            artistQuery: artistQuery,
            token: token,
            completion: completion
        )
    }

    func search(artistQuery: String, token: String,
                completion: @escaping (Result<[ArtistSearchResult], Error>) -> Void) -> Cancellable? {
        NetworkActivityUtil.showNetworkIndicator()
        guard let searchText = artistQuery.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else {
            NetworkActivityUtil.hideNetworkIndicator()
            completion(.failure(SearchAPIError.badQuery))
            return nil
        }
        var request = URLRequest(
            url: URL(
                string: "https://api.spotify.com/v1/search?q=artist:\(searchText)*&type=artist"
            )!
        )
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) {
            defer { NetworkActivityUtil.hideNetworkIndicator() }
            if let error = $2 {
                completion(.failure(error))
                return
            }
            if ($1 as? HTTPURLResponse)?.statusCode != 200 {
                completion(.failure(SearchAPIError.unexpectedStatusCode))
                return
            }
            do {
                let results = try SpotifyAPISearchResult.parse(data: $0!)
                let artists = results.artists.items.map {
                    ArtistSearchResult(
                        artistName: $0.name,
                        imageURL: URL(optionalString: $0.images.first?.url),
                        externalURL: URL(string: $0.externalUrls.spotify)!
                    )
                }
                completion(.success(artists))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
}

/// Useful extension so that I can pass a URL an optional string and get out an optional URL, as opposed
/// to having to store the optional in a variable to pass it to URL
extension URL {
    init?(optionalString: String?) {
        if let string = optionalString {
            self.init(string: string)
        } else {
            return nil
        }
    }
}
