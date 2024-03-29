import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

final class SettingsViewControllerTest: KIFTestCase {
    private var controller: SettingsViewController!
    private var testDelegate: TestDelegate!

    final class TestDelegate: SettingsViewControllerDelegate {
        var contactUsCalls = 0
        var closeCalls = 0
        var logoutCalls = 0
        func contactUs() {
            contactUsCalls += 1
        }

        func close() {
            closeCalls += 1
        }

        func logOut() {
            logoutCalls += 1
        }
    }

    override func setUp() {
        testDelegate = TestDelegate()
        setupController()
    }

    private func setupController(loggedIn: Bool = true) {
        controller = SettingsViewController(loggedIn: loggedIn)
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

    func testLogOut() {
        tester().waitForAnimationsToFinish()
        controller.delegate = testDelegate
        tester().tapView(withAccessibilityLabel: "logout_text".localized)
        XCTAssertEqual(1, testDelegate.logoutCalls)
    }

    func testContactUs() {
        tester().waitForAnimationsToFinish()
        controller.delegate = testDelegate
        tester().tapView(
            withAccessibilityLabel: "about_cell_accessibility_text".localized
        )
        XCTAssertEqual(1, testDelegate.contactUsCalls)
    }

    func testNotLoggedIn() {
        setupController(loggedIn: false)
        tester().waitForAnimationsToFinish()
        // expect(self.controller.view).to(recordSnapshot())
        expect(self.controller.view).to(haveValidSnapshot())
    }
}
