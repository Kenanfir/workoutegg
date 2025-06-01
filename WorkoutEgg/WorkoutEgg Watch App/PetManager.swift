//
//  PetManager.swift
//  WorkoutEgg
//
//  Created by Kenan Firmansyah on 01/06/25.
//

import SwiftUI
import SwiftData

class PetManager: ObservableObject {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func getCurrentPet() -> PetData {
        let request = FetchDescriptor<PetData>(
            predicate: #Predicate { $0.isActive && !$0.isDead }
        )
        
        if let pet = try? context.fetch(request).first {
            return pet
        } else {
            // Create new pet
            return createNewPet()
        }
    }
    
    func getLongestLivedPet() -> LongestLivedPetData? {
        let request = FetchDescriptor<LongestLivedPetData>(
            sortBy: [SortDescriptor(\.age, order: .reverse)]
        )
        
        return try? context.fetch(request).first
    }
    
    func createNewPet(species: PetSpecies = .fufufafa) -> PetData {
        // Deactivate any existing active pets
        let activeRequest = FetchDescriptor<PetData>(
            predicate: #Predicate { $0.isActive }
        )
        
        if let activePets = try? context.fetch(activeRequest) {
            for pet in activePets {
                pet.isActive = false
            }
        }
        
        // Create new pet
        let newPet = PetData(species: species)
        context.insert(newPet)
        
        try? context.save()
        return newPet
    }
    
    func killCurrentPet(causeOfDeath: String) {
        let currentPet = getCurrentPet()
        
        // Save to longest lived if this pet lived longer than current record
        let currentLongest = getLongestLivedPet()
        if currentLongest == nil || currentPet.age > (currentLongest?.age ?? 0) {
            // Remove old longest lived record if exists
            if let oldLongest = currentLongest {
                context.delete(oldLongest)
            }
            
            // Create new longest lived record
            let longestLived = LongestLivedPetData(from: currentPet, causeOfDeath: causeOfDeath)
            context.insert(longestLived)
        }
        
        // Mark current pet as dead and inactive
        currentPet.isDead = true
        currentPet.isActive = false
        
        try? context.save()
    }
    
    func checkPetHealth() {
        let currentPet = getCurrentPet()
        
        // Check if pet died from neglect
        if currentPet.checkMissedFed() {
            killCurrentPet(causeOfDeath: "neglected")
            return
        }
        
        // Check if pet died from old age
        if currentPet.checkOldAge() {
            killCurrentPet(causeOfDeath: "old_age")
            return
        }
    }
}
