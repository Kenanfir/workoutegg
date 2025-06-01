import Foundation
import HealthKit
import WatchKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var caloriesBurned: Double = 0
    @Published var cumulativeCalories: Double = 0
    private var updateTimer: Timer?
    private var petData: PetData?
    
    init() {
        requestAuthorization()
        setupPeriodicUpdates()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // Set the pet data reference
    func setPetData(_ petData: PetData) {
        self.petData = petData
        // Update cumulative calories when pet data is set
        updateCumulativeCalories()
    }
    
    private func setupPeriodicUpdates() {
        // Update every 5 seconds while the app is active
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchTodayCalories()
        }
    }
    
    func requestAuthorization() {
        // Define the types of data we want to read
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        // Request authorization
        healthStore.requestAuthorization(toShare: [], read: [activeEnergyType]) { success, error in
            if success {
                self.fetchTodayCalories()
                self.setupBackgroundDelivery(for: activeEnergyType)
            }
        }
    }
    
    func setupBackgroundDelivery(for type: HKQuantityType) {
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if success {
                // Set up the observer query
                self.setupObserverQuery(for: type)
            }
        }
    }
    
    func setupObserverQuery(for type: HKQuantityType) {
        // Create the observer query
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                // Fetch the latest data when we receive a background update
                self?.fetchTodayCalories()
            }
            // Always call the completion handler
            completionHandler()
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    func fetchTodayCalories() {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                self.caloriesBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                self.updateCumulativeCalories()
            }
        }
        
        healthStore.execute(query)
    }
    
    // New method to fetch calories for multiple days (for egg stage)
    func fetchCaloriesSinceDate(_ startDate: Date) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                self.cumulativeCalories = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updateCumulativeCalories() {
        guard let petData = self.petData else { return }
        
        if petData.stage == .egg {
            // For egg stage, fetch calories since the pet became an egg
            let eggStartDate = getEggStartDate(petData: petData)
            fetchCaloriesSinceDate(eggStartDate)
        } else {
            // For other stages, use only today's calories
            cumulativeCalories = caloriesBurned
        }
        
        // Update the pet data
        petData.updateCumulativeCalories(todayCalories: caloriesBurned)
    }
    
    private func getEggStartDate(petData: PetData) -> Date {
        // Calculate when the pet became an egg based on age
        let calendar = Calendar.current
        let daysAsEgg = petData.age // Assuming age represents days as egg
        return calendar.date(byAdding: .day, value: -daysAsEgg, to: Date()) ?? Date()
    }
}
