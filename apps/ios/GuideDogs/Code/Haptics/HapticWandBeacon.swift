//
//  HapticWandBeacon.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

class HapticWandBeacon: HapticBeacon {
    
    /// Haptic engine for rendering haptics for the physical UI at decision points.
    private let engine = HapticEngine()
    
    /// Wand for tracking when the user is pointing their phone at the beacon's location so that corresponding haptics can be triggered appropriately.
    private let wand = PreviewWand()
    
    /// Angular window over which the wand audio plays surrounding the bearing to the beacon.
    private let audioWindow = 60.0
    
    /// Identifier for the beacon that plays ambient audio when the wand isn't pointed at a road.
    private(set) var beacon: AudioPlayerIdentifier?
    
    /// The location of this beacon.
    private var beaconLocation: CLLocation
    
    /// Whether the beacon is focused. An unfocused beacon does not produce sound.
    private var isBeaconFocussed = false
    
    /// If the phone is flat, beacon audio is played.
    private var phoneIsFlat: Bool = false
    
    /// A subscription to the orientation of the iPhone.
    private var deviceOrientationToken: AnyCancellable?
    
    static var description: String {
        return String(describing: self)
    }
    
    /// Set the location of the beacon.
    required init(at: CLLocation) {
        beaconLocation = at
        wand.delegate = self
    }
    
    /// Remove the subscription to the iPhone orientation when object is de-allocated.
    deinit {
        deviceOrientationToken?.cancel()
        deviceOrientationToken = nil
    }
    
    /// Start up the haptics for this particular beacon.
    func start() {
        
        /// Determine the orientation of the beacon
        guard let orientation = BeaconOrientation(beaconLocation) else {
            return
        }
        
        /// Get the flatness of the device
        phoneIsFlat = DeviceMotionManager.shared.isFlat
        
        /// Subscribe to changes in the flatness of the device
        deviceOrientationToken = NotificationCenter.default.publisher(for: .phoneIsFlatChanged).sink { _ in
            
            /// Update the flatness of the device
            self.phoneIsFlat = DeviceMotionManager.shared.isFlat
            
            /// Play or stop the beacon audio based on whether the phone is flat or not
            if self.phoneIsFlat {
                self.playBeaconAudio()
            } else {
                self.stopBeaconAudio()
            }
        }
        
        /// Create a wand target and start the wand
        let target = WandTarget(orientation, window: 60.0)
        let heading = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
        wand.start(with: [target], heading: heading)
    }
    
    /// Stop the haptics for this current beacon.
    func stop() {
        /// Cancel the subscription to changes in the flatness of the device
        deviceOrientationToken?.cancel()
        deviceOrientationToken = nil
        
        /// Stop feedback from the wand
        wand.stop()
        
        /// Stop playing the beacon audio
        if let player = beacon {
            AppContext.shared.audioEngine.stop(player)
            beacon = nil
        }
    }
    
    /// An internal function to play the beacon audio.
    private func playBeaconAudio() {
        
        /// Get the sound to play at the beacon location
        guard let sound = BeaconSound(PreviewWandAsset.self, at: beaconLocation, isLocalized: false) else {
            return
        }
        
        beacon = AppContext.shared.audioEngine.play(sound, heading: AppContext.shared.geolocationManager.heading(orderedBy: [.device]))
    }
    
    /// An internal function to stop the beacon audio.
    private func stopBeaconAudio() {
        guard let id = beacon else {
            return
        }
        
        AppContext.shared.audioEngine.stop(id)
    }
    
    func wandDidStart(_ wand: Wand) {
        /// Set up the ambient audio for the road finder.
        
        /// Distance at which the audio becomes silent.
        let silentDistance = 15.0
        /// Max distance for which audio can be heard.
        let maxDistance = audioWindow / 2 - silentDistance

        PreviewWandAsset.selector = { [weak self] input -> (PreviewWandAsset, PreviewWandAsset.Volume)? in
            /// This block sets the ambient audio based on the user's heading and distance from target.
            if case .heading(let userHeading, _) = input {
                guard let `self` = self, let heading = userHeading else {
                    /// If self is nil or the heading is nil, return no audio and zero volume.
                    return (PreviewWandAsset.noTarget, 0.0)
                }

                guard self.isBeaconFocussed else {
                    /// If the wand is not focused on a target, return no audio and zero volume.
                    return (PreviewWandAsset.noTarget, 0.0)
                }

                /// Calculate the distance from target.
                let distance = self.wand.angleFromCurrentTarget(heading) ?? 0.0
                /// Calculate the volume based on the distance.
                let volume = distance < silentDistance ? 1.0 : 1.0 - max(min((distance - silentDistance) / maxDistance, 1.0), 0.0)
                /// Return the audio and volume to play.
                return (PreviewWandAsset.noTarget, Float(volume))
            }
            /// Return nil if the input is not of type "heading".
            return nil
        }

        if phoneIsFlat {
            /// Play the audio when phone is flat.
            playBeaconAudio()
        }
    }

    func wand(_ wand: Wand, didCrossThreshold target: Orientable) {
        guard phoneIsFlat else {
            /// Do nothing if the phone is not flat.
            return
        }

        /// Always trigger the road haptics.
        engine.trigger(for: .impactHeavy)
        engine.prepare(for: .impactHeavy)
    }

    func wand(_ wand: Wand, didGainFocus target: Orientable, isInitial: Bool) {
        /// Set the "isBeaconFocussed" flag to true when the wand gains focus on the target.
        isBeaconFocussed = true
    }

    func wand(_ wand: Wand, didLongFocus target: Orientable) {
        /// No-op currently (no operation).
    }

    func wand(_ wand: Wand, didLoseFocus target: Orientable) {
        /// Set the "isBeaconFocussed" flag to false when the wand loses focus on the target.
        isBeaconFocussed = false
    }
}
