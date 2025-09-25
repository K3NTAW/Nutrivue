import Foundation
import SwiftData

@Model
class User {
    var id: UUID
    var age: Int
    var gender: Gender
    var weight: Double // in kg
    var height: Double // in cm
    var activityLevel: ActivityLevel
    var unitSystem: UnitSystem
    var dietaryNotes: String
    
    @Relationship(deleteRule: .cascade) var goals: Goals?

    init(age: Int, gender: Gender, weight: Double, height: Double, activityLevel: ActivityLevel, goals: Goals?, unitSystem: UnitSystem = .metric, dietaryNotes: String = "") {
        self.id = UUID()
        self.age = age
        self.gender = gender
        self.weight = weight
        self.height = height
        self.activityLevel = activityLevel
        self.goals = goals
        self.unitSystem = unitSystem
        self.dietaryNotes = dietaryNotes
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive
}

enum UnitSystem: String, Codable, CaseIterable {
    case metric
    case imperial
}

enum Gender: String, Codable, CaseIterable {
    case male
    case female
}
