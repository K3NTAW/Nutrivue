//
//  NourivoTests.swift
//  NourivoTests
//
//  Created by Kenta Waibel on 17.09.2025.
//

import XCTest
@testable import Nourivo

final class NourivoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    let goalService = GoalService()

    @Test func testBMRCalculationForMale() {
        let user = User(age: 30, gender: .male, weight: 80, height: 180, activityLevel: .sedentary, goals: nil)
        let goals = goalService.calculateGoals(for: user)
        
        // BMR = 10 * 80 + 6.25 * 180 - 5 * 30 + 5 = 800 + 1125 - 150 + 5 = 1780
        // TDEE = 1780 * 1.2 = 2136
        
        #expect(goals.calories == 2136)
    }
    
    @Test func testBMRCalculationForFemale() {
        let user = User(age: 25, gender: .female, weight: 60, height: 165, activityLevel: .moderate, goals: nil)
        let goals = goalService.calculateGoals(for: user)
        
        // BMR = 10 * 60 + 6.25 * 165 - 5 * 25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
        // TDEE = 1345.25 * 1.55 = 2085.1375
        
        #expect(goals.calories > 2085 && goals.calories < 2086)
    }

}
