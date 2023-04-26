//
//  TourWaypointArrivalCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

// Extension of CalloutOrigin enum to define the tourGuidance case
extension CalloutOrigin {
    static let tourGuidance = CalloutOrigin(rawValue: "tour_guidance", localizedString: GDLocalizedString("route_detail.name.default"))!
}

// Definition of the TourWaypointArrivalCallout class that conforms to the CalloutProtocol
class TourWaypointArrivalCallout: CalloutProtocol {
    // Properties of the class
    let id = UUID() // Unique identifier for the callout
    let origin: CalloutOrigin = .routeGuidance // The origin of the callout
    let timestamp = Date() // The timestamp for the callout
    let includeInHistory: Bool = true // A boolean flag to determine if the callout should be included in history
    let index: Int // The index of the waypoint in the tour
    let waypoint: LocationDetail // The waypoint for the callout
    let progress: TourProgress // The progress of the tour
    let previouslyVisited: Bool // A boolean flag to determine if the waypoint has been visited before
    let includePrefixSound = false // A boolean flag to determine if the callout should include a prefix sound

    // Debug description for the callout
    var debugDescription: String {
        return ""
    }

    // Log category for the callout
    var logCategory: String {
        return "waypoint_visited"
    }

    // Prefix sound for the callout
    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }

    // Initializer for the class
    init(index: Int, waypoint: LocationDetail, progress: TourProgress, previouslyVisited: Bool) {
        self.index = index
        self.waypoint = waypoint
        self.progress = progress
        self.previouslyVisited = previouslyVisited
    }

    // Method to get the sounds for the callout based on the location, repeat status, and automotive status
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        // Start with the flag found sound
        var sounds: [Sound] = []

        // If includePrefixSound is true, add a flag found sound at the waypoint location
        if includePrefixSound {
            sounds.append(GlyphSound(.flagFound, at: waypoint.location))
        }

        // Add a beacon found sound
        sounds.append(GlyphSound(.beaconFound))

        // Add a sound about the arrival at the waypoint
        let waypointNearby = GDLocalizedString("behavior.scavenger_hunt.callout.nearby_with_name", waypoint.displayName)
        sounds.append(TTSSound(waypointNearby, at: waypoint.location))

        // If there is an arrival callout for the waypoint, add it to the sounds
        if let arrival = waypoint.arrivalCallout {
            sounds.append(TTSSound(arrival, at: waypoint.location))
        }

        // If the waypoint has already been visited or the tour is complete, return the sounds
        guard !previouslyVisited, progress.isDone else {
            return Sounds(sounds)
        }

        // If this is an adaptive sports event, finish with a little pagentry
        sounds.append(GlyphSound(.huntComplete, at: waypoint.location))

        // Add a congratulations sound for completing the tour
        let congrats = GDLocalizedString("behavior.scavenger_hunt.callout.complete")
        sounds.append(TTSSound(congrats, at: waypoint.location))

        return Sounds(sounds)

    }

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
