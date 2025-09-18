import Foundation

class GoalService {
    
    private let activityMultipliers: [ActivityLevel: Double] = [
        .sedentary: 1.2,
        .light: 1.375,
        .moderate: 1.55,
        .active: 1.725,
        .veryActive: 1.9
    ]
    
    enum GoalType: String, CaseIterable { case maintain, lose, gain, muscle }

    func calculateGoals(for user: User, goal: GoalType = .maintain) -> Goals {
        let bmr = calculateBMR(for: user)
        let tdee = bmr * (activityMultipliers[user.activityLevel] ?? 1.2)
        let adjustedCalories: Double
        switch goal {
        case .maintain:
            adjustedCalories = tdee
        case .lose:
            adjustedCalories = tdee * 0.85 // ~15% deficit
        case .gain:
            adjustedCalories = tdee * 1.10 // ~10% surplus
        case .muscle:
            adjustedCalories = tdee * 1.05 // small surplus + higher protein
        }
        // Macro splits
        let (pRatio, cRatio, fRatio): (Double, Double, Double) = {
            switch goal {
            case .maintain: return (0.30, 0.40, 0.30)
            case .lose: return (0.35, 0.35, 0.30)
            case .gain: return (0.25, 0.50, 0.25)
            case .muscle: return (0.35, 0.35, 0.30)
            }
        }()
        let proteinCalories = adjustedCalories * pRatio
        let fatCalories = adjustedCalories * fRatio
        let carbCalories = adjustedCalories * cRatio
        
        let proteinGrams = proteinCalories / 4
        let fatGrams = fatCalories / 9
        let carbGrams = carbCalories / 4
        return Goals(calories: adjustedCalories, protein: proteinGrams, carbohydrates: carbGrams, fat: fatGrams, goalTypeRaw: goal.rawValue)
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
