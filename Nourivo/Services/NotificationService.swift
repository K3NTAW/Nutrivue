import Foundation
import UserNotifications

class NotificationService {
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Supplement Reminders
    func scheduleSupplementReminder(for supplement: Supplement) {
        guard let time = supplement.timeComponents() else { return }
        let identifiers = notificationIdentifiers(for: supplement)
        cancelSupplementReminder(for: supplement)
        let content = UNMutableNotificationContent()
        content.title = "Supplement Reminder"
        if let dosage = supplement.dosage, !dosage.isEmpty {
            content.body = "Take \(supplement.name) — \(dosage)"
        } else {
            content.body = "Take \(supplement.name)"
        }
        content.sound = .default
        
        let center = UNUserNotificationCenter.current()
        switch supplement.scheduleType {
        case .daily:
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(identifier: identifiers.first ?? UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        case .specificDays:
            for day in supplement.specificDaysList() {
                var components = time
                components.weekday = day
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "supp_\(supplement.id.uuidString)_d\(day)", content: content, trigger: trigger)
                center.add(request)
            }
        case .weekly:
            var components = time
            components.weekday = supplement.weeklyWeekday
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifiers.first ?? UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    func cancelSupplementReminder(for supplement: Supplement) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: supplement))
    }
    
    private func notificationIdentifiers(for supplement: Supplement) -> [String] {
        switch supplement.scheduleType {
        case .daily, .weekly:
            return ["supp_\(supplement.id.uuidString)"]
        case .specificDays:
            return supplement.specificDaysList().map { "supp_\(supplement.id.uuidString)_d\($0)" }
        }
    }
    
    func scheduleMealReminder(mealName: String, time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "Time to log your \(mealName)!"
        content.body = "Don't forget to log your meal to stay on track with your goals."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "meal_reminder_\(mealName)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelMealReminder(mealName: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["meal_reminder_\(mealName)"])
    }
}
