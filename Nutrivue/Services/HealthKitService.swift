import Foundation
import HealthKit

class HealthKitService {
    
    let healthStore = HKHealthStore()
    
    private var defaultReadTypes: Set<HKObjectType> {
        return [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.nutrivue.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"]))
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: defaultReadTypes) { success, error in
            completion(success, error)
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        let writeTypes = Set<HKSampleType>()
        healthStore.getRequestStatusForAuthorization(toShare: writeTypes, read: defaultReadTypes) { status, _ in
            // If request is unnecessary, we have already asked in the past (granted or denied).
            // We optimistically assume granted and verify by attempting reads when needed.
            completion(status == .unnecessary)
        }
    }
    
    func fetchLatestWeight(completion: @escaping (Double?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            completion(weightInKg)
        }
        
        healthStore.execute(query)
    }
    
    func fetchActiveEnergyBurned(completion: @escaping (Double?) -> Void) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else {
                completion(nil)
                return
            }
            let totalCalories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(totalCalories)
        }
        
        healthStore.execute(query)
    }
}
