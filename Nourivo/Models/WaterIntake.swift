import Foundation
import SwiftData

@Model
class WaterIntake {
    var id: UUID
    var amount: Double // in milliliters
    var date: Date
    var timestamp: Date
    
    init(amount: Double, date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.timestamp = Date()
    }
    
    // Helper to get total water intake for a specific date
    static func totalForDate(_ date: Date, intakes: [WaterIntake]) -> Double {
        let calendar = Calendar.current
        return intakes
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Helper to get total water intake for today
    static func totalToday(intakes: [WaterIntake]) -> Double {
        return totalForDate(Date(), intakes: intakes)
    }
}
