//
//  StatusGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
// User-initiated event to check the audio
class CheckAudioEvent: UserInitiatedEvent { }

// User-initiated event to preview the TTS voice
class TTSVoicePreviewEvent: UserInitiatedEvent {
    var voiceName: String // name of the TTS voice

    let completionHandler: ((Bool) -> Void)? // completion handler to be called after playing the event

    init(name: String, completionHandler: ((Bool) -> Void)? = nil) {
        self.voiceName = name
        self.completionHandler = completionHandler
    }
}

// User-initiated event to repeat a callout
struct RepeatCalloutEvent: UserInitiatedEvent {
    let callout: CalloutProtocol // callout to repeat
    let completionHandler: ((Bool) -> Void)? // completion handler to be called after playing the event
}

// User-initiated event for generic announcement
class GenericAnnouncementEvent: UserInitiatedEvent {
    let glyph: StaticAudioEngineAsset? // glyph associated with the announcement
    let announcement: String // announcement text

    let completionHandler: ((Bool) -> Void)? // completion handler to be called after playing the event

    let compass: CLLocationDirection? // compass direction associated with the announcement
    let direction: CLLocationDirection? // relative direction associated with the announcement
    let location: CLLocation? // location associated with the announcement

    // Initializer for a private init method
    private init(_ announcement: String,
                 glyph: StaticAudioEngineAsset? = nil,
                 compass: CLLocationDirection?,
                 direction: CLLocationDirection?,
                 location: CLLocation?,
                 completionHandler: ((Bool) -> Void)? = nil) {
        self.glyph = glyph
        self.announcement = announcement
        self.compass = compass
        self.direction = direction
        self.location = location
        self.completionHandler = completionHandler
    }

    // Convenience initializer for an announcement with no location or direction specified
    convenience init(_ announcement: String, glyph: StaticAudioEngineAsset? = nil, completionHandler: ((Bool) -> Void)? = nil) {
        self.init(announcement, glyph: glyph, compass: nil, direction: nil, location: nil, completionHandler: completionHandler)
    }

    // Convenience initializer for an announcement with a compass direction specified
    convenience init(_ announcement: String, glyph: StaticAudioEngineAsset? = nil, compass: CLLocationDirection, completionHandler: ((Bool) -> Void)? = nil) {
        self.init(announcement, glyph: glyph, compass: compass, direction: nil, location: nil, completionHandler: completionHandler)
    }

    // Convenience initializer for an announcement with a relative direction specified
    convenience init(_ announcement: String, glyph: StaticAudioEngineAsset? = nil, direction: CLLocationDirection, completionHandler: ((Bool) -> Void)? = nil) {
        self.init(announcement, glyph: glyph, compass: nil, direction: direction, location: nil, completionHandler: completionHandler)
    }

    // Convenience initializer for an announcement with a location specified
    convenience init(_ announcement: String, glyph: StaticAudioEngineAsset? = nil, location: CLLocation, completionHandler: ((Bool) -> Void)? = nil) {
        self.init(announcement, glyph: glyph, compass: nil, direction: nil, location: location, completionHandler: completionHandler)
    }
}

// Define a SystemGenerator class that implements the ManualGenerator protocol
class SystemGenerator: ManualGenerator {

    // Create an array of event types that this generator can handle
    private var eventTypes: [Event.Type] = [
        CheckAudioEvent.self,
        TTSVoicePreviewEvent.self,
        GenericAnnouncementEvent.self,
        RepeatCalloutEvent.self
    ]

    // Declare two unowned references to external dependencies
    private unowned let geo: GeolocationManagerProtocol
    private unowned let deviceManager: DeviceManagerProtocol

    // Define an initializer that takes two external dependencies and assigns them to the corresponding properties
    init(geo: GeolocationManagerProtocol, device: DeviceManagerProtocol) {
        self.geo = geo
        self.deviceManager = device
    }

    // Implement the respondsTo method of the ManualGenerator protocol
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        // Check if the type of the given event is in the array of event types
        return eventTypes.contains { $0 == type(of: event) }
    }

    // Implement the handle method of the ManualGenerator protocol
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        // Match the given event against various event types to handle them differently
        switch event {

        // If the event is a CheckAudioEvent, handle it
        case is CheckAudioEvent:
            // Create an array to store callouts
            var callouts: [CalloutProtocol] = []

            // Check if there is at least one device available
            guard let device = deviceManager.devices.first else {
                // If not, add a default callout to the array and return it as an action to play callouts
                callouts.append(StringCallout(.arHeadset, GDLocalizedString("devices.callouts.check_audio.default")))
                return .playCallouts(CalloutGroup(callouts, action: .interruptAndClear, logContext: "check_audio"))
            }

            // If there is at least one device, check what type it is
            switch device {

            // If it's a headphone motion manager, check if it's connected
            case let headphoneMotionManager as HeadphoneMotionManagerWrapper:
                if headphoneMotionManager.isConnected {
                    // If connected, add success and AirPods callouts to the array
                    callouts.append(GlyphCallout(.arHeadset, .connectionSuccess))
                    callouts.append(StringCallout(.arHeadset, GDLocalizedString("devices.callouts.check_audio.airpods")))
                } else {
                    // If disconnected, add disconnected AirPods callout to the array
                    callouts.append(StringCallout(.arHeadset, GDLocalizedString("devices.callouts.check_audio.airpods.disconnected")))
                }

            // If it's any other device, add the default callout to the array
            default:
                callouts.append(StringCallout(.arHeadset, GDLocalizedString("devices.callouts.check_audio.default")))
            }

            // Return the array of callouts as an action to play callouts
            return .playCallouts(CalloutGroup(callouts, action: .interruptAndClear, logContext: "check_audio"))

        // If the event is a TTSVoicePreviewEvent, handle it
        case let event as TTSVoicePreviewEvent:
            // Create a callout with a random position and the voice name from the event
            let callout = StringCallout(.system, GDLocalizedString("voice.apple.preview", event.voiceName), position: Double.random(in: 0.0 ..< 360.0))
            let group = CalloutGroup([callout], action: .interruptAndClear, logContext: "tts.preview_voice")
            group.onComplete = event.completionHandler

            return .playCallouts(group)

        case let event as GenericAnnouncementEvent:
            let callout: StringCallout

            if let compass = event.compass {
                callout = StringCallout(.system, event.announcement, glyph: event.glyph, position: compass)
            } else if let direction = event.direction {
                callout = RelativeStringCallout(.system, event.announcement, glyph: event.glyph, position: direction)
            } else if let location = event.location {
                callout = StringCallout(.system, event.announcement, glyph: event.glyph, location: location)
            } else {
                callout = StringCallout(.system, event.announcement, glyph: event.glyph)
            }

            let group = CalloutGroup([callout], action: .interruptAndClear, logContext: "system_announcement")
            group.onComplete = event.completionHandler

            return .playCallouts(group)

        case let event as RepeatCalloutEvent:
            guard let location = geo.location else {
                return nil
            }

            return .playCallouts(CalloutGroup([event.callout], repeatingFromLocation: location, action: .interruptAndClear, logContext: "repeat_callout"))

        default:
            return nil
        }
    }
}
