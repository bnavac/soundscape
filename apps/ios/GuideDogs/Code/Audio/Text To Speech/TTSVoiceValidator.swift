//
//  TTSVoiceValidator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine

/// `TTSVoiceValidator` is a class used to validate a text-to-speech (TTS) voice.
class TTSVoiceValidator {
    /// The identifier for the TTS voice being validated.
    let identifier: String
    
    /// The cancellable object used to cancel the TTS voice validation.
    private var cancellable: AnyCancellable?
    
    /// Initializes a new `TTSVoiceValidator` instance with the specified TTS voice identifier.
    /// - Parameter voice: The identifier of the TTS voice to validate.
    init(identifier voice: String) {
        self.identifier = voice
    }
    
    /// Validates the TTS voice specified during initialization.
    /// - Returns: A `Future` object that will emit a Boolean value indicating whether the TTS voice is valid or not.
    func validate() -> Future<Bool, Never> {
        return Future { [weak self] promise in
            // Ensure that voice identifier, AVSpeechSynthesisVoice and
            // TTSAudioBufferPublisher objects can be created. If any of the
            // objects cannot be created, immediately resolve the Future with a
            // value of false.
            guard let id = self?.identifier,
                  let voice = AVSpeechSynthesisVoice(identifier: id),
                  let ttsAudioBufferPublisher = TTSAudioBufferPublisher(voice.name, voiceIdentifier: id) else {
                promise(.success(false))
                return
            }
            
            // Subscribe to the TTSAudioBufferPublisher and collect all emitted
            // values. If any errors occur during the subscription, resolve the
            // Future with a value of false. If the subscription completes
            // successfully, resolve the Future with a value of true.
            self?.cancellable = ttsAudioBufferPublisher.collect().sink(receiveCompletion: { [weak self] (result) in
                switch result {
                case .failure: promise(.success(false))
                case .finished: promise(.success(true))
                }
                
                self?.cancellable = nil
            }, receiveValue: { (_) in
                // We don't need to handle it in any way.
            })
        }
    }
}
