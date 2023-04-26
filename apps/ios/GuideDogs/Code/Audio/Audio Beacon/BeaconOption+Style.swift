//
//  BeaconOption+Style.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension BeaconOption {
    
    /// Types of beacon styles.
    enum Style: String {
        case standard
        case haptic
    }
    
    /// Determines whether the beacon is a haptic, or only sound beacon.
    var style: Style {
        switch self {
        case .wand, .pulse: return .haptic
        default: return .standard
        }
    }
    
    /// Returns an array of all the cases of the `BeaconOption` enum type that match the specified style.
    /// - Parameter style: The style to filter by.
    /// - Returns: An array of all the cases of the `BeaconOption` enum type that match the specified style.
    static func allCases(for style: Style) -> [BeaconOption] {
        return BeaconOption.allCases.filter({ return $0.style == style })
    }
    
    // MARK: Availability
    
    /// Returns a Boolean value that indicates whether the specified style is available.
    /// - Parameter style: The style to check.
    /// - Returns: `true` if the specified style is available; otherwise, `false`.
    static func isAvailable(style: Style) -> Bool {
        switch style {
        case .standard: return true
        case .haptic: return HapticEngine.supportsHaptics
        }
    }
    
    /// Returns an array of all the available cases of the `BeaconOption` enum type.
    /// - Returns: An array of all the available cases of the `BeaconOption` enum type.
    static var allAvailableCases: [BeaconOption] {
        return BeaconOption.allCases.filter({ return isAvailable(style: $0.style) })
    }
    
    /// Returns an array of all the available cases of the `BeaconOption` enum type that match the specified style.
    /// - Parameter style: The style to filter by.
    /// - Returns: An array of all the available cases of the `BeaconOption` enum type that match the specified style.
    static func allAvailableCases(for style: Style) -> [BeaconOption] {
        guard isAvailable(style: style) else {
            return []
        }
        
        return BeaconOption.allCases(for: style)
    }
    
}
