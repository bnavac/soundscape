//
//  AlertContainerManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class AlertContainer: NotificationContainer {
    // MARK: Properties

    private var alertController: UIAlertController?

    // MARK: `NotificationContainer`

    // Presents the given view controller as an alert, using the given presenting view controller.
    // If the given view controller is not a `UIAlertController`, the method does nothing.
    // If an alert controller is already presented, the method does nothing.
    // The completion block is called after the alert is presented.
    func present(_ viewController: UIViewController, presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let alertController = viewController as? UIAlertController else {
            completion?()
            return
        }

        guard alertController.presentingViewController == nil else {
            completion?()
            return
        }

        presentingViewController.present(alertController, animated: animated) { [weak self] in
            // Save alert controller
            self?.alertController = alertController

            completion?()
        }
    }

    // Dismisses the currently presented alert, if any.
    // The completion block is called after the alert is dismissed.
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let alertController = alertController else {
            completion?()
            return
        }

        if alertController.presentingViewController == nil {
            // Discard alert controller
            self.alertController = nil

            completion?()
        } else {
            alertController.dismiss(animated: animated) { [weak self] in
                // Discard alert controller
                self?.alertController = nil

                completion?()
            }
        }
    }

}
