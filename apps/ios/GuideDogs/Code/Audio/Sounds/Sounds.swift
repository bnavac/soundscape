//
//  Sounds.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// A closure that takes a notification and returns an array of sounds
typealias AsyncSoundsNotificationHandler = (_ notification: Notification) -> [Sound]

class Sounds {

    // MARK: Properties

    // Returns an empty instance of the `Sounds` class
    static var empty: Sounds {
        return Sounds()
    }

    // A lock to ensure thread safety when accessing the `soundArray` property
    private let lock = NSLock()
    // An array of `Sound` instances
    private(set) var soundArray: [Sound]
    // A closure that will be executed when a notification is received
    private var onNotificationHandler: AsyncSoundsNotificationHandler?
    // A name for the notification to be observed
    private var notificationName: Notification.Name?
    // An object to be passed to the notification observer
    private var notificationObject: Any?

    // A Boolean value indicating whether the `soundArray` is empty or not
    var isEmpty: Bool {
        return soundArray.isEmpty
    }

    // MARK: Initialization

    // Initializes a `Sounds` instance with an array of `Sound` instances
    init(_ sounds: [Sound] = []) {
        self.soundArray = sounds
    }

    // Convenience initializer that takes a single `Sound` instance
    convenience init(_ sound: Sound) {
        self.init([sound])
    }

    // Convenience initializer that takes an array of `Sound` instances, a notification handler, a notification name and a notification object
    convenience init(soundArray: [Sound], onNotificationHandler: AsyncSoundsNotificationHandler?, notificationName: Notification.Name?, notificationObject: Any?) {
        self.init(soundArray)

        self.onNotificationHandler = onNotificationHandler
        self.notificationName = notificationName
        self.notificationObject = notificationObject

        // If `notificationName` is not `nil`, add an observer for the notification
        guard let notificationName = self.notificationName else {
            return
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onAsyncSoundsCompleted),
                                               name: notificationName,
                                               object: notificationObject)
    }

    // MARK: Iterate through array

    // Removes and returns the first sound from the `soundArray`, if not empty
    func next() -> Sound? {
        lock.lock()

        defer {
            lock.unlock()
        }

        guard soundArray.count > 0 else {
            return nil
        }

        // Try to get next sound
        return soundArray.removeFirst()
    }

    // MARK: Notifications

    // A selector function that will be called when a notification is received
    @objc private func onAsyncSoundsCompleted(_ notification: Notification) {
        lock.lock()

        defer {
            lock.unlock()
        }

        guard let soundArray = onNotificationHandler?(notification) else {
            return
        }

        // Append the array of sounds received from the notification to the `soundArray`
        self.soundArray.append(contentsOf: soundArray)
    }

}
