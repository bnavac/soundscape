//
//  PushAlertObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SafariServices

class PushAlertObserver: NotificationObserver {

    // MARK: Properties

    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
    private var pushNotification: PushNotification?

    // MARK: Initialization

    init() {
        // Register for push notification received notification
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(self.pushNotificationReceived),
                                            name: Notification.Name.pushNotificationReceived,
                                            object: nil)
    }

    // MARK: Notifications

    // Called when a push notification is received
    @objc
    private func pushNotificationReceived(_ notification: Notification) {
        guard let pushNotification = notification.userInfo?[PushNotificationManager.NotificationKeys.pushNotification] as? PushNotification else {
            return
        }

        self.pushNotification = pushNotification

        didDismiss = false

        delegate?.stateDidChange(self)
    }

    // Resets the current push data when the push alert is shown
    private func didShowPush() {
        didDismiss = true
        pushNotification = nil
    }

    // MARK: `NotificationObserver` implementation

    // Returns a view controller to present the push notification
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard let pushNotification = pushNotification else {
            return nil
        }

        // Construct the message to show in the alert
        var message: String? {
            if let subtitle = pushNotification.subtitle, let body = pushNotification.body {
                return subtitle + "\n" + body
            } else if let subtitle = pushNotification.subtitle {
                return subtitle
            } else if let body = pushNotification.body {
                return body
            } else {
                return nil
            }
        }

        // Ensure the notification has text to show
        guard pushNotification.title != nil || message != nil else {
            GDLogPushError("Cannot present push notification in-app alert. Reason: notification does not contain text.")
            return nil
        }

        // Create an alert controller to display the push notification
        let alertController = UIAlertController(title: pushNotification.title,
                                                message: message,
                                                preferredStyle: .alert)

        // Add a dismiss action
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: { [weak self] (_) in
            self?.didShowPush()
        })
        alertController.addAction(dismissAction)

        // If the push notification has a URL, add an action to open it in Safari
        if let urlString = pushNotification.url,
            let url = URL(string: urlString),
            let rootViewController = AppContext.rootViewController {
            let openURLAction = UIAlertAction(title: GDLocalizedString("general.alert.open"), style: .default, handler: { [weak self] (_) in
                self?.didShowPush()

                let safariVC = SFSafariViewController(url: url)
                safariVC.preferredBarTintColor = Colors.Background.primary
                safariVC.preferredControlTintColor = Colors.Foreground.primary
                rootViewController.present(safariVC, animated: true, completion: nil)
            })
            alertController.addAction(openURLAction)
            alertController.preferredAction = openURLAction
        }

        return alertController
    }

}
