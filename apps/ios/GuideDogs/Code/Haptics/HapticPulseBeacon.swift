//
//  HapticPulseBeacon.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

class HapticPulseBeacon: HapticBeacon {
    /// Responsible for rendering haptics for the physical UI at decision points.
    private let engine = HapticEngine()
    
    /// Used to track when the user is pointing their phone at the beacon's location so that corresponding haptics can be triggered appropriately.
    private let wand = PreviewWand()
    
    /// Defines the angular window over which the wand audio plays surrounding the bearing to the beacon.
    private let audioWindow = 60.0
    
    /// Represents the ID for the beacon that plays ambient audio when the wand isn't pointed at a road.
    private(set) var beacon: AudioPlayerIdentifier?
    
    /// Represents the location of the beacon.
    private var beaconLocation: CLLocation
    
    /// Idicates whether the wand is currently focused on the beacon.
    private var isBeaconFocussed = false
    
    /// Represents the heading of the device.
    private var timerHeading: Heading?
    /// Used to cancel the timer.
    private var timerToken: AnyCancellable?
    
    /// Indicates whether the phone is flat or not.
    private var phoneIsFlat: Bool = false
    /// Used to cancel the device orientation token.
    private var deviceOrientationToken: AnyCancellable?
    
    /// Indicates whether to include haptic feedback or not.
    private let includeAHaptics = false
    
    /// Returns a representation of the HapticPulseBeacon class.
    static var description: String {
        return String(describing: self)
    }
    
    /// Initializes a new `HapticPulseBeacon` object with the specified location.
    /// - Parameter at: The CLLocation object that represents the location of the beacon.
    required init(at: CLLocation) {
        beaconLocation = at
        wand.delegate = self
    }
    
    /// Deinitializes the `HapticPulseBeacon` instance.
    ///
    /// Ccancels any ongoing tasks related to it, such as the timer token for heading updates and the device orientation token for monitoring the phone's orientation. Also stops any audio playback by stopping the audio engine's player associated with the beacon, if it exists.
    deinit {
        timerHeading = nil
        
        timerToken?.cancel()
        timerToken = nil
        
        deviceOrientationToken?.cancel()
        deviceOrientationToken = nil
    }
    
    /// Starts the beacon's haptics.
    ///
    /// If the phone is flat, and the user is pointing towards the beacon, every half second the beacon will send a haptic pulse to the user.
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
        
        // Create a target that spans the A+ and A regions but cuts off before B and Behind
        let target = WandTarget(orientation, window: includeAHaptics ? 110.0 : 30.0)
        let heading = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
        
        wand.start(with: [target], heading: heading)
    }
    
    /// Stops the beacon's haptics.
    func stop() {
        // Stop feedback from the wand
        wand.stop()
        
        timerHeading = nil
        timerToken?.cancel()
        timerToken = nil
        
        deviceOrientationToken?.cancel()
        deviceOrientationToken = nil
        
        if let player = beacon {
            AppContext.shared.audioEngine.stop(player)
            beacon = nil
        }
    }
    
    /// If the user's phone becomes flat, send an audio queue to the user.
    private func playBeaconAudio () {
        guard let sound = BeaconSound(PreviewWandAsset.self, at: beaconLocation, isLocalized: false) else {
            return
        }
        
        beacon = AppContext.shared.audioEngine.play(sound, heading: AppContext.shared.geolocationManager.heading(orderedBy: [.device]))
    }
    
    /// If the user's phone is no only flat, stop the audio.
    private func stopBeaconAudio() {
        guard let id = beacon else {
            return
        }
        
        AppContext.shared.audioEngine.stop(id)
    }
    
    /// The function that gets called when the wand starts focusing on a target.
    ///
    /// In this function, the ambient audio for the road finder is set up, based on the user's heading and the location of the beacon. The volume of the audio is calculated based on the distance between the user's current heading and the target location, and is set to 1.0 if the distance is within a certain threshold, and 0.0 otherwise.
    ///
    /// - Parameters:
    ///   - wand: The Wand object that started focusing on a target.
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
    
    /// Notifies the delegate when the specified wand crosses the threshold of the specified orientable target.
    ///
    /// - Parameters:
    ///   - wand: The wand that crossed the threshold.
    ///   - target: The orientable target that the wand crossed.
    func wand(_ wand: Wand, didCrossThreshold target: Orientable) {
        guard phoneIsFlat else {
            return
        }
        
        // Always trigger the road haptics
        engine.trigger(for: .error)
        engine.prepare(for: .error)
    }
    
    /// Notifies the delegate that the specified wand has gained focus on the given target.
    ///
    /// This method is called by the wand object when it gains focus on a new target. The delegate can use this method to perform any necessary setup or configuration for the target. If the `isInitial` parameter is true, this indicates that this is the first time the target has gained focus, so the delegate may need to perform additional initialization.
    ///
    /// - Parameters:
    ///    - wand: The wand that gained focus.
    ///    - target: The Orientable object that the wand has gained focus on.
    ///    - isInitial: A Boolean value indicating whether this is the initial focus event for the target.
    func wand(_ wand: Wand, didGainFocus target: Orientable, isInitial: Bool) {
        isBeaconFocussed = true
        
        timerToken?.cancel()
        timerToken = nil
        
        if includeAHaptics {
            timerHeading = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
            timerToken = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                guard self?.phoneIsFlat ?? false else {
                    return
                }
                
                guard let userHeading: CLLocationDirection = self?.timerHeading?.value else {
                    return
                }
                
                let angle = userHeading.add(degrees: -target.bearing)
                
                if angle >= 345 || angle <= 15 {
                    self?.engine.trigger(for: .impactHeavy)
                    self?.engine.prepare(for: .impactHeavy)
                } else if (angle >= 310 && angle <= 345) || (angle >= 15 && angle <= 50) {
                    self?.engine.trigger(for: .impactLight)
                    self?.engine.prepare(for: .impactLight)
                }
            }
        } else {
            // If we are only using A+ haptics, we don't need to worry about the device's heading
            // since it is already guaranteed to be in the A+ range
            timerToken = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                guard self?.phoneIsFlat ?? false else {
                    return
                }
                
                self?.engine.trigger(for: .impactHeavy)
                self?.engine.prepare(for: .impactHeavy)
            }
        }
    }
    
    func wand(_ wand: Wand, didLongFocus target: Orientable) {
        // No-op currently
    }
    

    /// Informs the delegate that the specified wand has lost focus on the given orientable target.
    ///
    /// Call this method on the delegate object when the specified wand loses focus on the given orientable target. The delegate can use this information to update its state or take other actions as needed.
    /// This method is called by the wand when it loses focus on the target. You should not call this method directly.
    /// - Parameters:
    ///    - wand: The wand that has lost focus.
    ///    - target: The orientable object that the wand was focused on.
    func wand(_ wand: Wand, didLoseFocus target: Orientable) {
        isBeaconFocussed = false
        
        timerHeading = nil
        timerToken?.cancel()
        timerToken = nil
    }
}
