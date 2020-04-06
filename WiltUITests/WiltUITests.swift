import XCTest

final class WiltUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testListenLaterSnapshot() {
        snapshot("ListenLater")
    }

    func testProfileSnapshot() {
        let tabBarsQuery = XCUIApplication().tabBars
        tabBarsQuery.buttons["Profile"].tap()
        snapshot("Profile")
    }

    func testFeedSnapshot() {
        let tabBarsQuery = XCUIApplication().tabBars
        tabBarsQuery.buttons["Feed"].tap()
        snapshot("Feed")
    }
}
