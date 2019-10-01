import XCTest

// TODO: these are currently disabled because I couldn't get all the
// dependencies installed correctly

// TODO: not really sure what I should be doing with these tests
// It seems like a lot of work to write end-to-end tests, especially with
// third party services, so I'll leave this to only test the onboarding for
// now
class WiltUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testShowsIntro() {
        let introText = app.staticTexts[
            "Welcome to Wilt. We'll keep track of what you listen to."
        ]
        XCTAssertTrue(introText.exists)
    }

    func testSlide() {
        app.otherElements
            .containing(.navigationBar, identifier:"Wilt.OnboardingView")
            .children(matching: .other).element
            /*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeUp()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let secondPageText = app.staticTexts[
            "Once you've signed up we'll start tracking your listens and new data will be available daily"
        ]
        XCTAssertTrue(secondPageText.exists)
    }
}
