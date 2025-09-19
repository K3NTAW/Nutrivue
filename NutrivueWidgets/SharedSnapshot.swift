import Foundation

struct SharedSnapshot: Codable {
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

enum SharedSnapshotReader {
    static func read() -> SharedSnapshot? {
        let suite = UserDefaults(suiteName: "group.com.nutrivue.app")
        guard let data = suite?.data(forKey: "WidgetSnapshot.v1") else { return nil }
        return try? JSONDecoder().decode(SharedSnapshot.self, from: data)
    }
}


