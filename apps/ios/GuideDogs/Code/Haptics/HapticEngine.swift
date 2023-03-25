//
//  HapticEngine.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreHaptics


/// ``HapticEngine`` is a helper or wrapper class for creating and triggering haptic feedback on iOS devices using `CoreHaptics` framework. It provides a unified API for creating and managing feedback generators of three different types: ``UIImpactFeedbackGenerator``, ``UISelectionFeedbackGenerator``, and ``UINotificationFeedbackGenerator``.
class HapticEngine {
    /// Contains all loaded `UIFeedbackGenerator`.
    private var generators: [UIFeedbackGenerator] = []
    
    /// ``FeedbackStyle`` is a combined enumeration of the all the types of feedbacks from the main feedback generators.
    enum FeedbackStyle {
        /// The `.heavy` style from ``UIImpactFeedbackGenerator``.
        case impactHeavy
        /// The `.light` style from ``UIImpactFeedbackGenerator``.
        case impactLight
        /// The `.medium` style from ``UIImpactFeedbackGenerator``.
        case impactMedium
        /// The `.rigid` style from ``UIImpactFeedbackGenerator``.
        case impactRigid
        /// The `.soft` style from ``UIImpactFeedbackGenerator``.
        case impactSoft
        
        /// The feedback style from ``UISelectionFeedbackGenerator``.
        case selection
        
        /// The `.error` style from ``UINotificationFeedbackGenerator``.
        case error
        /// The `.success` style from ``UINotificationFeedbackGenerator``.
        case success
        /// The `.warning` style from ``UINotificationFeedbackGenerator``.
        case warning
        
        /// Converts a ``FeedbackStyle`` style to a ``UIImpactFeedbackGenerator`` style.
        /// - Returns: The corresponding ``UIImpactFeedbackGenerator`` style, or ``nil`` if the ``FeedbackStyle`` does not apply.
        func toImpactFeedbackStyle() -> UIImpactFeedbackGenerator.FeedbackStyle? {
            switch self {
            case .impactHeavy: return .heavy
            case .impactLight: return .light
            case .impactMedium: return .medium
            case .impactRigid: return .rigid
            case .impactSoft: return .soft
            default: return nil
            }
        }
        
        /// Converts a ``FeedbackStyle`` style to a ``UINotificationFeedbackGenerator`` style.
        /// - Returns: The corresponding ``UINotificationFeedbackGenerator`` style, or ``nil`` if the ``FeedbackStyle`` does not apply.
        func toNotificationFeedbackType() -> UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .error: return .error
            case .success: return .success
            case .warning: return .warning
            default: return nil
            }
        }
    }
    
    /// Determines whether the device supports haptic playback.
    /// - Returns: `true` if the device supports haptics.
    static var supportsHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    /// Creates a feedback generator for the given style of feedback.
    ///
    /// This adds a new generator to the engine that supports `style` if it is not already supported.
    ///
    /// - Parameter style: The style of feedback to create a generator from.
    func setup(for style: FeedbackStyle) {
        guard !generators.contains(where: { $0.supports(style) }) else {
            return
        }
        
        generators.append(UIFeedbackGenerator.make(supporting: style))
    }
    
    /// Creates feedback generators for all given styles of feedback.
    ///
    /// For each of the `styles`, a new generator is added to the engine if it is not already supported.
    ///
    /// - Parameter styles: An array of the each `FeedbackStyle` to be setup.
    func setup(for styles: [FeedbackStyle]) {
        for style in styles {
            setup(for: style)
        }
    }
    
    /// Removes all feedback generators from the engine and frees their resources.
    func teardownAll() {
        generators.removeAll()
    }
    
    /// Removes all the generators that support `style` and frees their resources.
    /// - Parameter style: The style of feedback generators to remove.
    func teardown(for style: FeedbackStyle) {
        generators.removeAll(where: { $0.supports(style) })
    }
    
    /// Prepares the generator for the given type of feedback. If a generator does not already exist, one will be created and then prepared.
    ///
    /// It is recommended that you prepare a feedback generator before you call it, to minimize latency while the generator is loading.
    ///
    /// - Parameter style: The style of feedback to prepare to be generated.
    func prepare(for style: FeedbackStyle) {
        // Create the generator if it doesn't already exist
        setup(for: style)
        
        generators.first(where: { $0.supports(style) })?.prepare()
    }
    
    /// Triggers the appropriate feedback generator to generate feedback.
    ///
    /// If a generator does not already exist, one will not be created by this function. You should call `setup(for:)` and `prepare(for:)` before you trigger a generator.
    ///
    /// - Parameters:
    ///   - style: Style of feedback to generate.
    ///   - intensity: Optional parameter for impact-type styles. Ignored by all other styles.
    func trigger(for style: FeedbackStyle, intensity: CGFloat? = nil) {
        guard let generator = generators.first(where: { $0.supports(style) }) else {
            return
        }
        
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impactGenerator = generator as? ImpactFeedbackGeneratorWrapper else {
                return
            }
            
            if let intensity = intensity {
                impactGenerator.impactOccurred(intensity: intensity)
            } else {
                impactGenerator.impactOccurred()
            }
            
        case .selection:
            guard let selectionGenerator = generator as? UISelectionFeedbackGenerator else {
                return
            }
            
            selectionGenerator.selectionChanged()
            
        case .error, .success, .warning:
            guard let notificationGenerator = generator as? UINotificationFeedbackGenerator else {
                return
            }
            
            guard let type = style.toNotificationFeedbackType() else {
                return
            }
            
            notificationGenerator.notificationOccurred(type)
        }
    }
}

private class ImpactFeedbackGeneratorWrapper: UIImpactFeedbackGenerator {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    override init(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.style = style
        super.init(style: style)
    }
}

private extension UIFeedbackGenerator {
    func supports(_ style: HapticEngine.FeedbackStyle) -> Bool {
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impact = self as? ImpactFeedbackGeneratorWrapper else {
                return false
            }
            
            return impact.style == style.toImpactFeedbackStyle()
            
        case .selection:
            return self is UISelectionFeedbackGenerator
            
        case .error, .success, .warning:
            return self is UINotificationFeedbackGenerator
        }
    }
    
    static func make(supporting style: HapticEngine.FeedbackStyle) -> UIFeedbackGenerator {
        switch style {
        case .impactHeavy, .impactLight, .impactMedium, .impactRigid, .impactSoft:
            guard let impactStyle = style.toImpactFeedbackStyle() else {
                return ImpactFeedbackGeneratorWrapper(style: .light)
            }
            
            return ImpactFeedbackGeneratorWrapper(style: impactStyle)
            
        case .selection:
            return UISelectionFeedbackGenerator()
            
        case .error, .success, .warning:
            return UINotificationFeedbackGenerator()
        }
    }
}
