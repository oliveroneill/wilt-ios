@testable import Wilt

class FakeAuthenticator: Authenticator {
    /// This will store the authCode passed into signUp. We won't test the
    /// redirect URI
    var signUpCalls = [String]()
    var loginCalls = [String]()

    var currentUser: String? = nil

    private let signUpResult: Result<String, Error>?
    private let loginResult: Result<String, Error>?

    init(signUpResult: Result<String, Error>? = nil,
         loginResult: Result<String, Error>? = nil) {
        self.signUpResult = signUpResult
        self.loginResult = loginResult
    }

    func signUp(authCode: String, redirectURI: String,
                callback: @escaping (Result<String, Error>) -> Void) {
        signUpCalls.append(authCode)
        if let result = signUpResult {
            callback(result)
        }
    }

    func login(token: String,
               callback: @escaping (Result<String, Error>) -> Void) {
        loginCalls.append(token)
        if let result = loginResult {
            callback(result)
        }
    }
}
