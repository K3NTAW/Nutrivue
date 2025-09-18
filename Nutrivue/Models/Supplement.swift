import Foundation
import SwiftData

enum SupplementScheduleType: Int, Codable {
    case daily = 0
    case specificDays = 1
    case weekly = 2
}

@Model
class Supplement {
    var id: UUID
    var name: String
    var dosage: String?
    var notes: String?
    // Persist-safe schedule fields
    var scheduleTypeRaw: Int
    // Store specific days as a bitmask where bit 1..7 correspond to Sunday..Saturday
    var specificDaysMask: Int?
    var weeklyWeekday: Int?
    // Persist-safe time fields
    var timeHour: Int?
    var timeMinute: Int?
    
    var createdAt: Date
    var isArchived: Bool
    
    @Relationship(deleteRule: .cascade) var intakes: [SupplementIntake]
    
    init(name: String, dosage: String?, notes: String?, scheduleType: SupplementScheduleType, specificDaysMask: Int?, weeklyWeekday: Int?, timeHour: Int?, timeMinute: Int?) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.notes = notes
        self.scheduleTypeRaw = scheduleType.rawValue
        self.specificDaysMask = specificDaysMask
        self.weeklyWeekday = weeklyWeekday
        self.timeHour = timeHour
        self.timeMinute = timeMinute
        self.createdAt = Date()
        self.isArchived = false
        self.intakes = []
    }
}

@Model
class SupplementIntake {
    var id: UUID
    var date: Date
    var supplementID: UUID
    
    init(supplementID: UUID, date: Date) {
        self.id = UUID()
        self.supplementID = supplementID
        self.date = date
    }
}

extension Supplement {
    var scheduleType: SupplementScheduleType { SupplementScheduleType(rawValue: scheduleTypeRaw) ?? .daily }
    
    func isScheduledForToday(reference: Date = Date()) -> Bool {
        let calendar = Calendar.current
        switch scheduleType {
        case .daily:
            return true
        case .specificDays:
            let weekday = calendar.component(.weekday, from: reference)
            return specificDaysList().contains(weekday)
        case .weekly:
            let weekday = calendar.component(.weekday, from: reference)
            return weeklyWeekday == weekday
        }
    }
    
    func isScheduledForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch scheduleType {
        case .daily:
            return true
        case .specificDays:
            let weekday = calendar.component(.weekday, from: date)
            return specificDaysList().contains(weekday)
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            return weeklyWeekday == weekday
        }
    }

    func specificDaysList() -> [Int] {
        if let mask = specificDaysMask {
            var days: [Int] = []
            for day in 1...7 {
                let bit = 1 << (day - 1)
                if (mask & bit) != 0 { days.append(day) }
            }
            return days
        }
        var days: [Int] = []
        return days
    }
    
    func timeComponents() -> DateComponents? {
        guard let h = timeHour, let m = timeMinute else { return nil }
        var c = DateComponents()
        c.hour = h
        c.minute = m
        return c
    }
    
    func wasTakenToday(reference: Date = Date()) -> Bool {
        let calendar = Calendar.current
        return intakes.contains { calendar.isDate($0.date, inSameDayAs: reference) }
    }
}


