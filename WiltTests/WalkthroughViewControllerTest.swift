import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class WalkthroughViewControllerTest: KIFTestCase {
    private var controller: WalkthroughViewController!

    override func setUp() {
        controller = WalkthroughViewController()
        guard let window = UIApplication.shared.keyWindow else {
            XCTFail("Unexpected nil window")
            return
        }
        window.rootViewController = controller
    }

    func testInitialScreen() {
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testSecondScreen() {
        tester().swipeView(withAccessibilityLabel: "walkthrough_view", in: .left)
        tester().waitForAnimationsToFinish()
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }

    func testSignInButton() {
        class TestDelegate : WalkthroughViewControllerDelegate {
            private(set) var buttonPressed = false
            func onSignInButtonPressed() {
                buttonPressed = true
            }
        }
        let delegate = TestDelegate()
        controller.delegate = delegate
        tester().tapView(withAccessibilityLabel: "sign_in_button")
        XCTAssert(delegate.buttonPressed)
    }
}
