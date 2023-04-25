//
//  GPXTracker.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import iOS_GPX_Framework // import the iOS GPX framework
import CoreMotion.CMMotionActivity // import the CoreMotion activity framework

class GPXTracker {

    // MARK: Properties

    private(set) var isTracking = false // a private property that can be read from outside but only set from within

    // two arrays of GPXLocation objects to store raw and smoothed location data
    private(set) var rawLocations: [GPXLocation] = []
    private(set) var smoothLocations: [GPXLocation] = []

    private let queue = DispatchQueue(label: "com.company.appname.gpxtracker") // a queue to perform the save operation on a separate thread

    // MARK: Tracking state

    // a function to start tracking, sets isTracking to true and resets the location arrays
    func startTracking() {
        reset()

        isTracking = true
    }

    // a function to stop tracking, sets isTracking to false and saves the location data
    func stopTracking() {
        isTracking = false

        save()
    }

    // a function to reset the tracking state, sets isTracking to false and clears the location arrays
    func reset() {
        isTracking = false

        rawLocations.removeAll()
        smoothLocations.removeAll()
    }

    // a function to track a location, adds the location to the raw or smoothed location array depending on the raw parameter
    func track(location: GPXLocation, raw: Bool = true) {
        if raw {
            rawLocations.append(location)
        } else {
            smoothLocations.append(location)
        }
    }

    // MARK: Saving

    // a private function to save the location data to a GPX file, called by stopTracking()
    private func save() {
        // perform the save operation on a separate thread to avoid blocking the UI
        queue.async {
            // save the raw and smoothed location arrays with different filename suffixes
            self.save(locations: self.rawLocations, filenameSuffix: "raw")
            self.save(locations: self.smoothLocations, filenameSuffix: "smooth")

            // reset the location arrays on the main thread
            DispatchQueue.main.async {
                self.reset()
            }
        }
    }

    // a private function to save an array of GPXLocation objects to a GPX file with a given filename suffix
    private func save(locations: [GPXLocation], filenameSuffix suffix: String = "") {
        guard locations.count > 0 else {
            GDLogLocationInfo("No locations tracked. Not saving GPX file.") // log an info message if there are no locations to save
            return
        }

        // use the timestamp of the first location as the filename for the GPX file
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyy-MM-dd HH-mm-ss"

        // create the GPX file with the location data
        let filename = "\(formatter.string(from: locations.first?.location.timestamp ?? Date()))-\(suffix)"
        let root = GPXRoot.createGPX(withTrackLocations: locations)
        if !GPXFileManager.create(content: root.gpx(), filename: filename) {
            GDLogLocationError("Error saving GPX file!") // log an error message if there was an error saving the GPX file
        }
    }

}
