import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class OnboardingViewControllerTest: KIFTestCase {
    private var controller: OnboardingViewController!
    private var delegate: FakeOnboardingDelegate!

    override func setUp() {
        setupController()
    }

    private func setupController(
        delegate: FakeOnboardingDelegate = FakeOnboardingDelegate(showLoginResult: .success("123"))
    ) {
        let viewModel = OnboardingViewModel(
            userAuthenticator: FakeAuthenticator()
        )
        self.delegate = delegate
        viewModel.delegate = delegate
        controller = OnboardingViewController(viewModel: viewModel)
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        window.rootViewController = controller
    }

    func testInitialScreen() {
        tester().waitForAnimationsToFinish()
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testSecondScreen() {
        tester().waitForAnimationsToFinish()
        tester().swipeView(
            withAccessibilityLabel: "onboarding_view_accessibility_text".localized,
            in: .left
        )
        tester().waitForAnimationsToFinish()
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testSignInButton() {
        tester().tapView(withAccessibilityLabel: "sign_in_text".localized)
        XCTAssertEqual(1, delegate.showLoginCallCount)
    }

    func testAuthenticatingScreen() {
        tester().tapView(withAccessibilityLabel: "sign_in_text".localized)
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testErrorScreen() {
        let delegate = FakeOnboardingDelegate(
            showLoginResult: .failure(FakeError.testError)
        )
        setupController(delegate: delegate)
        tester().tapView(withAccessibilityLabel: "sign_in_text".localized)
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }
}
