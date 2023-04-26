//
//  TourWaypointDepartureCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class TourWaypointDepartureCallout: CalloutProtocol {
    // Declaring class-level properties
    let id = UUID() // Unique identifier for this callout instance
    let origin: CalloutOrigin = .tourGuidance // Origin of the callout
    let timestamp = Date() // Timestamp for the callout
    let includeInHistory: Bool = false // Indicates if this callout should be included in the callout history
    let includePrefixSound = false // Indicates if a prefix sound should be played with this callout

    let index: Int // Index of the waypoint in the tour
    let waypoint: LocationDetail // LocationDetail object containing information about the waypoint
    let progress: TourProgress // TourProgress object containing progress information for the tour
    let isAutomatic: Bool // Indicates if this callout was automatically triggered

    // Implementing debugDescription computed property from the CustomDebugStringConvertible protocol
    var debugDescription: String {
        return ""
    }

    // Implementing logCategory computed property to specify the category for logging purposes
    var logCategory: String {
        return "waypoint_started"
    }

    // Implementing prefixSound computed property to return the prefix sound for this callout
    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }

    // Initializing class instance with index, waypoint, progress, and isAutomatic parameters
    init(index: Int, waypoint: LocationDetail, progress: TourProgress, isAutomatic: Bool) {
        self.index = index
        self.waypoint = waypoint
        self.progress = progress
        self.isAutomatic = isAutomatic
    }

    // Implementing sounds method to return an array of Sound objects for this callout
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        // Start with the flag found sound
        var sounds: [Sound] = []

        // Check if prefixSound should be included and append it to sounds array if it exists
        if includePrefixSound, let prefixSound = prefixSound {
            sounds.append(prefixSound)
        }

        // Create beaconOn string with distance information
        let beaconOn: String
        if let location = location {
            let distance = location.distance(from: waypoint.location)
            let formattedDistance = LanguageFormatter.string(from: distance, rounded: true)

            beaconOn = GDLocalizedString("behavior.scavenger_hunt.callout.next_flag",
                                        waypoint.displayName,
                                        formattedDistance,
                                        String(index + 1),
                                        String(progress.total))
        } else {
            beaconOn = GDLocalizedString("behavior.scavenger_hunt.callout.next_flag.no_distance",
                                        waypoint.displayName,
                                        String(index + 1),
                                        String(progress.total))
        }

        // Append a TTSSound object with beaconOn string and waypoint location to the sounds array
        sounds.append(TTSSound(beaconOn, at: waypoint.location))

        // Append a TTSSound object with departure information to the sounds array if departure exists for the waypoint
        if let departure = waypoint.departureCallout {
            sounds.append(TTSSound(departure, at: waypoint.location))
        }

        // Return Sounds object with sounds array as input
        return Sounds(sounds)
    }

    // Implementing distanceDescription method to return distance

    func distanceDescription(for location: CLLocation?, tts: Bool) -> String? {
        guard let location = location else {
            return nil
        }

        let distance = location.distance(from: waypoint.location)

        if tts {
            return LanguageFormatter.spellOutDistance(distance)
        }

        return LanguageFormatter.string(from: distance)
    }

    func moreInfoDescription(for location: CLLocation?) -> String {
        // This callout type doesn't have a matching card, so no more info description is needed
        return GDLocalizationUnnecessary("")
    }
}
