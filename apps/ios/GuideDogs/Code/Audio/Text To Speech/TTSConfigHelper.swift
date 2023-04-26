//
//  TTSConfigHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine

/// TTSConfigHelper is a Swift struct that provides methods for configuring text-to-speech (TTS) voices using
/// Apple's AVFoundation framework. It includes a set of disallowed voices and functions to load available
/// voices, filter them based on language and quality, and select a default voice for a given language.
struct TTSConfigHelper {
    /// These voices are disallowed because they sound robotic not very seamless.
    static let disallowedVoices: Set<String> = [
        "com.apple.speech.synthesis.voice.Fred",
        "com.apple.speech.synthesis.voice.Victoria",
        "com.apple.speech.voice.Alex"
    ]
    
    /// Returns the default TTS voice for a given locale, or the first valid voice in the appropriate language if the default voice is disallowed.
    /// - Parameter locale: The locale for which to get the default TTS voice.
    /// - Returns: An AVSpeechSynthesisVoice object that matches the language code of the locale, or nil if no such voice is available.
    static func defaultVoice(forLocale locale: Locale) -> AVSpeechSynthesisVoice? {
        guard let voice = AVSpeechSynthesisVoice(language: locale.languageCode) else { return nil }
        
        // The default voice per language matches the voice selected in iOS:
        // Settings > Accessibility > Spoken Content > Voices
        // If the default voice matches one of the disallowed voices, we need to make
        // sure we use another voice.
        // This tries to select the first valid voice in the appropriate language.
        // Note: Usually, if an enhanced voice exists for the language, it will be
        // the one selected, as iOS seems to put them first in the voices array.
        guard !disallowedVoices.contains(voice.identifier) else {
            return AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language == locale.identifier }
                .filter { !disallowedVoices.contains($0.identifier) }
                .first
        }
        
        return voice
    }
        
    /// Loads available TTS voices, filters them based on disallowed voices and condensed them by keeping only the enhanced version if both an enhanced and default version exist.
    /// - Parameters:
    ///   - forCurrentLanguage: A Boolean value that indicates whether to return voices for the current language (`true`) or voices for other languages (`false`).
    ///   - currentLocale: The locale of the current user.
    /// - Returns: An array of AVSpeechSynthesisVoice objects that match the specified criteria, sorted first by locale and then by name.
    static func loadVoices(forCurrentLanguage: Bool, currentLocale: Locale) -> [AVSpeechSynthesisVoice] {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices().filter({ !self.disallowedVoices.contains($0.identifier) })
        let enhancedVoiceIdStubs: [String] = availableVoices.compactMap { $0.quality == .enhanced ? $0.identifier.replacingOccurrences(of: "premium", with: "") : nil }
        let currentIdentifier = SettingsContext.shared.voiceId
        
        // Condense the list of voices such that we keep only the enhanced version if both an enhanced and default version exist
        let condensedVoices = availableVoices.filter { (voice) -> Bool in
            // Keep all enhanced quality voices
            guard voice.quality == .default, voice.identifier != currentIdentifier else {
                return true
            }
            
            // Remove any default quality voices which matching enhanced voices
            return !enhancedVoiceIdStubs.contains(voice.identifier.replacingOccurrences(of: "compact", with: ""))
        }
        
        if forCurrentLanguage {
            // Filter our voices in other languages and then sort by locale and then name, but
            // ensure voices for the current locale show up first in the list
            return condensedVoices.filter({ Locale(identifier: $0.language).languageCode == currentLocale.languageCode }).sorted {
                let identifierA = Locale(identifier: $0.language).identifierHyphened
                let identifierB = Locale(identifier: $1.language).identifierHyphened
                let current = currentLocale.identifierHyphened
                
                if identifierA == current && identifierB != current {
                    return true
                } else if identifierA != current && identifierB == current {
                    return false
                } else if identifierA == identifierB {
                    return $0.name < $1.name
                } else {
                    return identifierA < identifierB
                }
            }
        } else {
            // Filter our voices in the current language and then sort by locale and then name, but
            // ensure voices for the current locale show up first in the list
            return condensedVoices.filter({ Locale(identifier: $0.language).languageCode != currentLocale.languageCode }).sorted {
                let identifierA = Locale(identifier: $0.language).identifierHyphened
                let identifierB = Locale(identifier: $1.language).identifierHyphened
                
                if identifierA == identifierB {
                    return $0.name < $1.name
                } else {
                    return identifierA < identifierB
                }
            }
        }
    }
}
