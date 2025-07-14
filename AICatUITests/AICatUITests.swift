//
//  AICatUITests.swift
//  AICatUITests
//
//  Created by Lei Pan on 2025/7/14.
//

import XCTest

final class AICatUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

//        XCUIDevice.shared.orientation = .portrait
//        XCUIDevice.shared.appearance = .light
//
//        let simulatedLocation = CLLocation(latitude: 28.3114, longitude: -81.5535)
//        XCUIDevice.shared.location = XCUILocation(location: simulatedLocation)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.activate()
        let element = app/*@START_MENU_TOKEN@*/.buttons["chatlist-button"]/*[[".otherElements",".buttons[\"Conversation\"]",".buttons[\"chatlist-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        element.tap()
        app.buttons["list-add-conversation-button"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["AICat Main"].waitForExistence(timeout: 3.0), "AICat Main")
        XCTAssertTrue(
            app.staticTexts["add-conversation-title"].waitForExistence(timeout: 3.0), "New Chat")
        app/*@START_MENU_TOKEN@*/.buttons["xmark"]/*[[".otherElements",".buttons[\"Close\"]",".buttons[\"xmark\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        element.tap()
        // Use XCTAssert and related functions to verify your tests produce the correct results.

//        let app = XCUIApplication()
//        app.launch()
//        app.cells["Landmark-186"].tap()
//        XCTAssertTrue(
//            app.staticTexts["Landmark-186"].waitForExistence(timeout: 10.0)),
//        "Great Barrier exists"
//        )
//
//        let favoriteButton = app.buttons["Favorite"]
//        favoriteButton.tap()
//        XCTAssertTrue(
//            favoriteButton.wait(for: \.value, toEqual: true, timeout: 10.0),
//            "Great Barrier is a favorite"
//        )

//        let app = XCUIApplication()
//        let customURL = URL(string: "landmarks://great-barrier")!
//        XCUIDevice.shared.system.open(customURL)
//
//        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10.0))
//        XCTAssertTrue(app.staticTexts["Great Barrier Reef"].waitForExistence(timeout: 10.0))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
