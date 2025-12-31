import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Page 1: Welcome & Concept
            VStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .padding(.bottom, 10)

                Text("Welcome to\nWorkoutEgg")
                    .multilineTextAlignment(.center)
                    .font(.headline)

                Text("Your new gym buddy!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)

                Spacer()

                Text("Burn active calories in real life to grow your pet.")
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .padding()
            }
            .tag(0)

            // Page 2: Feeding
            VStack {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .padding(.bottom, 10)

                Text("Feed Your Pet")
                    .font(.headline)

                Spacer()

                Text("Use your burned calories to feed your pet and keep them alive!")
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .padding()

                Text("Don't neglect them!")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.red)
            }
            .tag(1)

            // Page 3: Evolution & Start
            VStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .padding(.bottom, 10)

                Text("Evolve & Grow")
                    .font(.headline)

                Spacer()

                Text("Watch your egg hatch and evolve into unique creatures.")
                    .multilineTextAlignment(.center)
                    .font(.caption2)
                    .padding()

                Button(action: {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                    HapticManager.shared.playSuccess()
                }) {
                    Text("Get Started")
                }
                .background(Color.blue)
                .cornerRadius(20)
                .padding()
            }
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
