import Keys

import Foundation

struct AuthInfo {
    let accessToken: String
    let refreshToken: String
    let expirationDate: Date
}

/// Authoriser for Spotify Web API. This mostly just exists for mocking.
/// I would have made this a more generic authorisation flow but since
/// events are being sent all the way from the AppDelegate, it seemed
/// important to make it clear that those were Spotify events and not to
/// generalise it
protocol SpotifyAuthoriser {
    /// Authorise the app to use Spotify for this user
    ///
    /// - Parameter onComplete: Called on authorisation completion
    func authorise(onComplete: @escaping ((Result<AuthInfo, Error>) -> Void))

    /// Called via the AppDelegate when the Spotify app returns the result
    /// of the authorisation flow. See AppDelegate's `application open` function
    func authorisationComplete(application: UIApplication, url: URL,
                               options: [UIApplication.OpenURLOptionsKey : Any])
}

/// SpotifyAuthoriser that will open the Spotify app if it's installed
/// or use web if it isn't.
/// NSObject is required to implement SPTSessionManagerDelegate
class SpotifyAppAuthoriser: NSObject, SpotifyAuthoriser {
    private lazy var sessionManager: SPTSessionManager = {
        // cocoapods-keys is used to store secrets
        let keys = WiltKeys()
        let spotifyClientID = keys.spotifyClientID
        let spotifyRedirectURL = URL(string: keys.spotifyRedirectURI)!
        var configuration = SPTConfiguration(
            clientID: spotifyClientID,
            redirectURL: spotifyRedirectURL
        )
        return SPTSessionManager(configuration: configuration, delegate: self)
    }()
    private var onAuthorisationComplete: ((Result<AuthInfo, Error>) -> Void)?

    func authorise(onComplete: @escaping ((Result<AuthInfo, Error>) -> Void)) {
        onAuthorisationComplete = onComplete
        let requestedScopes: SPTScope = [
            .userReadEmail,
            .userReadRecentlyPlayed,
            .userTopRead
        ]
        sessionManager.initiateSession(with: requestedScopes, options: .default)
    }

    /// This will be called once Spotify returns and we've made it back
    /// to our application. These arguments will come from `AppDelegate`s
    /// `application open` function
    func authorisationComplete(application: UIApplication, url: URL,
                               options: [UIApplication.OpenURLOptionsKey : Any]) {
        sessionManager.application(
            application,
            open: url,
            options: options
        )
    }
}

extension SpotifyAppAuthoriser: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print(
            AuthInfo(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expirationDate: session.expirationDate
            )
        )
        onAuthorisationComplete?(
            .success(
                AuthInfo(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    expirationDate: session.expirationDate
                )
            )
        )
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        onAuthorisationComplete?(.failure(error))
    }
}
