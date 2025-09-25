import Foundation
import SwiftData

// By defining the snapshot structure here, we make this service self-contained
// and ensure it can compile without needing to see the widget's files.
struct AppSnapshot: Codable {
    struct Macros: Codable { let p: Double; let c: Double; let f: Double; let pGoal: Double; let cGoal: Double; let fGoal: Double }
    struct Supplements: Codable {
        struct Item: Codable { let name: String; let time: Date; let taken: Bool }
        let due: Int; let taken: Int; let nextName: String?; let nextTime: Date?; let list: [Item]
    }
    struct Weekly: Codable { let last7: [Double] }
    let date: Date
    let calories: Double
    let calorieGoal: Double
    let macros: Macros
    let supplements: Supplements
    let weekly: Weekly
}


// This service is responsible for creating and saving the data snapshot
// that is shared with all the widgets.

@MainActor
class SnapshotService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func writeSnapshot() {
        // 1. Fetch all necessary data from SwiftData
        guard let user = try? modelContext.fetch(FetchDescriptor<User>()).first,
              let goals = user.goals else {
            return
        }
        
        let meals = (try? modelContext.fetch(FetchDescriptor<Meal>())) ?? []
        let todaysMeals = meals.filter { Calendar.current.isDateInToday($0.date) }
        
        // 2. Calculate all the values needed for the snapshot
        let totalCalories = todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
        let totalProtein = todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.protein }
        let totalCarbs = todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.carbohydrates }
        let totalFat = todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.fat }
        
        // (Supplement and Weekly data can be added here later)
        
        // 3. Create the snapshot object
        let snapshot = AppSnapshot(
            date: Date(),
            calories: totalCalories,
            calorieGoal: goals.calories,
            macros: .init(p: totalProtein, c: totalCarbs, f: totalFat, pGoal: goals.protein, cGoal: goals.carbohydrates, fGoal: goals.fat),
            supplements: .init(due: 0, taken: 0, nextName: nil, nextTime: nil, list: []),
            weekly: .init(last7: [])
        )
        
        // 4. Save the snapshot to the shared UserDefaults
        if let suite = UserDefaults(suiteName: "group.com.nutrivue.app"),
           let data = try? JSONEncoder().encode(snapshot) {
            suite.setValue(data, forKey: "WidgetSnapshot.v1")
        }
    }
}
