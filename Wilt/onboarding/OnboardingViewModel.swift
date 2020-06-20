import Keys

/// The view state of the onboarding controller
///
/// - onboarding: Showing the walkthrough
/// - authenticating: Should show a loading spinner while authenticating
/// - loginError: Something went wrong
enum OnboardingViewState: Equatable {
    case onboarding
    case authenticating
    case loginError
}

final class OnboardingViewModel {
    var onViewUpdate: ((OnboardingViewState) -> Void)?
    private let userAuthenticator: Authenticator
    weak var delegate: OnboardingViewModelDelegate?

    init(userAuthenticator: Authenticator = FirebaseAuthentication()) {
        self.userAuthenticator = userAuthenticator
    }

    func onViewAppeared() {
        // The default state will show the walkthrough
        onViewUpdate?(.onboarding)
    }

    func onInfoButtonPressed() {
        delegate?.showInfo()
    }

    func onSignInButtonPressed() {
        // Start authorising
        let redirectURI = WiltKeys().spotifyRedirectURI
        delegate?.showLogin { [weak self] in
            guard let self = self else { return }
            let authCode: String
            do {
               authCode = try $0.get()
            } catch {
               print("Spotify error", error)
               self.onViewUpdate?(.loginError)
               return
            }
            // Update state to display the loading spinner
            self.onViewUpdate?(.authenticating)
            self.userAuthenticator.signUp(
               authCode: authCode,
               redirectURI: redirectURI
            ) { [weak self] in
               guard let self = self else { return }
               let token: String
               do {
                   token = try $0.get()
               } catch {
                   print("Sign up error", error)
                   self.onViewUpdate?(.loginError)
                   return
               }
               self.userAuthenticator.login(token: token) { [weak self] in
                   guard let self = self else { return }
                   let userID: String
                   do {
                       userID = try $0.get()
                   } catch {
                       print("Login error", error)
                       self.onViewUpdate?(.loginError)
                       return
                   }
                   print("Logged in", userID)
                   self.delegate?.loggedIn(userID: userID)
               }
            }
        }
    }
}

/// The delegate for events that occur within the onboarding view
protocol OnboardingViewModelDelegate: class {
    func loggedIn(userID: String)
    func showLogin(onComplete: @escaping ((Result<String, Error>) -> Void))
    func showInfo()
}
