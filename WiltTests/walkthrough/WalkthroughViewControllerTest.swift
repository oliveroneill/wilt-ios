import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class WalkthroughViewControllerTest: KIFTestCase {
    private var controller: WalkthroughViewController!
    private var authoriser: FakeAuthoriser!

    override func setUp() {
        setupController()
    }

    private func setupController(
        authoriser: FakeAuthoriser = FakeAuthoriser(),
        authenticator: FakeAuthenticator = FakeAuthenticator()
    ) {
        self.authoriser = authoriser
        let viewModel = WalkthroughViewModel(
            userAuthenticator: authenticator,
            spotifyAuthoriser: authoriser
        )
        controller = WalkthroughViewController(viewModel: viewModel)
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
        tester().swipeView(withAccessibilityLabel: "walkthrough_view", in: .left)
        tester().waitForAnimationsToFinish()
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testSignInButton() {
        tester().tapView(withAccessibilityLabel: "sign_in_button")
        XCTAssertEqual(1, authoriser.authoriseCallCount)
    }

    func testAuthenticatingScreen() {
        tester().tapView(withAccessibilityLabel: "sign_in_button")
         // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testErrorScreen() {
        let mockAuthoriser = FakeAuthoriser(
            authoriseResult: .failure(FakeError.testError)
        )
        setupController(authoriser: mockAuthoriser)
        tester().tapView(withAccessibilityLabel: "sign_in_button")
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }
}