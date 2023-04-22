//
//  Heading.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// Protocol that defines properties and a method for notifying
// about heading updates
protocol HeadingNotifier {
    var value: Double? { get } // The current heading value
    var accuracy: Double? { get } // The accuracy of the heading value
    func onHeadingDidUpdate(_ completionHandler: (((_ heading: HeadingValue?) -> Void)?)) // Method to notify about heading updates
}

class Heading: HeadingNotifier {

    // MARK: Properties

    // Default value for the heading if no other value is available
    static let defaultValue: Double = 0.0

    // Possible heading types
    private let types: [HeadingType]

    // Current heading values for each type
    private var course: HeadingValue?
    private var deviceHeading: HeadingValue?
    private var userHeading: HeadingValue?

    // Closure to be called when the heading updates
    private var onHeadingDidUpdate: ((_ heading: HeadingValue?) -> Void)?

    // The current heading value, based on the available heading types
    // Only returns a valid value if at least one heading type is available
    private var heading: (headingValue: HeadingValue, headingType: HeadingType)? {
        for type in types {
            switch type {
            case .user: if let userHeading = userHeading { return (userHeading, .user) } // Use user heading if available
            case .course: if let course = course { return (course, .course) } // Use course heading if available
            case .device: if let deviceHeading = deviceHeading { return (deviceHeading, .device) } // Use device heading if available
            }
        }

        // Heading is invalid if no heading types are available
        return nil
    }

    // The current heading value as a Double, if available
    var value: Double? {
        return heading?.headingValue.value
    }

    // The accuracy of the current heading value, if available
    var accuracy: Double? {
        return heading?.headingValue.accuracy
    }

    // Whether the current heading is a course heading
    var isCourse: Bool {
        guard let type = heading?.headingType else {
            // Heading is invalid if no heading types are available
            // Use `false` as default value
            return false
        }

        switch type {
        case .user: return false
        case .course: return true
        case .device: return false
        }
    }

    // MARK: Initialization

    // Initialize the Heading object with the available heading types and values
    init(orderedBy types: [HeadingType],
         course: HeadingValue?,
         deviceHeading: HeadingValue?,
         userHeading: HeadingValue?,
         geolocationManager: GeolocationManagerProtocol? = nil) {
        self.types = types
        self.course = course
        self.deviceHeading = deviceHeading
        self.userHeading = userHeading

        // Listen for notifications about changes to the heading
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onHeadingTypeDidChange(_:)),
                                               name: Notification.Name.headingTypeDidUpdate,
                                               object: geolocationManager)
    }

    /// Copy constructor
    ///
    /// - Parameter from: Another Heading object to copy configuration information from
    convenience init(from: Heading, geolocationManager: GeolocationManagerProtocol? = nil) {
        self.init(orderedBy: from.types,
                  course: from.course,
                  deviceHeading: from.deviceHeading,
                  userHeading: from.userHeading,
                  geolocationManager: geolocationManager)
    }

    // MARK: Notifications

    // A method that sets the closure to be called whenever the heading value changes
    func onHeadingDidUpdate(_ completionHandler: (((_ heading: HeadingValue?) -> Void)?)) {
        self.onHeadingDidUpdate = completionHandler
    }

    // A method that is called whenever the heading type changes, either from the user, device, or course heading source
    @objc private func onHeadingTypeDidChange(_ notification: Notification) {
        guard let headingType = notification.userInfo?[GeolocationManager.Key.type] as? HeadingType else {
            return
        }

        var headingValue: HeadingValue?

        if let value = notification.userInfo?[GeolocationManager.Key.value] as? Double {
            let accuracy = notification.userInfo?[GeolocationManager.Key.accuracy] as? Double
            headingValue = HeadingValue(value, accuracy)
        }

        // Save old value for calculated `heading`
        let oldValue = self.heading?.headingValue

        switch headingType {
        case .course: course = headingValue
        case .device: deviceHeading = headingValue
        case .user: userHeading = headingValue
        }

        // Calculate new value for `heading`
        let newValue = self.heading?.headingValue

        guard oldValue != newValue else {
            return
        }

        onHeadingDidUpdate?(newValue)
    }

}
