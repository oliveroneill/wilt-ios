import XCTest
import Nimble
import Nimble_Snapshots
import KIF

@testable import Wilt

class SettingsViewControllerTest: KIFTestCase {
    private var controller: SettingsViewController!
    private var testDelegate: TestDelegate!

    class TestDelegate: SettingsViewControllerDelegate {
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

    private func setupController() {
        controller = SettingsViewController()
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
        tester().tapView(withAccessibilityLabel: "logout_cell")
        XCTAssertEqual(1, testDelegate.logoutCalls)
    }

    func testContactUs() {
        tester().waitForAnimationsToFinish()
        controller.delegate = testDelegate
        tester().tapView(withAccessibilityLabel: "about_cell")
        XCTAssertEqual(1, testDelegate.contactUsCalls)
    }
}
