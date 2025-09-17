import Foundation
import SwiftData

@Model
class Goals {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double

    init(calories: Double, protein: Double, carbohydrates: Double, fat: Double) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
    }
}
