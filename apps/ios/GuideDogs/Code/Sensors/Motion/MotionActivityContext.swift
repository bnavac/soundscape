//
//  MotionActivityContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreMotion

extension Notification.Name {
    static let motionActivityDidChange = Notification.Name("GDAMotionActivityDidChange")
    static let isInMotionDidChange = Notification.Name("GDAIsInMotionDidChange")
}

// MARK: -

/// The principle class for detecting user motion activity.
class MotionActivityContext {

    // MARK: Keys

    private struct UserDefaultKeys {
        static let didToggleCallout = "GDAMotionFitnessDidToggleCallout"
    }

    struct NotificationKeys {
        static let activityType = "GDAActivityType"
        static let isInMotion = "GDAIsInMotion"
    }

    // MARK: - Public Properties

    static var motionFitnessDidToggleCallouts: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultKeys.didToggleCallout)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.didToggleCallout)
        }
    }

    /// While `CMMotionActivity` activities are not mutually exclusive,
    /// Soundscape only uses one current activity type.
    /// This is why we use the `ActivityType` as the public interface for activity state.
    var currentActivity: ActivityType {
        return gpxSimulatedActivity ?? activityType
    }

    /// Use this value to override the current activity
    var gpxSimulatedActivity: ActivityType? {
        didSet {
            if let gpxSimulatedActivity = gpxSimulatedActivity {
                GDLogMotionVerbose("GPX simulated activity changed to: \(gpxSimulatedActivity)")

                stopActivityUpdates()
                handleActivityUpdate(gpxSimulatedActivity, confidence: .high)
                updateMotionState()
            } else {
                GDLogMotionVerbose("GPX simulated activity disabled")

                startActivityUpdates()
            }
        }
    }

    weak var authorizationDelegate: AsyncAuthorizationProviderDelegate?

    // MARK: - Private Properties

    private let motionActivityManager = CMMotionActivityManager()

    private var activityType = ActivityType.unknown {
        didSet {
            guard oldValue != activityType else {
                return
            }

            updateMotionState()

            // UI and Audio updates should be done on main thread
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.motionActivityDidChange,
                                                object: self,
                                                userInfo: [NotificationKeys.activityType: self.activityType])
            }
        }
    }

    /// Indicating whether the device is in motion, i.e. walking, running, cycling or in an automotive
    private(set) var isInMotion: Bool = false

    // MARK: - Actions

    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            GDLogMotionVerbose("Could not start activity updates. Activity estimation is unavailable on the current device.")
            return
        }

        GDLogMotionVerbose("Starting activity updates")

        let operationQueue = OperationQueue()
        operationQueue.name = "MotionActivityContextQueue"

        motionActivityManager.startActivityUpdates(to: operationQueue) { [unowned self] (motionActivity) in
            // Check that we received a valid motion activity
            guard let motionActivity = motionActivity else { return }

            self.handleActivityUpdate(motionActivity)
        }
    }

    func stopActivityUpdates() {
        GDLogMotionVerbose("Stopping activity updates")
        motionActivityManager.stopActivityUpdates()
    }

    private func handleActivityUpdate(_ motionActivity: CMMotionActivity) {
        let activityType = ActivityType(motionActivity: motionActivity)
        handleActivityUpdate(activityType, confidence: motionActivity.confidence)
    }

    private func handleActivityUpdate(_ activityType: ActivityType, confidence: CMMotionActivityConfidence) {
        // Don't process updates if we are simulating a GPX activity
        guard gpxSimulatedActivity == nil else {
            return
        }

        // Don't process updates with low confidence
        guard confidence != .low else {
            return
        }

        // Don't process updates with a similar activity type as the current one
        guard currentActivity != activityType else {
            return
        }

        self.activityType = activityType

        GDLogMotionVerbose("Motion activity changed to: \(activityType) (confidence: \(confidence.description))")
    }

    private func updateMotionState() {
        let isInMotion = currentActivity.isInMotion

        guard isInMotion != self.isInMotion else {
            return
        }

        self.isInMotion = isInMotion

        GDLogMotionVerbose("Motion state changed. Is in motion: \(isInMotion)")

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.isInMotionDidChange,
                                            object: self,
                                            userInfo: [NotificationKeys.isInMotion: isInMotion])
        }
    }

}

// MARK: - MotionActivityProtocol
// Extension of MotionActivityContext that conforms to the MotionActivityProtocol.
// It provides computed properties to determine if the current motion activity is walking or in a vehicle.
extension MotionActivityContext: MotionActivityProtocol {

    var isWalking: Bool {
        return currentActivity == .walking
    }

    var isInVehicle: Bool {
        return currentActivity == .automotive
    }

}

// MARK: - Authorization
// Extension of MotionActivityContext that handles authorization for motion activity updates.
extension MotionActivityContext {

    // Requests motion activity authorization from the user, and calls the given callback with the result.
    class func requestAuthorization(_ callback: ((_ authorized: Bool, _ error: Error?) -> Void)?) {
        // If authorization is already granted, return true.
        if CMMotionActivityManager.authorizationStatus() == .authorized {
            callback?(true, nil)
            return
        }

        // Create a motion activity manager instance to query for authorization.
        let motionActivityManager = CMMotionActivityManager()

        // Query for motion activity authorization.
        motionActivityManager.queryActivityStarting(from: Date(), to: Date(), to: OperationQueue.main) { (_, error) in
            // If there is an error, return false.
            guard error == nil else {
                // If running on a simulator, consider the authorization granted.
                if UIDeviceManager.isSimulator {
                    callback?(true, nil)
                    return
                }

                callback?(false, error)
                return
            }

            // Stop motion activity updates and return true.
            motionActivityManager.stopActivityUpdates()

            callback?(true, nil)
        }
    }
}

// MARK: - AsyncAuthorizationProvider
// Extension of MotionActivityContext that conforms to the AsyncAuthorizationProvider protocol.
// It provides the current authorization status and a method to request authorization.
extension MotionActivityContext: AsyncAuthorizationProvider {

    var authorizationStatus: AuthorizationStatus {
    // Map CMMotionActivityManager.authorizationStatus to AuthorizationStatus enum.
    switch CMMotionActivityManager.authorizationStatus() {
    case .authorized: return .authorized
    case .notDetermined: return .notDetermined
    default: return .denied
    }
}

    // Requests motion activity authorization from the user and notifies the authorization delegate with the result.
    func requestAuthorization() {
        MotionActivityContext.requestAuthorization { [weak self] _, _ in
            guard let `self` = self else {
                return
            }

            self.authorizationDelegate?.authorizationDidChange(self.authorizationStatus)
        }
    }

}

// MARK: - Description
// Extension of CMMotionActivityConfidence enum that provides a description for each confidence level.
// This is used for debugging and logging purposes.
extension CMMotionActivityConfidence: CustomStringConvertible {
    public var description: String {
        switch self {
        case .low:
            return "low"
        case .medium:
            return "medium"
        case .high:
            return "high"
        @unknown default:
            return "unknown - (WARNING) new enum value added"
        }
    }
}
