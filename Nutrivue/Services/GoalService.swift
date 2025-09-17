import Foundation

class GoalService {
    
    private let activityMultipliers: [ActivityLevel: Double] = [
        .sedentary: 1.2,
        .light: 1.375,
        .moderate: 1.55,
        .active: 1.725,
        .veryActive: 1.9
    ]
    
    func calculateGoals(for user: User) -> Goals {
        let bmr = calculateBMR(for: user)
        let tdee = bmr * (activityMultipliers[user.activityLevel] ?? 1.2)
        
        // For now, we'll set the calorie goal to the TDEE.
        // We can add logic for weight loss/gain later.
        // Macronutrient split will be a standard 40% carbs, 30% protein, 30% fat.
        
        let proteinCalories = tdee * 0.30
        let fatCalories = tdee * 0.30
        let carbCalories = tdee * 0.40
        
        let proteinGrams = proteinCalories / 4
        let fatGrams = fatCalories / 9
        let carbGrams = carbCalories / 4
        
        return Goals(calories: tdee, protein: proteinGrams, carbohydrates: carbGrams, fat: fatGrams)
    }
    
    private func calculateBMR(for user: User) -> Double {
        // Using the Mifflin-St Jeor Equation
        let weightTerm = 10 * user.weight
        let heightTerm = 6.25 * user.height
        let ageTerm = 5 * Double(user.age)
        
        switch user.gender {
        case .male:
            return weightTerm + heightTerm - ageTerm + 5
        case .female:
            return weightTerm + heightTerm - ageTerm - 161
        }
    }
}
