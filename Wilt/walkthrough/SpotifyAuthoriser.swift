import Keys

import Foundation

/// Authoriser for Spotify Web API. This mostly just exists for mocking.
/// I would have made this a more generic authorisation flow but since
/// events are being sent all the way from the AppDelegate, it seemed
/// important to make it clear that those were Spotify events and not to
/// generalise it
protocol SpotifyAuthoriser {
    /// Authorise the app to use Spotify for this user
    ///
    /// - Parameter onComplete: Called on authorisation completion
    func authorise(onComplete: @escaping ((Result<String, Error>) -> Void))

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
    private var onAuthorisationComplete: ((Result<String, Error>) -> Void)?

    func authorise(onComplete: @escaping ((Result<String, Error>) -> Void)) {
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

/// Custom Spotify auth errors
///
/// - noCodeGiven: If the Spotify auth code is empty, meaning the cancel button
/// was pressed
enum SpotifyAuthoriserError: Error {
    case noCodeGiven
}

extension SpotifyAppAuthoriser: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {}

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        onAuthorisationComplete?(.failure(error))
    }

    func sessionManager(manager: SPTSessionManager, shouldRequestAccessTokenWith code: String) -> Bool {
        // There seems to be a bug when using Spotify with the web view,
        // if the user presses the Cancel button then we'll receive a
        // shouldRequestAccessToken with an empty code
        guard code.count > 0 else {
            onAuthorisationComplete?(
                .failure(SpotifyAuthoriserError.noCodeGiven)
            )
            return false
        }
        onAuthorisationComplete?(.success(code))
        return true
    }
}
