import Foundation
import WatchKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Haptic Patterns

    func playSuccess() {
        WKInterfaceDevice.current().play(.success)
    }

    func playError() {
        WKInterfaceDevice.current().play(.failure)
    }

    func playLightImpact() {
        WKInterfaceDevice.current().play(.click)
    }

    func playMediumImpact() {
        WKInterfaceDevice.current().play(.directionUp)  // Similar feel to medium impact
    }

    func playHeavyImpact() {
        WKInterfaceDevice.current().play(.retry)  // Stronger vibration
    }

    func playSelection() {
        WKInterfaceDevice.current().play(.click)
    }

    func playStart() {
        WKInterfaceDevice.current().play(.start)
    }

    func playStop() {
        WKInterfaceDevice.current().play(.stop)
    }
}
