//
//  TourDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

// Define the TourDetail class that conforms to the RouteDetailProtocol
class TourDetail: RouteDetailProtocol {

    // MARK: Properties

    // Store the event associated with the tour
    let event: AuthoredActivityContent

    // Store the name, description, and waypoints of the tour
    private(set) var name: String?
    private(set) var description: String?
    private(set) var waypoints: [LocationDetail] = []
    private(set) var pois: [LocationDetail] = []

    // Store a list of cancellable listeners
    private var listeners: [AnyCancellable] = []

    // Get the current guided tour if there is one
    var guidance: GuidedTour? {
        guard let guide = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour else {
            return nil
        }

        guard guide.content.id == id else {
            return nil
        }

        return guide
    }

    // Check if a guided tour is active
    var isGuidanceActive: Bool {
        return guidance != nil
    }

    // Get the ID of the tour
    var id: String {
        return event.id
    }

    // Get the display name of the tour
    var displayName: String {
        if let name = name, name.isEmpty == false {
            return name
        }

        return GDLocalizedString("route_detail.name.default")
    }

    // MARK: Initialization

    // Initialize the TourDetail object with the given AuthoredActivityContent
    init(content: AuthoredActivityContent) {
        self.event = content

        // Initialize route properties
        setRouteProperties()
    }

    // Remove all cancellable listeners when the object is deallocated
    deinit {
        listeners.cancelAndRemoveAll()
    }

    // MARK: Route Properties

    // Set the name, description, and waypoints of the tour
    private func setRouteProperties() {
        name = event.name
        description = event.desc
        waypoints = event.waypoints.map { wpt -> LocationDetail in
            let detail = ImportedLocationDetail(nickname: wpt.name,
                                                annotation: wpt.description,
                                                departure: wpt.departureCallout,
                                                arrival: wpt.arrivalCallout,
                                                images: wpt.images,
                                                audio: wpt.audioClips)

            return LocationDetail(location: CLLocation(wpt.coordinate),
                                  imported: detail,
                                  telemetryContext: "tour_detail")
        }
    }

}
