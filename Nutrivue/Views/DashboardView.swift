import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @Query(sort: \Meal.date) private var meals: [Meal]
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var totalCaloriesToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProteinToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbsToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.carbohydrates }
    }
    
    private var totalFatToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    if let user, let goals = user.goals {
                        
                        // Calorie Progress Ring
                        ZStack {
                            ProgressRingView(progress: totalCaloriesToday / goals.calories, color: .blue)
                                .frame(width: 200, height: 200)
                            
                            VStack {
                                Text("\(totalCaloriesToday, specifier: "%.0f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("kcal / \(goals.calories, specifier: "%.0f")")
                                    .font(.caption)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Calorie Intake")
                        .accessibilityValue("\(totalCaloriesToday, specifier: "%.0f") of \(goals.calories, specifier: "%.0f") kcal")
                        
                        // Macronutrient Progress Bars
                        HStack(spacing: 20) {
                            MacroProgressView(name: "Protein", current: totalProteinToday, goal: goals.protein, color: .red)
                            MacroProgressView(name: "Carbs", current: totalCarbsToday, goal: goals.carbohydrates, color: .green)
                            MacroProgressView(name: "Fat", current: totalFatToday, goal: goals.fat, color: .orange)
                        }
                        
                    } else {
                        Text("No user data found.")
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
}
