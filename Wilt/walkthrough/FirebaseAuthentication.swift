import Firebase

protocol Authenticator {
    var currentUser: String? { get }
    func signUp(authCode: String, redirectURI: String,
                callback: @escaping (Result<String, Error>) -> Void)
    func login(token: String, callback: @escaping (Result<String, Error>) -> Void)
}

class FirebaseAuthentication: Authenticator {
    private let auth = Auth.auth()
    lazy var functions = Functions.functions(region: "asia-northeast1")
    /// Get the current logged in user, or null if there's no user logged in
    var currentUser: String? {
        return auth.currentUser?.uid
    }

    /// Sign up this user with specified Spotify authorisation code
    ///
    /// - Parameters:
    ///   - authCode: Spotify authorisation code
    ///   - redirectURI: The redirect URI as specified on Spotify dashboard
    ///   - callback: will be called with a custom authentication token from
    /// the Firebase function
    func signUp(authCode: String, redirectURI: String,
                callback: @escaping (Result<String, Error>) -> Void) {
        let data: [String:Any] = [
            "spotifyAuthCode": authCode,
            "spotifyRedirectUri": redirectURI
        ]
        functions
            .httpsCallable("signUp")
            .call(data) {
                guard let data = $0?.data as? [String: Any] else {
                    guard let error = $1 else {
                        fatalError("No error and no response?")
                    }
                    callback(.failure(error))
                    return
                }
                guard let token = data["token"] as? String else {
                    fatalError("Unexpected response from authenticated")
                }
                callback(.success(token))
            }
    }

    /// Login this user with specified custom auth token
    ///
    /// - Parameters:
    ///   - token: The custom token
    ///   - callback: will be called with the username of the logged in user
    func login(token: String, callback: @escaping (Result<String, Error>) -> Void) {
        auth.signIn(withCustomToken: token) {
            guard let data = $0 else {
                guard let error = $1 else {
                    fatalError("No error and no response?")
                }
                callback(.failure(error))
                return
            }
            callback(.success(data.user.uid))
        }
    }
}

extension Date {
    /// The seconds until we reach this date
    var secondsLeft: Int {
        return Int(timeIntervalSince(Date()))
    }
}
