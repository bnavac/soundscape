//
//  CloudKeyValueStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Notification.Name {
    static let cloudKeyValueStoreDidChange = Notification.Name("GDACloudKeyValueStoreDidChange")
}

enum CloudKeyValueStoreChangeReason: Int, CustomStringConvertible {
    
    /// Initial downloads happen the first time a device is connected to an iCloud account, and when a user switches their primary iCloud account.
    case initialSync = 0
    /// Value(s) were changed externally from other users/devices.
    case serverChanged = 1
    /// The user has changed the primary iCloud account.
    case accountChanged = 2
    /// The app's key-value store has exceeded its space quota on the iCloud server.
    case quotaViolationChange = 3
    
    var description: String {
        switch self {
        case .initialSync:
            return "initial_sync"
        case .serverChanged:
            return "server_changed"
        case .accountChanged:
            return "account_changed"
        case .quotaViolationChange:
            return "quota_violation_change"
        }
    }
    
}

/// Acts as a facade to the iCloud Key-Value Store (NSUbiquitousKeyValueStore)
class CloudKeyValueStore {
    
    // MARK: Keys

    struct NotificationKeys {
        static let reason = "GDAReasonKey"
        static let changedKeys = "GDAChangedKeysKey"
    }
    
    // MARK: Properties
    //A NSU...Store is a way to store use preferences in the user's icloud account
    //allowing for preferences to be saved and transfered across devices,
    //likely as an array of key-value pairs
    var keyValueStore: NSUbiquitousKeyValueStore?
    //A set of strings which is just every key in the NSUKV stored as a dictionary
    var allKeys: Set<String> {
        guard let keyValueStore = keyValueStore else { return [] }
        return Set(keyValueStore.dictionaryRepresentation.keys)
    }
    
    var pendingRouteErrorNotifications: [RouteParameters] = []
    
    // MARK: Actions

    func start() {
        keyValueStore = NSUbiquitousKeyValueStore.default
        //Adds an observer to monitor if the app is active
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: NSNotification.Name.appDidBecomeActive,
                                               object: nil)
        //Adds an observer to monitor if the user has completed onboarding
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: .onboardingDidComplete,
                                               object: nil)
        //Adds an observer to monitor
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(storeDidChange),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: keyValueStore)
        //Another observer to monitor if the user has completed onboarding
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onboardingDidComplete),
                                               name: .onboardingDidComplete,
                                               object: nil)
        
        synchronize()
    }
    
    func synchronize() {
        guard let keyValueStore = keyValueStore else {
            GDLogCloudInfo("KV store not initialized. Call `start()` before calling this method.")
            return
        }
        
        let synchronized = keyValueStore.synchronize()
        GDLogCloudInfo("KV store \(synchronized ? "synchronized" : "failed to synchronize")")
    }
    
    // MARK: Getting Values
    ///Returns the value associated with a key
    func object(forKey key: String) -> Any? {
        return keyValueStore?.object(forKey: key) ?? nil
    }
    
    // MARK: Setting Values
    ///Sets the value at a key to the object param
    func set(object: Any?, forKey key: String) {
        guard let keyValueStore = keyValueStore else {
            GDLogCloudInfo("KV store not initialized. Call `start()` before calling this method.")
            return
        }
        
        keyValueStore.set(object, forKey: key)
        GDLogCloudInfo("KV store added object with key: \(key)")
        
        synchronize()
    }
    ///TODO: Figure out what this does
    func set(dictionary: [String: Any], forKey key: String) {
        set(object: dictionary, forKey: key)
    }
    
    // MARK: Removing Values
    
    func removeAllObjects() {
        for key in allKeys {
            removeObject(forKey: key)
        }
    }
    
    func removeObject(forKey key: String) {
        guard let keyValueStore = keyValueStore else {
            GDLogCloudInfo("KV store not initialized. Call `start()` before calling this method.")
            return
        }
        
        keyValueStore.removeObject(forKey: key)
        GDLogCloudInfo("KV store removed object with key: \(key)")
        
        synchronize()
    }
}

// MARK: Handeling store change notifications

extension CloudKeyValueStore {
    
    @objc func storeDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            GDLogCloudInfo("KV store did change externally notification error: Does not contain user info")
            return
        }
        
        guard let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            GDLogCloudInfo("KV store did change externally notification error: Does not contain change reason")
            return
        }
        
        var reason: CloudKeyValueStoreChangeReason

        switch changeReason {
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            GDLogCloudInfo("KV store did change externally notification - reason: Initial Sync")
            reason = CloudKeyValueStoreChangeReason.initialSync
        case NSUbiquitousKeyValueStoreServerChange:
            GDLogCloudInfo("KV store did change externally notification - reason: Server Change")
            reason = CloudKeyValueStoreChangeReason.serverChanged
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // From Apple: The total amount of space available in your app’s key-value store, for a given user, is 1 MB.
            // There is a per-key value size limit of 1 MB, and a maximum of 1024 keys.
            // If you attempt to write data that exceeds these quotas, the write attempt fails and no change
            // is made to your iCloud key-value storage. In this scenario, the system posts the
            // didChangeExternallyNotification notification with a change reason of NSUbiquitousKeyValueStoreQuotaViolationChange.
            GDLogCloudInfo("KV store did change externally notification - reason: Quota Violation")
            reason = CloudKeyValueStoreChangeReason.quotaViolationChange
        case NSUbiquitousKeyValueStoreAccountChange:
            GDLogCloudInfo("KV store did change externally notification - reason: Account Change")
            reason = CloudKeyValueStoreChangeReason.accountChanged
        default:
            GDLogCloudInfo("KV store did change externally notification - reason: Unknown")
            return
        }
        
        var forwardNotificationUserInfo: [String: Any] = [NotificationKeys.reason: reason]
        
        if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
            GDLogCloudInfo("KV store did change externally notification - changed keys: \(changedKeys)")
            
            forwardNotificationUserInfo[NotificationKeys.changedKeys] = changedKeys
        }
        
        NotificationCenter.default.post(name: .cloudKeyValueStoreDidChange,
                                        object: self,
                                        userInfo: forwardNotificationUserInfo)
        
        GDATelemetry.track("cloud_sync.store_did_change", value: reason.description)
    }
    
    @objc private func appDidBecomeActive(_ notification: Notification) {
        synchronize()
    }
    
    @objc private func onboardingDidComplete() {
        guard pendingRouteErrorNotifications.isEmpty == false else {
            return
        }
        
        notifyOfInvalidRoutesIfNeeded(routeParametersObjects: pendingRouteErrorNotifications)
        pendingRouteErrorNotifications.removeAll()
    }
}
