import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @Query(sort: \Meal.date) private var meals: [Meal]
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var totalCaloriesToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
    }
    
    private var totalFoodItemsToday: Int {
        todaysMeals.flatMap { $0.items }.count
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
                VStack(spacing: 20) {
                    // Greeting
                    Text(greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let user, let goals = user.goals {
                        
                        // Calorie Progress Ring
                        ZStack {
                            ProgressRingView(progress: totalCaloriesToday / goals.calories, color: .accentColor)
                                .frame(width: 220, height: 220)
                            
                            VStack {
                                Text("\(totalCaloriesToday, specifier: "%.0f")")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("kcal consumed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 20)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Calorie Intake")
                        .accessibilityValue("\(totalCaloriesToday, specifier: "%.0f") of \(goals.calories, specifier: "%.0f") kcal")
                        
                        // Macronutrient Progress Bars
                        GroupBox {
                            VStack(spacing: 15) {
                                MacroProgressView(name: "Protein", current: totalProteinToday, goal: goals.protein, color: .red)
                                MacroProgressView(name: "Carbs", current: totalCarbsToday, goal: goals.carbohydrates, color: .green)
                                MacroProgressView(name: "Fat", current: totalFatToday, goal: goals.fat, color: .orange)
                            }
                        } label: {
                            Text("Macronutrients")
                                .font(.headline)
                        }
                        
                    } else {
                        Text("No user data found. Complete onboarding to see your dashboard.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
                .id(totalFoodItemsToday)
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DashboardView()
}
