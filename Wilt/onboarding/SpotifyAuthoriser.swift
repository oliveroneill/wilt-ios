import Keys

import Foundation
import SpotifyLogin

/// Authoriser for Spotify Web API. This mostly just exists for mocking.
/// I would have made this a more generic authorisation flow but since
/// events are being sent all the way from the AppDelegate, it seemed
/// important to make it clear that those were Spotify events and not to
/// generalise it
protocol SpotifyAuthoriser {
    /// Authorise the app to use Spotify for this user
    ///
    /// - Parameter onComplete: Called on authorisation completion
    func authorise(from: UIViewController,
                   onComplete: @escaping ((Result<String, Error>) -> Void))

    /// Called via the AppDelegate when the Spotify app returns the result
    /// of the authorisation flow. See AppDelegate's `application open` function
    func authorisationComplete(application: UIApplication, url: URL,
                               options: [UIApplication.OpenURLOptionsKey : Any])
}

/// SpotifyAuthoriser that will open the Spotify app if it's installed
/// or use web if it isn't.
/// NSObject is required to implement SPTSessionManagerDelegate
final class SpotifyAppAuthoriser: NSObject, SpotifyAuthoriser {
    private let canceledURL = URL(
        string: "wilt://spotify-login?error=user_canceled&error_description=User%20aborted"
    )!
    private var onAuthorisationComplete: ((Result<String, Error>) -> Void)?

    func authorise(from: UIViewController,
                   onComplete: @escaping ((Result<String, Error>) -> Void)) {
        let keys = WiltKeys()
        SpotifyLogin.shared.configure(
            clientID: keys.spotifyClientID,
            redirectURL: URL(string: keys.spotifyRedirectURI)!
        )
        onAuthorisationComplete = onComplete
        let requestedScopes: [Scope] = [
            .userReadEmail,
            .userReadRecentlyPlayed,
            .userReadTop
        ]
        SpotifyLoginPresenter.login(from: from, scopes: requestedScopes)
    }

    /// This will be called once Spotify returns and we've made it back
    /// to our application. These arguments will come from `AppDelegate`s
    /// `application open` function
    func authorisationComplete(application: UIApplication, url: URL,
                               options: [UIApplication.OpenURLOptionsKey : Any]) {
        // There seems to be a bug in the Spotify iOS SDK where user cancels
        // via the Spotify app don't trigger anything on the session manager.
        // This is a workaround
        guard url != canceledURL else {
            onAuthorisationComplete?(.failure(SpotifyAuthoriserError.userAbort))
            return
        }
        _ = SpotifyLogin.shared.applicationOpenURL(url) { [weak self] in
            if case let .failure(error) = $0 {
                self?.onAuthorisationComplete?(.failure(error))
            } else if case let .success(code) = $0 {
                guard code.count > 0 else {
                    self?.onAuthorisationComplete?(
                        .failure(SpotifyAuthoriserError.noCodeGiven)
                    )
                    return
                }
                self?.onAuthorisationComplete?(.success(code))
            }
        }
    }
}

/// Custom Spotify auth errors
///
/// - noCodeGiven: If the Spotify auth code is empty, meaning the cancel button
/// was pressed
/// - userAbort: The user cancelled the auth flow
enum SpotifyAuthoriserError: Error {
    case noCodeGiven
    case userAbort
}
