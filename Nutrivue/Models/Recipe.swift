import Foundation
import SwiftData

@Model
class Recipe {
    var id: UUID
    var name: String
    var notes: String?
    var servings: Double
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    
    @Relationship(deleteRule: .cascade) var ingredients: [RecipeIngredient]
    
    init(name: String, notes: String? = nil, servings: Double = 1.0, ingredients: [RecipeIngredient] = []) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.servings = servings
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFavorite = false
        self.ingredients = ingredients
    }
}

@Model
class RecipeIngredient {
    var id: UUID
    var name: String
    var amountGrams: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var sourceBarcode: String?
    var sourceImageUrl: String?
    
    init(name: String, amountGrams: Double, caloriesPer100g: Double, proteinPer100g: Double, carbsPer100g: Double, fatPer100g: Double, sourceBarcode: String? = nil, sourceImageUrl: String? = nil) {
        self.id = UUID()
        self.name = name
        self.amountGrams = amountGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.sourceBarcode = sourceBarcode
        self.sourceImageUrl = sourceImageUrl
    }
}

extension RecipeIngredient {
    func totals() -> (cal: Double, p: Double, c: Double, f: Double) {
        let factor = amountGrams / 100.0
        return (
            factor * caloriesPer100g,
            factor * proteinPer100g,
            factor * carbsPer100g,
            factor * fatPer100g
        )
    }
}

extension Recipe {
    func totalNutrition() -> (cal: Double, p: Double, c: Double, f: Double) {
        ingredients.reduce((0,0,0,0)) { acc, ing in
            let t = ing.totals()
            return (acc.0 + t.cal, acc.1 + t.p, acc.2 + t.c, acc.3 + t.f)
        }
    }
    
    func perServingNutrition() -> (cal: Double, p: Double, c: Double, f: Double) {
        let t = totalNutrition()
        guard servings > 0 else { return (0,0,0,0) }
        return (t.cal / servings, t.p / servings, t.c / servings, t.f / servings)
    }
    
    func scaledNutrition(servings count: Double) -> (cal: Double, p: Double, c: Double, f: Double) {
        let per = perServingNutrition()
        return (per.cal * count, per.p * count, per.c * count, per.f * count)
    }
}


