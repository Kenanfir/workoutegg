//
//  DebugConfig.swift
//  WorkoutEgg
//
//  Created by AI Assistant on Debug Configuration
//

import Foundation

/// Global debug configuration for the WorkoutEgg app
/// Set this to `true` to enable debug outputs, `false` to disable them
struct DebugConfig {
    
    /// Master debug flag - controls all debug outputs in the app
    /// Set to `false` for production builds
    static let isDebugMode: Bool = false
    
    /// Conditional debug print function
    /// Only prints if debug mode is enabled
    static func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if isDebugMode {
            print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
        }
    }
    
    /// Check if visual debug elements should be shown
    static var shouldShowVisualDebugElements: Bool {
        return isDebugMode
    }
    
    /// Check if UI debug overlays should be shown (like Evolve Pet button)
    static var shouldShowDebugUI: Bool {
        return isDebugMode
    }
    
    /// Check if tap indicators should be shown
    static var shouldShowTapIndicators: Bool {
        return isDebugMode
    }
    
    /// Check if hit area visualization should be shown
    static var shouldShowHitArea: Bool {
        return isDebugMode
    }
} 