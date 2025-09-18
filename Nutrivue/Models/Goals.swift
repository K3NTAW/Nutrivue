import Foundation
import SwiftData

@Model
class Goals {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var goalTypeRaw: String?

    init(calories: Double, protein: Double, carbohydrates: Double, fat: Double, goalTypeRaw: String?) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.goalTypeRaw = goalTypeRaw
    }
}
