import Foundation
import SwiftData

class HealthSyncService {
    private let healthKitService = HealthKitService()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func syncIfAuthorized() {
        healthKitService.checkAuthorizationStatus { [weak self] granted in
            guard let self = self, granted else { return }
            let enabled = UserDefaults.standard.object(forKey: "healthIntegrationEnabled") as? Bool ?? true
            guard enabled else { return }
            self.syncLatestWeight()
            self.syncActiveEnergy()
        }
    }
    
    private func syncLatestWeight() {
        healthKitService.fetchLatestWeight { [weak self] weight in
            guard let self, let weight else { return }
            do {
                let descriptor = FetchDescriptor<User>()
                if let user = try self.modelContext.fetch(descriptor).first {
                    user.weight = weight
                    try self.modelContext.save()
                }
            } catch {
                // Best effort; avoid surfacing UI from background sync
            }
        }
    }
    
    private func syncActiveEnergy() {
        // Currently not stored; fetching here is a placeholder for future use
        healthKitService.fetchActiveEnergyBurned { _ in }
    }
}


