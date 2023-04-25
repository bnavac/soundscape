//
//  OfflineBannerObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class OfflineBannerObserver: PersistentNotificationObserver {

    // MARK: Properties

    weak var delegate: NotificationObserverDelegate? // A delegate for this observer
    private var offlineState: OfflineState // The current offline state

    // MARK: Initialization

    init() {
        self.offlineState = AppContext.shared.offlineContext.state // Initialize the offline state from the shared app context

        NotificationCenter.default.addObserver(self, selector: #selector(self.onOfflineStateDidChange), name: Notification.Name.offlineStateDidChange, object: nil) // Register for notifications when the offline state changes
    }

    // MARK: Notifications

    @objc
    private func onOfflineStateDidChange(_ notification: Notification) {
        guard let offlineState = notification.userInfo?[OfflineContext.Keys.state] as? OfflineState else {
            return
        }

        self.offlineState = offlineState // Update the offline state

        delegate?.stateDidChange(self) // Notify the delegate of the state change
    }

    // MARK: `NotificationManager`

    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard offlineState != .online else { // If the app is online, return nil
            return nil
        }

        var notificationViewController: BannerViewController?

        if offlineState == .offline {
            notificationViewController = OfflineBannerViewController(in: viewController) // If the app is offline, show the OfflineBannerViewController
        }

        if offlineState == .enteringOnline {
            notificationViewController = BannerViewController(nibName: "OnlineBanner") // If the app is entering online mode, show the OnlineBannerViewController
        }

        // Initialize delegate
        notificationViewController?.delegate = self // Set this object as the delegate for the notification view controller

        return notificationViewController
    }

}

extension OfflineBannerObserver: BannerViewControllerDelegate {

    func didSelect(_ bannerViewController: BannerViewController) {
        guard let offlineBannerViewController = bannerViewController as? OfflineBannerViewController else {
            return
        }

        guard let segue = offlineBannerViewController.segue else {
            return
        }

        delegate?.performSegue(self, destination: segue) // Notify the delegate that a segue should be performed
    }

    func didDismiss(_ bannerViewController: BannerViewController) {
        // no-op
    }

}
