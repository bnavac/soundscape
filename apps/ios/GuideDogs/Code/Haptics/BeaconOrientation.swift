//
//  BeaconOrientation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

/// A `BeaconOrientation` describes the direction that a beacon is from the user's current position. It is private implementation of an orientable for building beacon feedback.
class BeaconOrientation: Orientable {
    /// The direction of the beacon from the current user.
    var bearing: CLLocationDirection {
        return userLocation.bearing(to: beaconLocation)
    }
    
    /// The beacon's current location.
    private let beaconLocation: CLLocation
    /// The user's current location.
    private var userLocation: CLLocation
    /// Stores a unsubspriction method to the user's current location, to call when de-allocated.
    private var locationCancellable: AnyCancellable?
    
    /// Set up the location observer, and begin calculating the `bearing` of the user.
    init?(_ beacon: CLLocation) {
        guard let loc = AppContext.shared.geolocationManager.location else {
            return nil
        }
        
        userLocation = loc
        beaconLocation = beacon
        
        locationCancellable = NotificationCenter.default.publisher(for: .locationUpdated).sink { [weak self] _ in
            guard let loc = AppContext.shared.geolocationManager.location else {
                return
            }
            
            self?.userLocation = loc
        }
    }
    
    /// Unsubscribe to user location updates.
    deinit {
        locationCancellable?.cancel()
        locationCancellable = nil
    }
}
