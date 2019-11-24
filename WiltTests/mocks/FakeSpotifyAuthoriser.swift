@testable import Wilt

final class FakeAuthoriser: SpotifyAuthoriser {
    var authoriseCallCount = 0
    var authorisationCompleteCallCount = 0
    private let authoriseResult: Result<String, Error>?

    init(authoriseResult: Result<String, Error>? = nil) {
        self.authoriseResult = authoriseResult
    }

    func authorise(onComplete: @escaping ((Result<String, Error>) -> Void)) {
        authoriseCallCount += 1
        if let result = authoriseResult {
            onComplete(result)
        }
    }

    func authorisationComplete(application: UIApplication, url: URL,
                               options: [UIApplication.OpenURLOptionsKey : Any]) {
        authorisationCompleteCallCount += 1
    }
}
