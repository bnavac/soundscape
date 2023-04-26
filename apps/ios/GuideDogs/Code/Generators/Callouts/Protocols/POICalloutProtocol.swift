//
//  POICalloutProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

// This is the POICalloutProtocol, which extends the CalloutProtocol and adds properties and methods for POI callouts.
protocol POICalloutProtocol: CalloutProtocol {
    // This is the key property, which is a unique identifier for the POI callout.
    var key: String { get }

    // This is the poi property, which represents the Point of Interest that the callout is associated with.
    var poi: POI? { get }

    // This is the marker property, which represents the reference entity that the callout is associated with.
    var marker: ReferenceEntity? { get }

}

// This is an extension to the POICalloutProtocol, which adds a computed property and a method.
extension POICalloutProtocol {
    // This is the prefixSound computed property, which returns a sound for the POI callout.
    var prefixSound: Sound? {
        guard let poi = poi else {
            return nil
        }

        let category = SuperCategory(rawValue: poi.superCategory) ?? SuperCategory.undefined

        return GlyphSound(category.glyph)
    }

    // This is the distanceDescription method, which returns a description of the distance to the POI callout from a given location.
    // The method takes an optional CLLocation object and a Boolean value that specifies whether the description should be for text-to-speech output.
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        guard let location = location, let distance = poi?.distanceToClosestLocation(from: location) else {
            return nil
        }

        if tts {
            return LanguageFormatter.spellOutDistance(distance)
        }

        return LanguageFormatter.string(from: distance)
    }

}
