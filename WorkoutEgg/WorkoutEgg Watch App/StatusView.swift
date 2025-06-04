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
                    .font(.custom("VCROSDMono", size: 14))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.18))
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Status Content
            VStack(alignment: .leading, spacing: 12) {
                StatusRow(label: "AGE", value: petData.ageInDays)
                StatusRow(label: "TOTAL", value: petData.totalCaloriesString)
                StatusRow(label: "SPECIES", value: petData.species.displayName)
                StatusRow(label: "STAGE", value: "\(petData.stage.rawValue)")
                StatusRow(label: "EMOTION", value: petData.emotion.displayName)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.12))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.black.opacity(0.08))
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
                .font(.custom("VCROSDMono", size: 12))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.custom("VCROSDMono", size: 12))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ScrollableStatusView: View {
    @Bindable var currentPet: PetData
    let longestLivedPet: LongestLivedPetData?
    
    @State private var showScrollHint: Bool = true
    
    var body: some View {
        ZStack {
            Image("background/bg-field")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Current Pet Status
                    StatusView(petData: currentPet)
                    
                    // Longest Lived Pet Card (compact, like the image)
                    if let longestPet = longestLivedPet {
                        LongestLivedPetCardCompact(petData: longestPet)
                    } else {
                        LongestLivedPetCardCompact(
                            petData: LongestLivedPetData(
                                age: 0,
                                species: .kikimora,
                                stage: .egg,
                                emotion: .content,
                                totalCaloriesConsumed: 0,
                                finalStreak: 0,
                                createdDate: Date(),
                                diedDate: Date(),
                                causeOfDeath: ""
                            )
                        )
                    }
                    
                    // Add some bottom padding for scrolling
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
        }
    }
}

struct LongestLivedPetCardCompact: View {
    let petData: LongestLivedPetData
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            VStack(spacing: 0) {
                HStack {
                    Text("LONGEST\nLIVED")
                        .font(.custom("VCROSDMono", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(petData.ageInDays)
                        .font(.custom("VCROSDMono", size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 2)
                
                if !petData.petImageName.isEmpty {
                    AnimatedLongestLivedPetImage(petData: petData, frameHeight: 80)
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

/// SwiftUI view that displays an animated pet using Timer to cycle through frames
struct AnimatedPetImage: View {
    let petData: PetData
    let frameHeight: CGFloat
    
    @State private var currentFrame = 1
    @State private var animationTimer: Timer?
    
    var body: some View {
        Group {
            if petData.stage == .egg {
                // Static egg image
                Image(petData.petImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: frameHeight)
            } else {
                // Animated pet image
                Image(petData.getPetAnimationFrame(currentFrame))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: frameHeight)
                    .onAppear {
                        startAnimation()
                    }
                    .onDisappear {
                        stopAnimation()
                    }
                    .onChange(of: petData.emotion) { _, _ in
                        // Restart animation when emotion changes
                        stopAnimation()
                        startAnimation()
                    }
                    .onChange(of: petData.stage) { _, _ in
                        // Restart animation when stage changes
                        stopAnimation()
                        startAnimation()
                    }
            }
        }
    }
    
    private func startAnimation() {
        // Only animate non-egg pets
        guard petData.stage != .egg else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentFrame = currentFrame >= 4 ? 1 : currentFrame + 1
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

/// Similar animated view for LongestLivedPetData
struct AnimatedLongestLivedPetImage: View {
    let petData: LongestLivedPetData
    let frameHeight: CGFloat
    
    @State private var currentFrame = 1
    @State private var animationTimer: Timer?
    
    var body: some View {
        Group {
            if petData.stage == .egg {
                // Static egg image
                Image(petData.petImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: frameHeight)
            } else {
                // Animated pet image - use first frame as fallback if animation fails
                let framePath = "Pet/\(petData.species.camelCaseName)\(petData.stage.camelCaseName)\(petData.emotion.camelCaseName)IdleFr\(currentFrame)"
                Image(framePath)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: frameHeight)
                    .onAppear {
                        startAnimation()
                    }
                    .onDisappear {
                        stopAnimation()
                    }
            }
        }
    }
    
    private func startAnimation() {
        // Only animate non-egg pets
        guard petData.stage != .egg else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentFrame = currentFrame >= 4 ? 1 : currentFrame + 1
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
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

