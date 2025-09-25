//
//  NourivoUITests.swift
//  NourivoUITests
//
//  Created by Kenta Waibel on 17.09.2025.
//

import XCTest

final class NourivoUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Onboarding screen should be presented
        XCTAssert(app.navigationBars["Tell us about you"].waitForExistence(timeout: 5))
        
        app.textFields["Age"].tap()
        app.textFields["Age"].typeText("30")
        
        app.buttons["gender_picker"].tap()
        app.buttons["Male"].tap()

        app.textFields["Weight (kg)"].tap()
        app.textFields["Weight (kg)"].typeText("80")
        
        app.textFields["Height (cm)"].tap()
        app.textFields["Height (cm)"].typeText("180")
        
        app.buttons["activity_level_picker"].tap()
        app.buttons["Sedentary"].tap()

        app.buttons["Save and Continue"].tap()
        
        // After onboarding, the dashboard should be visible
        XCTAssert(app.navigationBars["Dashboard"].waitForExistence(timeout: 5))
    }
}
