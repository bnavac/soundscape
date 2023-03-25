//
//  HapticBeacon.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

/// A protocol specifying a Beacon that emits haptic feedback based on the direction and location of the user.
protocol HapticBeacon: WandDelegate {
    /// Represents the audio player used by the beacon.
    var beacon: AudioPlayerIdentifier? { get }
    
    ///  Initialize the beacon `at` a certain location.
    init(at: CLLocation)
    /// Starts the `HapticBeacon` and begin emitting haptic feedback.
    func start()
    /// Stop the `HapticBeacon` and end emitting haptic feedback.
    func stop()
}
