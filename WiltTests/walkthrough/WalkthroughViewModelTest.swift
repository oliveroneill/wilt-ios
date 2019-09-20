import XCTest

@testable import Wilt

class WalkthroughViewModelTest: XCTestCase {
    func testOnViewAppeared() {
        let viewModel = WalkthroughViewModel(
            userAuthenticator: FakeAuthenticator(),
            spotifyAuthoriser: FakeAuthoriser()
        )
        var state: WalkthroughViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onViewAppeared()
        XCTAssertEqual(WalkthroughViewState.walkthrough, state)
    }

    func testOnSignInButtonPressedChangesState() {
        let mockAuthoriser = FakeAuthoriser()
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        var state: WalkthroughViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(WalkthroughViewState.authenticating, state)
    }

    func testOnSignInButtonPressedCallsAuthorise() {
        let mockAuthoriser = FakeAuthoriser()
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(1, mockAuthoriser.authoriseCallCount)
        // Ensure we didn't attempt to login since the fake authoriser
        // will not return anything by default
        XCTAssertEqual(0, mockAuthenticator.signUpCalls.count)
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceeds() {
        let expected = "a_spotify_token_for_tests"
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success(expected))
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.onSignInButtonPressed()
        XCTAssertEqual([expected], mockAuthenticator.signUpCalls)
        // Ensure we didn't attempt to login since the fake authenticator
        // will not return anything by default
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseFails() {
        let expected = FakeError.testError
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .failure(expected))
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.onSignInButtonPressed()
        // Ensure we don't continue since we failed
        XCTAssertEqual(0, mockAuthenticator.signUpCalls.count)
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceedsAndSignUpSucceeds() {
        let expected = "sign_up_custom_token"
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success(expected)
        )
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.onSignInButtonPressed()
        XCTAssertEqual([expected], mockAuthenticator.loginCalls)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceedsAndSignUpFails() {
        let expected = FakeError.testError
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .failure(expected)
        )
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthSucceedsSignUpSucceedsAndLoginSucceeds() {
        let expected = "your_username"
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success("346451"),
            loginResult: .success(expected)
        )
        class TestDelegate: WalkthroughViewModelDelegate {
            var userID: String?
            func loggedIn(userID: String) {
                self.userID = userID
            }
            func showInfo() {}
        }
        let delegate = TestDelegate()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(expected, delegate.userID)
    }

    func testOnSignInButtonPressedAndAuthSucceedsSignUpSucceedsAndLoginFails() {
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success("346451"),
            loginResult: .failure(FakeError.testError)
        )
        class TestDelegate: WalkthroughViewModelDelegate {
            var userID: String?
            func loggedIn(userID: String) {
                self.userID = userID
            }
            func showInfo() {}
        }
        let delegate = TestDelegate()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertNil(delegate.userID)
    }

    func testOnSignInButtonPressedChangesToFailState() {
        let mockAuthoriser = FakeAuthoriser(authoriseResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .failure(FakeError.testError)
        )
        let viewModel = WalkthroughViewModel(
            userAuthenticator: mockAuthenticator,
            spotifyAuthoriser: mockAuthoriser
        )
        var state: WalkthroughViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(WalkthroughViewState.loginError, state)
    }

    func testOnInfoButtonPressed() {
        class TestDelegate: WalkthroughViewModelDelegate {
            var infoCalls = 0
            func loggedIn(userID: String) {}
            func showInfo() {
                infoCalls += 1
            }
        }
        let delegate = TestDelegate()
        let viewModel = WalkthroughViewModel(
            userAuthenticator: FakeAuthenticator(),
            spotifyAuthoriser: FakeAuthoriser()
        )
        viewModel.delegate = delegate
        viewModel.onInfoButtonPressed()
        XCTAssertEqual(1, delegate.infoCalls)
    }
}
