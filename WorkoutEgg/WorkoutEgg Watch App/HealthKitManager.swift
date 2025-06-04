import Foundation
import HealthKit
import WatchKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var caloriesBurned: Double = 0
    @Published var cumulativeCalories: Double = 0
    private var updateTimer: Timer?
    private var petData: PetData?
    
    // Add completion callback for when data is loaded
    var onDataLoaded: (() -> Void)?
    
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
        // Update every 5 minutes while the app is active
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchTodayCalories()
        }
    }
    
    func requestAuthorization() {
        // Define the types of data we want to read
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            DebugConfig.debugPrint("❌ HealthKit: Failed to create activeEnergyBurned type")
            return
        }
        
        DebugConfig.debugPrint("🏥 HealthKit: Requesting authorization...")
        
        // Request authorization
        healthStore.requestAuthorization(toShare: [], read: [activeEnergyType]) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    DebugConfig.debugPrint("❌ HealthKit Authorization Error: \(error.localizedDescription)")
                    return
                }
                
                if success {
                    DebugConfig.debugPrint("✅ HealthKit: Authorization granted")
                    self.fetchTodayCalories()
                    self.setupBackgroundDelivery(for: activeEnergyType)
                } else {
                    DebugConfig.debugPrint("❌ HealthKit: Authorization denied")
                }
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
            DebugConfig.debugPrint("❌ HealthKit: Failed to get activeEnergyBurned type")
            return
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: activeEnergyType)
        DebugConfig.debugPrint("🔐 HealthKit Authorization Status: \(authStatus.rawValue)")
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        DebugConfig.debugPrint("📅 HealthKit Query: \(startOfDay) to \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                DebugConfig.debugPrint("❌ HealthKit Query Error: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                DebugConfig.debugPrint("⚠️ HealthKit: No data or nil result")
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            DebugConfig.debugPrint("✅ HealthKit: Fetched \(calories) calories for today")
            
            DispatchQueue.main.async {
                self.caloriesBurned = calories
                self.updateCumulativeCalories()
                DebugConfig.debugPrint("📱 HealthKit: Updated caloriesBurned to \(self.caloriesBurned)")
                self.onDataLoaded?()
            }
        }
        
        healthStore.execute(query)
    }
    
    // New method to fetch calories for multiple days (for egg stage)
    func fetchCaloriesSinceDate(_ startDate: Date) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            DebugConfig.debugPrint("❌ HealthKit: Failed to get activeEnergyBurned type for cumulative query")
            return
        }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        DebugConfig.debugPrint("📅 HealthKit Cumulative Query: \(startDate) to \(now)")
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                DebugConfig.debugPrint("❌ HealthKit Cumulative Query Error: \(error.localizedDescription)")
                
                // Fallback: If cumulative query fails, use today's calories for egg stage
                DispatchQueue.main.async {
                    DebugConfig.debugPrint("🔄 Fallback: Using today's calories (\(self.caloriesBurned)) for egg cumulative")
                    self.cumulativeCalories = self.caloriesBurned
                    self.petData?.updateCumulativeCalories(todayCalories: self.caloriesBurned, cumulativeCalories: self.caloriesBurned)
                    self.onDataLoaded?()
                }
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                DebugConfig.debugPrint("⚠️ HealthKit Cumulative: No data or nil result")
                
                // Fallback: If no cumulative data available, use today's calories
                DispatchQueue.main.async {
                    DebugConfig.debugPrint("🔄 Fallback: No cumulative data, using today's calories (\(self.caloriesBurned))")
                    self.cumulativeCalories = self.caloriesBurned
                    self.petData?.updateCumulativeCalories(todayCalories: self.caloriesBurned, cumulativeCalories: self.caloriesBurned)
                    self.onDataLoaded?()
                }
                return
            }
            
            let cumulativeCalories = sum.doubleValue(for: HKUnit.kilocalorie())
            DebugConfig.debugPrint("✅ HealthKit: Fetched \(cumulativeCalories) cumulative calories since \(startDate)")
            
            DispatchQueue.main.async {
                self.cumulativeCalories = cumulativeCalories
                DebugConfig.debugPrint("📱 HealthKit: Updated cumulativeCalories to \(self.cumulativeCalories)")
                
                // Update the pet data with both values
                self.petData?.updateCumulativeCalories(todayCalories: self.caloriesBurned, cumulativeCalories: cumulativeCalories)
                self.onDataLoaded?()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updateCumulativeCalories() {
        guard let petData = self.petData else { 
            DebugConfig.debugPrint("⚠️ HealthKitManager: No petData reference")
            return 
        }
        
        DebugConfig.debugPrint("🔄 HealthKitManager updating calories:")
        DebugConfig.debugPrint("   - Pet stage: \(petData.stage.displayName)")
        DebugConfig.debugPrint("   - Pet age: \(petData.age)")
        DebugConfig.debugPrint("   - caloriesBurned: \(caloriesBurned)")
        
        if petData.stage == .egg {
            // For egg stage, fetch calories since the pet became an egg
            let eggStartDate = getEggStartDate(petData: petData)
            DebugConfig.debugPrint("   - Using egg mode, fetching since: \(eggStartDate)")
            fetchCaloriesSinceDate(eggStartDate)
        } else {
            // For other stages, use only today's calories
            DebugConfig.debugPrint("   - Using non-egg mode, setting cumulative = burned")
            cumulativeCalories = caloriesBurned
            
            // Update the pet data with today's calories only
            petData.updateCumulativeCalories(todayCalories: caloriesBurned)
        }
        
        DebugConfig.debugPrint("   - HealthKitManager cumulativeCalories: \(cumulativeCalories)")
    }
    
    private func getEggStartDate(petData: PetData) -> Date {
        // Use the pet's actual creation date as the start date for cumulative calories
        // This is more accurate than trying to calculate from age
        let eggStartDate = petData.createdDate
        
        DebugConfig.debugPrint("🥚 Egg start date calculation:")
        DebugConfig.debugPrint("   - Pet created: \(eggStartDate)")
        DebugConfig.debugPrint("   - Pet age: \(petData.age)")
        DebugConfig.debugPrint("   - Current date: \(Date())")
        
        // Ensure we don't query future dates
        let now = Date()
        if eggStartDate > now {
            DebugConfig.debugPrint("   - WARNING: Creation date is in future, using current date")
            return now
        }
        
        return eggStartDate
    }
}
