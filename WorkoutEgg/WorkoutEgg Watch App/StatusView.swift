//
//  StatusView.swift
//  WorkoutEgg
//
//  Created by Kenan Firmansyah on 01/06/25.
//

import SwiftUI
import SwiftData

struct StatusView: View {
    @Bindable var petData: PetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title Header
            HStack {
                Spacer()
                Text("STATUS")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Status Content
            VStack(alignment: .leading, spacing: 12) {
                StatusRow(label: "AGE", value: petData.ageInDays)
                StatusRow(label: "TOTAL", value: petData.totalCaloriesString)
                StatusRow(label: "SPECIES", value: petData.species.displayName)
                StatusRow(label: "STAGE", value: "\(petData.stage.rawValue)")
                
                // Emotion with color indicator
                HStack {
                    Text("EMOTION")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .leading)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(petData.emotion.color)
                            .frame(width: 8, height: 8)
                        
                        Text(petData.emotion.displayName)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ScrollableStatusView: View {
    @Bindable var currentPet: PetData
    let longestLivedPet: LongestLivedPetData?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Current Pet Status
                StatusView(petData: currentPet)
                
                // Longest Lived Pet
                if let longestPet = longestLivedPet {
                    LongestLivedPetCard(petData: longestPet)
                }
                
                // Add some bottom padding for scrolling
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
}

struct LongestLivedPetCard: View {
    let petData: LongestLivedPetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title Header
            HStack {
                Spacer()
                Text("LONGEST LIVED")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Pet Content with Image
            VStack(spacing: 16) {
                // Pet Stats
                VStack(alignment: .leading, spacing: 8) {
                    StatusRow(label: "LONGEST", value: petData.ageInDays)
                    StatusRow(label: "LIVED", value: "")
                    StatusRow(label: "SPECIES", value: petData.species.displayName)
                    StatusRow(label: "STAGE", value: "\(petData.stage.rawValue)")
                    StatusRow(label: "TOTAL", value: petData.totalCaloriesString)
                }
                .padding(.horizontal, 16)
                
                // Pet Image
                if !petData.petImageName.isEmpty {
                    Image(petData.petImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Cause of death (optional)
                if !petData.causeOfDeath.isEmpty && petData.causeOfDeath != "unknown" {
                    Text("Cause: \(petData.causeOfDeath.replacingOccurrences(of: "_", with: " ").capitalized)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

