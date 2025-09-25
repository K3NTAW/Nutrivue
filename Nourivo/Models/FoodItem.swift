import Foundation
import SwiftData

@Model
class FoodItem {
    var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    // Saved serving size in grams used when adding this item. Optional for legacy items.
    var servingGrams: Double?
    // If this item came from a recipe, link it back for serving-based adjustments
    var sourceRecipeId: UUID?
    var recipeServingsUsed: Double?
    
    init(name: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double, servingGrams: Double? = nil, sourceRecipeId: UUID? = nil, recipeServingsUsed: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.servingGrams = servingGrams
        self.sourceRecipeId = sourceRecipeId
        self.recipeServingsUsed = recipeServingsUsed
    }
}
