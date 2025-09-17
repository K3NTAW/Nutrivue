import Foundation
import Combine
import SwiftData

class SettingsViewModel: ObservableObject {
    private let healthKitService = HealthKitService()
    private let notificationService = NotificationService()
    private var modelContext: ModelContext
    
    @Published var isHealthKitAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var userWeight: Double?
    @Published var activeEnergy: Double?
    
    @Published var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled {
                requestNotificationPermission()
            } else {
                cancelAllReminders()
            }
        }
    }
    @Published var breakfastReminderTime = Date()
    @Published var lunchReminderTime = Date()
    @Published var dinnerReminderTime = Date()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    private func requestNotificationPermission() {
        notificationService.requestAuthorization { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                    self.errorMessage = "Notification permission was denied."
                }
            }
        }
    }
    
    func scheduleReminders() {
        if notificationsEnabled {
            let breakfastTime = Calendar.current.dateComponents([.hour, .minute], from: breakfastReminderTime)
            notificationService.scheduleMealReminder(mealName: "Breakfast", time: breakfastTime)
            
            let lunchTime = Calendar.current.dateComponents([.hour, .minute], from: lunchReminderTime)
            notificationService.scheduleMealReminder(mealName: "Lunch", time: lunchTime)
            
            let dinnerTime = Calendar.current.dateComponents([.hour, .minute], from: dinnerReminderTime)
            notificationService.scheduleMealReminder(mealName: "Dinner", time: dinnerTime)
        }
    }
    
    private func cancelAllReminders() {
        notificationService.cancelMealReminder(mealName: "Breakfast")
        notificationService.cancelMealReminder(mealName: "Lunch")
        notificationService.cancelMealReminder(mealName: "Dinner")
    }
    
    func authorizeHealthKit() {
        healthKitService.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isHealthKitAuthorized = true
                    self?.fetchHealthData()
                } else if let error = error {
                    self?.errorMessage = "HealthKit Authorization Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchHealthData() {
        fetchWeight()
        fetchActiveEnergy()
    }
    
    private func fetchWeight() {
        healthKitService.fetchLatestWeight { [weak self] weight in
            DispatchQueue.main.async {
                self?.userWeight = weight
                if let weight {
                    self?.updateUserWeightInDB(newWeight: weight)
                }
            }
        }
    }
    
    private func fetchActiveEnergy() {
        healthKitService.fetchActiveEnergyBurned { [weak self] energy in
            DispatchQueue.main.async {
                self?.activeEnergy = energy
            }
        }
    }
    
    private func updateUserWeightInDB(newWeight: Double) {
        do {
            let userDescriptor = FetchDescriptor<User>()
            if let user = try modelContext.fetch(userDescriptor).first {
                user.weight = newWeight
                try modelContext.save()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update user weight in the database."
            }
        }
    }
}
