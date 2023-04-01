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
        guard let orientation = BeaconOrientation(beaconLocation) else {
            return
        }
        
        phoneIsFlat = DeviceMotionManager.shared.isFlat
        deviceOrientationToken = NotificationCenter.default.publisher(for: .phoneIsFlatChanged).sink { _ in
            self.phoneIsFlat = DeviceMotionManager.shared.isFlat
            
            if self.phoneIsFlat {
                self.playBeaconAudio()
            } else {
                self.stopBeaconAudio()
            }
        }
        
        let target = WandTarget(orientation, window: 60.0)
        let heading = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
        
        wand.start(with: [target], heading: heading)
    }
    
    /// Stop the haptics for this current beacon.
    func stop() {
        deviceOrientationToken?.cancel()
        deviceOrientationToken = nil
        
        // Stop feedback from the wand
        wand.stop()
        
        if let player = beacon {
            AppContext.shared.audioEngine.stop(player)
            beacon = nil
        }
    }
    
    /// An internal function to play the beacon audio.
    private func playBeaconAudio() {
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
        // Set up the ambient audio for the road finder
        let silentDistance = 15.0
        let maxDistance = audioWindow / 2 - silentDistance
        
        PreviewWandAsset.selector = { [weak self] input -> (PreviewWandAsset, PreviewWandAsset.Volume)? in
            if case .heading(let userHeading, _) = input {
                guard let `self` = self, let heading = userHeading else {
                    return (PreviewWandAsset.noTarget, 0.0)
                }
                
                guard self.isBeaconFocussed else {
                    return (PreviewWandAsset.noTarget, 0.0)
                }
                
                let distance = self.wand.angleFromCurrentTarget(heading) ?? 0.0
                let volume = distance < silentDistance ? 1.0 : 1.0 - max(min((distance - silentDistance) / maxDistance, 1.0), 0.0)
                
                return (PreviewWandAsset.noTarget, Float(volume))
            }
            
            return nil
        }
        
        if phoneIsFlat {
            playBeaconAudio()
        }
    }
    
    func wand(_ wand: Wand, didCrossThreshold target: Orientable) {
        guard phoneIsFlat else {
            return
        }
        
        // Always trigger the road haptics
        engine.trigger(for: .impactHeavy)
        engine.prepare(for: .impactHeavy)
    }
    
    func wand(_ wand: Wand, didGainFocus target: Orientable, isInitial: Bool) {
        isBeaconFocussed = true
    }
    
    func wand(_ wand: Wand, didLongFocus target: Orientable) {
        // No-op currently
    }
    
    func wand(_ wand: Wand, didLoseFocus target: Orientable) {
        isBeaconFocussed = false
    }
}
