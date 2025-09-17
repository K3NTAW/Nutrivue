import Foundation
import UserNotifications

class NotificationService {
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            completion(success, error)
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
