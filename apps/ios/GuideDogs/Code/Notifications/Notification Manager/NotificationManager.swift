//
//  NotificationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class NotificationManager {

    // MARK: Properties

    private let observer: NotificationObserver  // The observer object that observes and manages notifications.
    weak var delegate: NotificationManagerDelegate?  // A delegate object that will receive notifications when certain events occur.

    // MARK: Initialization

    init(_ observer: NotificationObserver) {
        self.observer = observer
        self.observer.delegate = self
    }

    // MARK: `NotificationViewController`

    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        // Return the notification view controller if it hasn't been dismissed yet
        guard observer.didDismiss == false else {
            return nil
        }
        return observer.notificationViewController(in: viewController)
    }


}

extension NotificationManager: NotificationObserverDelegate {
    // MARK: NotificationObserverDelegate methods

    func stateDidChange(_ observer: NotificationObserver) {
        // Notify the delegate when the observer's state changes
        delegate?.stateDidChange(self)
    }

    func performSegue(_ observer: NotificationObserver, destination: ViewControllerRepresentable) {
        // Notify the delegate when a segue should be performed
        delegate?.performSegue(self, destination: destination)
    }

    func popToRootViewController(_ observer: NotificationObserver) {
        // Notify the delegate when the observer should pop to the root view controller
        delegate?.popToRootViewController(self)
    }


}
