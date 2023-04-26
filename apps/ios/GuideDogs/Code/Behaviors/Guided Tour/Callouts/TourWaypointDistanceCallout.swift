// TourWaypointDistanceCallout.swift
// Soundscape
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import Foundation
import CoreLocation

class TourWaypointDistanceCallout: CalloutProtocol {
    // MARK: Properties

    let id = UUID()
    let origin: CalloutOrigin = .tourGuidance
    let timestamp = Date()
    let includeInHistory: Bool = false
    let includePrefixSound = true

    let index: Int
    let waypoint: LocationDetail

    var debugDescription: String {
        return ""
    }

    var logCategory: String {
        return "waypoint_distance"
    }

    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }

    // MARK: Initialization

    init(index: Int, waypoint: LocationDetail) {
        self.index = index
        self.waypoint = waypoint
    }

    // MARK: CalloutProtocol methods

    // Returns the distance callout sounds for a given location
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        guard let location = location else {
            return Sounds.empty
        }

        // Calculate the distance between the current location and the waypoint
        let distance = location.distance(from: waypoint.location)

        // Create a layered sound with the POI glyph and the distance TTS sound
        let glyph = GlyphSound(.poiSense, at: waypoint.location)
        let distanceString = LanguageFormatter.formattedDistance(from: distance)
        let tts = TTSSound(GDLocalizedString("waypoint.callout", distanceString), at: waypoint.location)
        guard let layered = LayeredSound(glyph, tts) else {
            return Sounds(tts)
        }

        return Sounds(layered)
    }

    // Returns the distance description for a given location
    func distanceDescription(for location: CLLocation?, tts: Bool) -> String? {
        guard let location = location else {
            return nil
        }

        // Calculate the distance between the current location and the waypoint
        let distance = location.distance(from: waypoint.location)

        if tts {
            return LanguageFormatter.spellOutDistance(distance )
        }

        return LanguageFormatter.string(from: distance)
    }

    // Returns the more info description for this callout
    func moreInfoDescription(for location: CLLocation?) -> String {
        // This callout type doesn't have a matching card, so no more info description is needed
        return ""
    }
}
