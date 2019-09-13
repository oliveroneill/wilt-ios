import Firebase

protocol WiltAPI {
    func topArtistsPerWeek(from: Int64, to: Int64,
                           completion: @escaping (Result<[TopArtistData], Error>) -> Void)
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
}
