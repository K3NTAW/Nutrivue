import Foundation
import SwiftData

@Model
class FoodItem {
    let id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    
    init(name: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
    }
}
