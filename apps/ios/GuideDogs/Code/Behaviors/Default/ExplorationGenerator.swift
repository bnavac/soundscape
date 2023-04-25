//
//  ExplorationGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct ExplorationModeToggled: UserInitiatedEvent {
    let sender: AnyObject?
    let mode: ExplorationGenerator.Mode
    let requiredMarkerKeys: [String]
    let completionHandler: ((Bool) -> Void)?
    let logContext: String
    
    /// Initializes the event
    /// - Parameters:
    ///   - mode: Mode that is being toggled
    ///   - requiredMarkerKeys: An array of markers that must be included in the
    ///       callouts when `mode == .nearbyMarkers`. Ignored by all other modes.
    ///   - logContext: Context string to include in logs
    ///   - completion: Completion block to execute when the callouts generated by
    ///       this mode are finished playing after having toggled a mode on
    init(_ mode: ExplorationGenerator.Mode, sender: AnyObject? = nil, requiredMarkerKeys: [String] = [], logContext: String? = nil, completion: ((Bool) -> Void)? = nil) {
        self.mode = mode
        self.sender = sender
        self.requiredMarkerKeys = requiredMarkerKeys
        self.completionHandler = completion
        
        if let context = logContext {
            self.logContext = "exploration.\(mode).\(context)"
        } else {
            self.logContext = "exploration.\(mode)"
        }
    }
}

class ExplorationGenerator: ManualGenerator, AutomaticGenerator {
    
    enum Mode: String {
        case locate
        case aroundMe
        case aheadOfMe
        case nearbyMarkers
        
        var origin: CalloutOrigin {
            switch self {
            case .locate: return .locate
            case .aroundMe: return .orient
            case .aheadOfMe: return .explore
            case .nearbyMarkers: return .nearbyMarkers
            }
        }
        
        var noCalloutsMessage: String {
            switch self {
            case .locate:
                return GDLocalizedString("general.error.location_services_find_location_error")
            case .aroundMe, .aheadOfMe:
                return GDLocalizedString("callouts.nothing_to_call_out_now")
            case .nearbyMarkers:
                return GDLocalizedString("callouts.no_nearby_markers_to_call_out_now")
            }
        }
    }
    
    private var eventTypes: [Event.Type] = [
        ExplorationModeToggled.self,
        RegisterPrioritizedPOIs.self,
        RemoveRegisteredPOIs.self
    ]
    
    private unowned let data: SpatialDataProtocol
    private unowned let geo: GeolocationManagerProtocol
    private unowned let geocoder: ReverseGeocoder
    private unowned let motionActivity: MotionActivityProtocol
    private unowned let deviceMotion: DeviceMotionProvider
    
    private var prioritizedPOIs: [POI] = []
    private let maxAheadOfMeCallouts = 5
    private let maxNearbyMarkerCallouts = 4
    private var currentGroupId: UUID?
    private var currentMode: Mode?
    
    var canInterrupt: Bool = true
    
    private var spatialDataType: SpatialDataProtocol.Type {
        return type(of: data)
    }
    
    private var noLocationMessage: String {
        //This error will run if Apple's geocoding fails (ie, if the phone does not have it's own location).
        return GDLocalizedString("general.error.location_services_find_location_error")
    }
    
    init(data: SpatialDataProtocol, geocoder: ReverseGeocoder, geo: GeolocationManagerProtocol, motionActivity: MotionActivityProtocol, deviceMotion: DeviceMotionProvider) {
        self.data = data
        self.geo = geo
        self.geocoder = geocoder
        self.motionActivity = motionActivity
        self.deviceMotion = deviceMotion
    }
    
    func respondsTo(_ event: StateChangedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as RegisterPrioritizedPOIs:
            prioritizedPOIs = event.pois
            return .noAction
            
        case is RemoveRegisteredPOIs:
            prioritizedPOIs.removeAll()
            return .noAction
            
        default:
            return nil
        }
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        guard let event = event as? ExplorationModeToggled else {
            return nil
        }
        
        guard event.mode != currentMode else {
            event.completionHandler?(false)
            
            // By interrupting and clearing the queue, we will terminate the callouts for the current
            // mode. This state will be updated `calloutsCompleted(for:finished:)` below
            log(event, toggledOn: false)
            return .interruptAndClearQueue
        }
        
        if let errorMessage = locationServicesErrorMessage() {
            event.completionHandler?(false)
            let error = RelativeStringCallout(event.mode.origin, errorMessage, position: 0.0)
            return .playCallouts(CalloutGroup([error], action: .interruptAndClear, logContext: event.logContext))
        }
        
        guard let loc = geo.location else {
            event.completionHandler?(false)
            let error = RelativeStringCallout(event.mode.origin, noLocationMessage, position: 0.0)
            return .playCallouts(CalloutGroup([error], action: .interruptAndClear, logContext: event.logContext))
        }
        
        log(event, toggledOn: true)
        
        // Get the appropriate callouts
        var callouts: [CalloutProtocol]
        switch event.mode {
        case .locate:
            if let dataView = data.getDataView(for: loc, searchDistance: SpatialDataContext.initialPOISearchDistance) {
                GDLogGeocoderInfo("Reverse Geocode - from Locate command (\(loc.description))")
                let result = geocoder.reverseGeocode(loc, data: dataView, heading: geo.collectionHeading)
                callouts = [result.buildCallout(origin: .auto, sound: false, useClosestRoadIfAvailable: false)]
            } else {
                callouts = []
            }
            
            if event.sender is UserActivityManager {
                NSUserActivity(userAction: .myLocation).becomeCurrent()
            }
            
        case .aroundMe:
            let heading = geo.collectionHeading.value ?? Heading.defaultValue
            callouts = findCalloutsFor(location: loc, heading: heading, origin: event.mode.origin)
            
            if event.sender is UserActivityManager {
                NSUserActivity(userAction: .aroundMe).becomeCurrent()
            }
            
        case .aheadOfMe:
            let heading = geo.heading(orderedBy: [.user, .device, .course]).value ?? Heading.defaultValue
            let direction = SpatialDataView.getHeadingDirection(heading: heading)
            callouts = findCalloutsFor(direction, maxItems: maxAheadOfMeCallouts, location: loc, heading: heading, origin: event.mode.origin)
            
            if event.sender is UserActivityManager {
                NSUserActivity(userAction: .aheadOfMe).becomeCurrent()
            }
            
        case .nearbyMarkers:
            callouts = getCalloutsForMarkers(location: loc, requiredMarkerKeys: event.requiredMarkerKeys)

            if event.sender is UserActivityManager {
                NSUserActivity(userAction: .nearbyMarkers).becomeCurrent()
            }
        }
        
        if callouts.isEmpty {
            callouts.append(RelativeStringCallout(event.mode.origin, event.mode.noCalloutsMessage, position: 0.0))
        }
        
        let group = CalloutGroup(callouts, action: .interruptAndClear, playModeSounds: true, logContext: event.logContext)
        group.delegate = self
        group.onComplete = event.completionHandler
        
        currentGroupId = group.id
        currentMode = event.mode
        
        return .playCallouts(group)
    }
    
    private func locationServicesErrorMessage() -> String? {
        guard geo.isActive else {
            return GDLocalizedString("general.error.location_services_resume")
        }
        
        guard geo.coreLocationServicesEnabled else {
            return GDLocalizedString("general.error.location_services")
        }
        
        guard geo.coreLocationAuthorizationStatus == .fullAccuracyLocationAuthorized else {
            return GDLocalizedString("general.error.precise_location")
        }
        
        return nil
    }
    
    /// Helper function that gets the results of `getCalloutsFor(quadrants:maxItemsPerQuadrant:location:heading:)`
    /// for a single quadrant and unwraps them to only return the array of callouts instead
    /// of the dictionary of arrays.
    ///
    /// - Parameters:
    ///   - quadrant: Quadrant to get results for
    ///   - maxItems: Max number of callouts to return
    ///   - location: The user's current location
    ///   - heading: The user's current heading
    /// - Returns: An array of callouts
    private func findCalloutsFor(_ quadrant: CompassDirection,
                                 maxItems max: Int,
                                 location loc: CLLocation,
                                 heading head: CLLocationDirection,
                                 origin: CalloutOrigin) -> [CalloutProtocol] {
        
        return findCalloutsFor([quadrant],
                              maxItemsPerQuadrant: max,
                              location: loc,
                              heading: head,
                              origin: origin)
    }
    
    /// Gets the
    /// - Parameters:
    ///   - quadrants: Quadrants to gather callout for
    ///   - maxItemsPerQuadrant: Maximum number of callouts to return for each quadrant
    ///   - location: The user's current location
    ///   - heading: The user's current heading
    /// - Returns: A dictionary of arrays of callouts
    private func findCalloutsFor(_ quadrants: [CompassDirection] = [.north, .east, .south, .west],
                                 maxItemsPerQuadrant max: Int = 1,
                                 location loc: CLLocation,
                                 heading: CLLocationDirection,
                                 origin: CalloutOrigin) -> [CalloutProtocol] {
        let poiCategories = [SuperCategory.places, SuperCategory.landmarks, SuperCategory.authoredActivity]
        var poisByQuad: [CompassDirection: [POI]] = [:]
        var range = spatialDataType.initialPOISearchDistance
        
        // Quadrant cases:
        //   1. SpatialDataContext is providing a nil data view: quadrants is empty
        //   2. Enough POIs exist in all quadrants to satisfy the request: the while loop
        //      will hit the break and quadrants will have a full list of POIs for each quadrant
        //   3. Not all quadrants have enough POIs: the while loop condition will be satisfied
        //      at the max distance and quadrants will have four partially full lists
        while range <= spatialDataType.cacheDistance {
            defer {
                range += spatialDataType.expansionPOISearchDistance
            }
            
            // Get the spatial data view and filter POIs into quadrants
            guard let view = data.getDataView(for: loc, searchDistance: range)?.pois else {
                continue
            }
            
            poisByQuad = view.quadrants(quadrants,
                                        location: loc,
                                        heading: heading,
                                        categories: poiCategories,
                                        maxLengthPerQuadrant: max)
            
            if prioritizedPOIs.count > 0 {
                let prioritizedPOIsByQuad = prioritizedPOIs.quadrants(quadrants,
                                                                      location: loc,
                                                                      heading: heading,
                                                                      categories: poiCategories,
                                                                      maxLengthPerQuadrant: max)
                
                poisByQuad.merge(prioritizedPOIsByQuad) { defaultPOIs, prioritizedPOIs in
                    return prioritizedPOIs + defaultPOIs
                }
            }
            
            // If any quadrant isn't full, expand the search radius and continue
            if !quadrants.allSatisfy({ poisByQuad[$0, default: []].count >= max }) {
                continue
            }
            
            break
        }
        
        // All requested quadrants should have been returned (even if some are empty), otherwise
        // we are in an error state (e.g. no location data).
        guard poisByQuad.count == quadrants.count else {
            return []
        }
        
        return poisByQuad.flatMap { $0.value.map { POICallout(origin, key: $0.key, includeDistance: true) }}
    }
    
    private func getCalloutsForMarkers(location: CLLocation, requiredMarkerKeys: [String]) -> [CalloutProtocol] {
        var markers: [ReferenceEntity] = []
        var range = spatialDataType.initialPOISearchDistance
        while range <= spatialDataType.cacheDistance {
            defer {
                range += spatialDataType.expansionPOISearchDistance
            }
            
            // Get the spatial data view and filter POIs into quadrants
            guard let dataView = data.getCurrentDataView(searchDistance: range) else {
                continue
            }
            
            markers = dataView.markedPoints.sort(maxItems: maxNearbyMarkerCallouts, location: location)
            
            // If we don't have at least 4 markers, expand the search radius and try again
            guard markers.count >= maxNearbyMarkerCallouts else {
                continue
            }
            
            break
        }
        
        // Append the entities for `entityKeysToInclude`
        if !requiredMarkerKeys.isEmpty {
            // Filter out existing markers
            let filtered = requiredMarkerKeys.filter { (key) -> Bool in
                // Check if `markers` contain the reference entity with the same key
                return !markers.contains { $0.entityKey == key }
            }
            
            // Transform entity keys to entity objects
            markers.append(contentsOf: filtered.compactMap { SpatialDataCache.referenceEntityByEntityKey($0) })
        }
        
        return markers.map { POICallout(.nearbyMarkers, key: $0.getPOI().key, includeDistance: true) }
    }
    
    private func log(_ event: ExplorationModeToggled, toggledOn: Bool) {
        var locationString = "none"
            
        if let location = geo.location {
            locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude) +/- \(location.horizontalAccuracy)m"
        }
        
        GDLogInfo(.autoCallout, "Toggled \(event.mode) \(toggledOn ? "on" : "off") (location: \(locationString))")
        
        var properties: [String: String] = ["context": event.logContext, "start": String(toggledOn)]
        
        // No need to log all details for command 'end' event (start = `false`)
        guard toggledOn else {
            GDATelemetry.track("command.\(event.mode.rawValue)", with: properties)
            return
        }
        
        properties["is_flat"] = String(deviceMotion.isFlat)
        properties["has_heading"] = String(geo.collectionHeading.value != nil)
        properties["activity"] = motionActivity.currentActivity.rawValue
        
        GDATelemetry.track("command.\(event.mode.rawValue)", with: properties)
    }
    
    func cancelCalloutsForEntity(id: String) {
        // No-op
    }
}

extension ExplorationGenerator: CalloutGroupDelegate {
    func isCalloutWithinRegionToLive(_ callout: CalloutProtocol) -> Bool {
        return true
    }
    
    func calloutSkipped(_ callout: CalloutProtocol) {
        // No-op
    }
    
    func calloutStarting(_ callout: CalloutProtocol) {
        // No-op
    }
    
    func calloutFinished(_ callout: CalloutProtocol, completed: Bool) {
        // No-op
    }
    
    func calloutsSkipped(for group: CalloutGroup) {
        calloutsCompleted(for: group, finished: false)
    }
    
    func calloutsStarted(for group: CalloutGroup) {
        // No-op
    }
    
    func calloutsCompleted(for group: CalloutGroup, finished: Bool) {
        // Modes are mutually exclusive, so if the current mode has finished, then set the mode back to nil
        if group.id == currentGroupId {
            currentGroupId = nil
            currentMode = nil
        }
    }
}
