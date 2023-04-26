//
//  TTSAudioBufferPublisher.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine

/// An error that can be thrown during text-to-speech synthesis.
enum TTSError: Error, CustomStringConvertible {
    /// The synthesizer was cancelled before finishing.
    case cancelled
    /// The synthesizer failed to render any output. The voice may be broken.
    case failedToRender
    /// Unable to convert synthesizer output to `PCMFloat32`.
    case unableToConvert
    
    /// A string describing the error.
    var description: String {
        switch self {
        case .cancelled: return "Synthesizer cancelled before finishing."
        case .failedToRender: return "Synthesizer failed to render any output. Voice may be broken."
        case .unableToConvert: return "Unable to convert synthesizer output to PCMFloat32."
        }
    }
}

/// A publisher that generates audio buffers for text-to-speech (TTS) synthesizer output.
struct TTSAudioBufferPublisher: Publisher {
    /// The type of elements published by this publisher.
    typealias Output = AVAudioPCMBuffer
    /// The type of error this publisher might publish.
    typealias Failure = TTSError
    
    /// The text to synthesize.
    let text: String
    /// The identifier of the voice to use. If nil, the default voice will be used.
    let voiceId: String?
    
    /// Initializes a new instance of the `TTSAudioBufferPublisher` struct.
    /// - Parameters:
    ///   - text: The text to synthesize.
    ///   - voiceIdentifier: The identifier of the voice to use. If nil, the default voice will be used.
    /// - Returns: A new `TTSAudioBufferPublisher` instance, or nil if no voice identifier is found.
    init?(_ text: String, voiceIdentifier: String? = nil) {
        guard let voiceId = voiceIdentifier ??
                SettingsContext.shared.voiceId ??
                TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier else {
            return nil
        }
        
        self.voiceId = voiceId
        self.text = text
    }

    /// Attaches a subscriber to this publisher to receive audio buffers.
    /// - Parameters:
    ///   - subscriber: The subscriber to attach to this publisher.
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = TTSSubscription(subscriber: subscriber, text: text, voiceIdentifier: voiceId)
        subscriber.receive(subscription: subscription)
    }
}

private extension TTSAudioBufferPublisher {
    /// A subscription to a `TTSAudioBufferPublisher`.
    final class TTSSubscription<S: Subscriber>: NSObject, AVSpeechSynthesizerDelegate, Subscription where Output == S.Input, Failure == S.Failure {
        /// The subscriber attached to this subscription.
        private var subscriber: S? {
            didSet {
                if subscriber == nil {
                    synth?.delegate = nil
                    synth = nil
                }
            }
        }
        
        /// The AVSpeechSynthesizer used for speech synthesis.
        private var synth: AVSpeechSynthesizer?
        /// The AVSpeechUtterance representing the text to be synthesized.
        private let utterance: AVSpeechUtterance
        /// The audio buffers produced by the synthesizer.
        private var buffers: [AVAudioPCMBuffer] = []
        /// A lock used to synchronize access to the buffer array.
        private var lock: NSRecursiveLock = .init()
        
        /// The current demand for audio buffers from the subscriber.
        private var requested: Subscribers.Demand = .none
        /// The number of audio buffers processed by the subscriber.
        private var processed: Subscribers.Demand = .none
        
        /// The completion status of the subscription.
        private var completion: Subscribers.Completion<S.Failure>?
        
        /// The identifier of the voice to be used for synthesis.
        private let voiceId: String?
        /// The AVSpeechSynthesisVoice to be used for synthesis.
        private var voice: AVSpeechSynthesisVoice? {
            guard let id = voiceId else {
                return nil
            }
            
            return AVSpeechSynthesisVoice(identifier: id)
        }
        
        /// Initializes a new instance of `TTSSubscription`.
        /// - Parameters:
        ///   - subscriber: The subscriber to attach to this subscription.
        ///   - text: The text to be synthesized.
        ///   - voiceIdentifier: The identifier of the voice to be used for synthesis.
        init(subscriber: S, text: String, voiceIdentifier: String? = nil) {
            self.voiceId = voiceIdentifier
            
            /// Format the text for tts.
            var formatted = LanguageFormatter.expandCodedDirection(for: text)
            formatted = PostalAbbreviations.format(formatted, locale: LocalizationContext.currentAppLocale)
            formatted = formatted.replacingOccurrences(of: "_", with: " ")
            
            /// Initialize parameters.
            self.subscriber = subscriber
            self.utterance = AVSpeechUtterance(string: formatted)
            super.init()
            
            /// Configure the utterance.
            utterance.rate = SettingsContext.shared.speakingRate
            utterance.voice = voice
            
            synth = AVSpeechSynthesizer()
            synth?.delegate = self
            synth?.write(utterance) { [weak self] buffer in
                self?.receiveBuffer(buffer)
            }
        }
        
        // MARK: Subscription
        
        /// Requests a given number of audio buffers from the publisher.
        /// - Parameter demand: The number of audio buffers requested.
        func request(_ demand: Subscribers.Demand) {
            flush(demand)
        }
        
        // MARK: Cancellable
        
        /// Cancels the subscription.
        func cancel() {
            synth?.stopSpeaking(at: .immediate)
            buffers.removeAll()
            subscriber = nil
        }
        
        // MARK: AVSpeechSynthesizer
        
        /// Receives an audio buffer from the synthesizer and converts it to the appropriate format.
        /// - Parameter buffer: The audio buffer received from the synthesizer.
        private func receiveBuffer(_ buffer: AVAudioBuffer) {
            lock.lock()
            
            defer {
                lock.unlock()
                flush()
            }
            
            /// The buffer should be a PCM buffer and there should be some data in it.
            guard let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 else {
                return
            }
            
            /// Get ready to convert the buffer to PCMFloat32 from PCMInt16:
            ///   1. Keep the audio in the same layout except move to the PCMFloat32 common format.
            ///   2. Create an audio converter from PCMInt16 to PCMFloat32.
            ///   3. Create a new buffer with the appropriate format.
            guard let floatFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcm.format.sampleRate, channels: pcm.format.channelCount, interleaved: pcm.format.isInterleaved),
                let converter = AVAudioConverter(from: pcm.format, to: floatFormat),
                let convertedBuffer = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: pcm.frameLength) else {
                completion = .failure(.unableToConvert)
                return
            }

            convertedBuffer.frameLength = pcm.frameLength

            /// Convert the Apple TTS from PCMInt16 to PCMFloat32.
            do {
                try converter.convert(to: convertedBuffer, from: pcm)
            } catch {
                GDLogAudioError("Unable to convert TTS data: \(error.localizedDescription)")
                completion = .failure(.unableToConvert)
                return
            }

            /// Save the converted buffer.
            buffers.append(convertedBuffer)
        }
        
        /// Flushes the audio buffers to the subscriber.
        /// - Parameters:
        ///   - adding: The additional demand requested by the subscriber.
        private func flush(_ adding: Subscribers.Demand = .none) {
            lock.lock()
            
            defer {
                lock.unlock()
            }
            
            guard let subscriber = subscriber else {
                buffers.removeAll()
                return
            }
            
            /// Add the new demand request to the current request.
            requested += adding
            
            /// Send as many audio buffers as we can.
            while !buffers.isEmpty, processed < requested {
                requested += subscriber.receive(buffers.remove(at: 0))
                processed += 1
            }
            
            /// If we have finished (we are out of buffers and the synth is done), then send the completion.
            if buffers.isEmpty, let completion = completion {
                subscriber.receive(completion: completion)
                self.subscriber = nil
            }
        }
        
        /// This function is called when the synthesizer finishes speaking the utterance.
        /// - Parameters:
        ///   - synthesizer: The synthesizer that spoke the utterance.
        ///   - utterance: The utterance that was spoken.
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            completion = processed > 0 ? .finished : .failure(.failedToRender)
            flush()
        }

        /// This function is called when the synthesizer cancels speaking the utterance.
        /// - Parameters:
        ///   - synthesizer: The synthesizer that spoke the utterance.
        ///   - utterance: The utterance that was spoken.
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            completion = processed > 0 ? .failure(.cancelled) : .failure(.failedToRender)
            flush()
        }
        
    }
}
