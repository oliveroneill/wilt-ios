import XCTest

@testable import Wilt

final class OnboardingViewModelTest: XCTestCase {
    func testOnViewAppeared() {
        let delegate = FakeOnboardingDelegate()
        let viewModel = OnboardingViewModel(
            userAuthenticator: FakeAuthenticator()
        )
        viewModel.delegate = delegate
        var state: OnboardingViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onViewAppeared()
        XCTAssertEqual(OnboardingViewState.onboarding, state)
    }

    func testOnSignInButtonPressedChangesState() {
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        var state: OnboardingViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(OnboardingViewState.authenticating, state)
    }

    func testOnSignInButtonPressedCallsAuthorise() {
        let delegate = FakeOnboardingDelegate()
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(1, delegate.showLoginCallCount)
        // Ensure we didn't attempt to login since the fake authoriser
        // will not return anything by default
        XCTAssertEqual(0, mockAuthenticator.signUpCalls.count)
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceeds() {
        let expected = "a_spotify_token_for_tests"
        let delegate = FakeOnboardingDelegate(showLoginResult: .success(expected))
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual([expected], mockAuthenticator.signUpCalls)
        // Ensure we didn't attempt to login since the fake authenticator
        // will not return anything by default
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseFails() {
        let expected = FakeError.testError
        let delegate = FakeOnboardingDelegate(showLoginResult: .failure(expected))
        let mockAuthenticator = FakeAuthenticator()
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        // Ensure we don't continue since we failed
        XCTAssertEqual(0, mockAuthenticator.signUpCalls.count)
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceedsAndSignUpSucceeds() {
        let expected = "sign_up_custom_token"
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success(expected)
        )
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual([expected], mockAuthenticator.loginCalls)
    }

    func testOnSignInButtonPressedAndAuthoriseSucceedsAndSignUpFails() {
        let expected = FakeError.testError
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .failure(expected)
        )
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(0, mockAuthenticator.loginCalls.count)
    }

    func testOnSignInButtonPressedAndAuthSucceedsSignUpSucceedsAndLoginSucceeds() {
        let expected = "your_username"
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success("346451"),
            loginResult: .success(expected)
        )
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual([expected], delegate.loggedInCalls)
    }

    func testOnSignInButtonPressedAndAuthSucceedsSignUpSucceedsAndLoginFails() {
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .success("346451"),
            loginResult: .failure(FakeError.testError)
        )
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(0, delegate.loggedInCalls.count)
    }

    func testOnSignInButtonPressedChangesToFailState() {
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let mockAuthenticator = FakeAuthenticator(
            signUpResult: .failure(FakeError.testError)
        )
        let viewModel = OnboardingViewModel(
            userAuthenticator: mockAuthenticator
        )
        viewModel.delegate = delegate
        var state: OnboardingViewState?
        viewModel.onViewUpdate = {
            state = $0
        }
        viewModel.onSignInButtonPressed()
        XCTAssertEqual(OnboardingViewState.loginError, state)
    }

    func testOnInfoButtonPressed() {
        let delegate = FakeOnboardingDelegate(showLoginResult: .success("1234"))
        let viewModel = OnboardingViewModel(
            userAuthenticator: FakeAuthenticator()
        )
        viewModel.delegate = delegate
        viewModel.onInfoButtonPressed()
        XCTAssertEqual(1, delegate.showInfoCallCount)
    }
}
