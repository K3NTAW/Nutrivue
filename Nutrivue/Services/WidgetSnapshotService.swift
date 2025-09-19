import Foundation
import SwiftData
import WidgetKit

struct WidgetSnapshot: Codable {
    struct Macros: Codable { let p: Double; let c: Double; let f: Double; let pGoal: Double; let cGoal: Double; let fGoal: Double }
    struct Supplements: Codable { let due: Int; let taken: Int; let nextName: String?; let nextTime: Date?; let list: [Item]
        struct Item: Codable { let name: String; let time: Date; let taken: Bool }
    }
    struct Weekly: Codable { let last7: [Double] }
    let date: Date
    let calories: Double
    let calorieGoal: Double
    let macros: Macros
    let supplements: Supplements
    let weekly: Weekly
}

class WidgetSnapshotService {
    private let modelContext: ModelContext
    private let suite = UserDefaults(suiteName: "group.com.nutrivue.app")
    private let key = "WidgetSnapshot.v1"
    
    init(modelContext: ModelContext) { self.modelContext = modelContext }
    
    func writeSnapshot() {
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            let user = users.first
            let goals = user?.goals
            // Today meals
            let mealsDesc = FetchDescriptor<Meal>()
            let meals = try modelContext.fetch(mealsDesc)
            let todayMeals = meals.filter { Calendar.current.isDateInToday($0.date) }
            let items = todayMeals.flatMap { $0.items }
            let calories = items.reduce(0) { $0 + $1.calories }
            let p = items.reduce(0) { $0 + $1.protein }
            let c = items.reduce(0) { $0 + $1.carbohydrates }
            let f = items.reduce(0) { $0 + $1.fat }
            // Supplements today
            let suppDesc = FetchDescriptor<Supplement>()
            let supps = try modelContext.fetch(suppDesc)
            let todaySupps = supps.filter { $0.isScheduledForToday() }
            let intakes = todaySupps.flatMap { $0.intakes }
            let takenCount = intakes.filter { Calendar.current.isDateInToday($0.date) }.count
            let dueCount = todaySupps.count
            let next = todaySupps.compactMap { s -> (String, Date)? in
                guard let comps = s.timeComponents(), let date = Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTimePreservingSmallerComponents) else { return nil }
                return (s.name, date)
            }.sorted { $0.1 < $1.1 }.first
            let suppList: [WidgetSnapshot.Supplements.Item] = todaySupps.compactMap { s in
                guard let comps = s.timeComponents(), let date = Calendar.current.date(from: comps) else { return nil }
                let isTaken = s.wasTakenToday()
                return .init(name: s.name, time: date, taken: isTaken)
            }
            // Weekly calories (last 7 days)
            let days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }.reversed()
            let last7 = days.map { day -> Double in
                let dayMeals = meals.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
                return dayMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
            }
            let snapshot = WidgetSnapshot(
                date: Date(),
                calories: calories,
                calorieGoal: goals?.calories ?? 2000,
                macros: .init(p: p, c: c, f: f, pGoal: goals?.protein ?? 0, cGoal: goals?.carbohydrates ?? 0, fGoal: goals?.fat ?? 0),
                supplements: .init(due: dueCount, taken: takenCount, nextName: next?.0, nextTime: next?.1, list: suppList),
                weekly: .init(last7: last7)
            )
            let data = try JSONEncoder().encode(snapshot)
            suite?.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // best effort
        }
    }
}


