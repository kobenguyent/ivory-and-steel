import XCTest
import AVFoundation
@testable import IvoryAndSteel

final class AudioEngineTests: XCTestCase {
    
    // MARK: - Frequency & Frame Math Tests
    
    func testMidiToFrequencyMath() {
        // A4 = MIDI 69 = 440.0 Hz
        let a4 = DSPMath.midiToFrequency(midi: 69)
        XCTAssertEqual(a4, 440.0, accuracy: 0.001)
        
        // A3 = MIDI 57 = 220.0 Hz
        let a3 = DSPMath.midiToFrequency(midi: 57)
        XCTAssertEqual(a3, 220.0, accuracy: 0.001)
        
        // C4 (Middle C) = MIDI 60 ≈ 261.6256 Hz
        let c4 = DSPMath.midiToFrequency(midi: 60)
        XCTAssertEqual(c4, 261.6256, accuracy: 0.01)
        
        // A0 = MIDI 21 = 27.5 Hz
        let a0 = DSPMath.midiToFrequency(midi: 21)
        XCTAssertEqual(a0, 27.5, accuracy: 0.001)
        
        // C8 = MIDI 108 ≈ 4186.01 Hz
        let c8 = DSPMath.midiToFrequency(midi: 108)
        XCTAssertEqual(c8, 4186.01, accuracy: 0.1)
    }
    
    func testSampleFrameCountAccuracy() {
        let sampleRate: Double = 44100.0
        
        // 1.0 second = exactly 44100 frames
        XCTAssertEqual(DSPMath.sampleFrameCount(duration: 1.0, sampleRate: sampleRate), 44100)
        
        // 0.5 seconds = exactly 22050 frames
        XCTAssertEqual(DSPMath.sampleFrameCount(duration: 0.5, sampleRate: sampleRate), 22050)
        
        // 12ms click = exactly round(0.012 * 44100) = 529 frames
        XCTAssertEqual(DSPMath.sampleFrameCount(duration: 0.012, sampleRate: sampleRate), 529)
        
        // 48 kHz sample rate check
        XCTAssertEqual(DSPMath.sampleFrameCount(duration: 0.012, sampleRate: 48000.0), 576)
    }
    
    // MARK: - Envelope Non-Zero Floor Tests (>= 0.0001, Never 0.0)
    
    func testPianoEnvelopeNonZeroFloorAndBounds() {
        let duration: Double = 1.6
        let velocity: Float = 0.8
        let sampleSteps = 2000
        
        var maxGain: Float = 0.0
        var minGain: Float = Float.greatestFiniteMagnitude
        
        for step in 0...sampleSteps {
            let t = (Double(step) / Double(sampleSteps)) * (duration + 0.2)
            let env = DSPMath.pianoEnvelope(time: t, duration: duration, velocity: velocity)
            
            // Critical requirement: strictly >= 0.0001 (never 0.0)
            XCTAssertGreaterThanOrEqual(env, DSPMath.envelopeFloor, "Envelope at time \(t) dipped below floor!")
            XCTAssertGreaterThan(env, 0.0, "Envelope at time \(t) was 0.0!")
            
            if env > maxGain { maxGain = env }
            if env < minGain { minGain = env }
        }
        
        // Peak attack at 8ms reaches velocity * 0.45
        let peakAtAttack = DSPMath.pianoEnvelope(time: 0.008, duration: duration, velocity: velocity)
        XCTAssertEqual(peakAtAttack, velocity * 0.45, accuracy: 0.005)
        
        // Decay at 248ms reaches velocity * 0.18
        let sustainGain = DSPMath.pianoEnvelope(time: 0.248, duration: duration, velocity: velocity)
        XCTAssertEqual(sustainGain, velocity * 0.18, accuracy: 0.005)
        
        XCTAssertLessThanOrEqual(maxGain, velocity * 0.45 + 0.001)
        XCTAssertGreaterThanOrEqual(minGain, DSPMath.envelopeFloor)
    }
    
    func testGuitarEnvelopeNonZeroFloorAndBounds() {
        let duration: Double = 1.8
        let velocity: Float = 0.85
        let sampleSteps = 2000
        
        var maxGain: Float = 0.0
        var minGain: Float = Float.greatestFiniteMagnitude
        
        for step in 0...sampleSteps {
            let t = (Double(step) / Double(sampleSteps)) * (duration + 0.2)
            let env = DSPMath.guitarEnvelope(time: t, duration: duration, velocity: velocity)
            
            XCTAssertGreaterThanOrEqual(env, DSPMath.envelopeFloor)
            XCTAssertGreaterThan(env, 0.0)
            
            if env > maxGain { maxGain = env }
            if env < minGain { minGain = env }
        }
        
        // Peak attack at 4ms reaches velocity * 0.50
        let peakAtAttack = DSPMath.guitarEnvelope(time: 0.004, duration: duration, velocity: velocity)
        XCTAssertEqual(peakAtAttack, velocity * 0.50, accuracy: 0.005)
        
        // Decay at 154ms reaches velocity * 0.22
        let sustainGain = DSPMath.guitarEnvelope(time: 0.154, duration: duration, velocity: velocity)
        XCTAssertEqual(sustainGain, velocity * 0.22, accuracy: 0.005)
        
        XCTAssertLessThanOrEqual(maxGain, velocity * 0.50 + 0.001)
        XCTAssertGreaterThanOrEqual(minGain, DSPMath.envelopeFloor)
    }
    
    // MARK: - Discrete-Time Samples Never Clip [-1.0, 1.0]
    
    func testPianoBufferSamplesNeverClip() {
        let testNotes = [21, 36, 48, 60, 72, 84, 96, 108] // A0 to C8
        
        for midi in testNotes {
            guard let buffer = DSPMath.renderPianoBuffer(
                midi: midi,
                velocity: 1.0, // Maximum velocity
                duration: 0.4,
                sampleRate: 44100.0
            ) else {
                XCTFail("Failed to render piano buffer for MIDI note \(midi)")
                return
            }
            
            guard let channelData = buffer.floatChannelData else {
                XCTFail("No float channel data in rendered buffer")
                return
            }
            
            let frameCount = Int(buffer.frameLength)
            XCTAssertGreaterThan(frameCount, 0)
            
            for ch in 0..<Int(buffer.format.channelCount) {
                let ptr = channelData[ch]
                for f in 0..<frameCount {
                    let sample = ptr[f]
                    XCTAssertGreaterThanOrEqual(sample, -1.0, "Sample at frame \(f) clipped below -1.0 for MIDI \(midi): \(sample)")
                    XCTAssertLessThanOrEqual(sample, 1.0, "Sample at frame \(f) clipped above 1.0 for MIDI \(midi): \(sample)")
                }
            }
        }
    }
    
    func testGuitarBufferSamplesNeverClip() {
        let guitarNotes = [40, 45, 50, 55, 59, 64, 76] // Standard guitar range E2-E5
        
        for midi in guitarNotes {
            guard let buffer = DSPMath.renderGuitarBuffer(
                midi: midi,
                velocity: 1.0,
                duration: 0.4,
                sampleRate: 44100.0
            ) else {
                XCTFail("Failed to render guitar buffer for MIDI note \(midi)")
                return
            }
            
            guard let channelData = buffer.floatChannelData else {
                XCTFail("No float channel data in rendered guitar buffer")
                return
            }
            
            let frameCount = Int(buffer.frameLength)
            XCTAssertGreaterThan(frameCount, 0)
            
            for ch in 0..<Int(buffer.format.channelCount) {
                let ptr = channelData[ch]
                for f in 0..<frameCount {
                    let sample = ptr[f]
                    XCTAssertGreaterThanOrEqual(sample, -1.0, "Guitar sample at frame \(f) clipped below -1.0: \(sample)")
                    XCTAssertLessThanOrEqual(sample, 1.0, "Guitar sample at frame \(f) clipped above 1.0: \(sample)")
                }
            }
        }
    }
    
    // MARK: - Direct Form II Transposed Biquad Filter Tests
    
    func testDirectForm2TransposedBiquadStability() {
        var biquad = DirectForm2TransposedBiquad()
        biquad.configureLowpass(cutoff: 1000.0, q: 0.7071, sampleRate: 44100.0)
        
        // Process unit impulse followed by 2000 zero samples
        let impulse = 1.0
        let out0 = biquad.process(sample: impulse)
        XCTAssertFalse(out0.isNaN)
        XCTAssertFalse(out0.isInfinite)
        
        var maxVal: Double = 0.0
        for _ in 0..<2000 {
            let out = biquad.process(sample: 0.0)
            XCTAssertFalse(out.isNaN)
            XCTAssertFalse(out.isInfinite)
            if abs(out) > maxVal { maxVal = abs(out) }
        }
        
        // Output should decay to near 0 without blowing up
        XCTAssertLessThan(biquad.s1, 0.001)
        XCTAssertLessThan(biquad.s2, 0.001)
    }
    
    // MARK: - VoiceNodePool Ring Buffer & Micro-Fadeout Stealing Tests
    
    func testVoiceNodePoolCircularAllocationAndStealing() {
        let pool = VoiceNodePool()
        XCTAssertEqual(pool.count, 16)
        
        // Allocate 16 distinct voices
        var allocatedVoices: [VoiceNode] = []
        for _ in 0..<16 {
            allocatedVoices.append(pool.allocateVoice())
        }
        
        // Check that all 16 voices are unique IDs 0..<16
        let ids = Set(allocatedVoices.map { $0.id })
        XCTAssertEqual(ids.count, 16)
        
        // Next allocation should wrap circularly around to voice 0
        let wrappedVoice = pool.allocateVoice()
        XCTAssertEqual(wrappedVoice.id, 0)
    }
    
    func testMicroFadeoutVoiceStealDoesNotCrash() {
        let pool = VoiceNodePool()
        let dummyFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let dummyBuffer = AVAudioPCMBuffer(pcmFormat: dummyFormat, frameCapacity: 1000)!
        dummyBuffer.frameLength = 1000
        
        // Fill 16 voices with simulated play
        for i in 0..<16 {
            let v = pool.allocateVoice()
            v.markPlaying(midi: 60 + i)
        }
        
        // Allocating 17th voice forces a voice steal with 3ms cosine fadeout
        let stolenVoice = pool.allocateVoice()
        XCTAssertEqual(stolenVoice.id, 0)
        XCTAssertFalse(stolenVoice.isPlaying, "Stolen voice should be stopped after micro-fadeout")
    }
    
    // MARK: - AudioEngine Integration Tests
    
    func testAudioEngineCacheAndProtocol() {
        let engine = AudioEngine.shared
        
        // Common register notes should be pre-cached
        XCTAssertTrue(engine.isCached(instrument: "piano", midi: 60), "Middle C (MIDI 60) should be cached")
        XCTAssertTrue(engine.isCached(instrument: "piano", midi: 72), "C5 (MIDI 72) should be cached")
        XCTAssertTrue(engine.isCached(instrument: "guitar", midi: 40), "E2 (MIDI 40) should be cached")
        
        // Test mute state toggling
        engine.setMuted(true)
        XCTAssertTrue(engine.getMuted())
        
        // Play calls while muted should safely return
        engine.playPianoDSP(midi: 60, velocity: 0.8, duration: 1.0)
        engine.playGuitarDSP(midi: 40, velocity: 0.85, duration: 1.0)
        
        engine.setMuted(false)
        XCTAssertFalse(engine.getMuted())
        
        // Play calls while unmuted execute cleanly
        engine.playPianoDSP(midi: 60, velocity: 0.8, duration: 0.2)
        engine.playGuitarDSP(midi: 45, velocity: 0.85, duration: 0.2)
    }
    
    func testMetronomeClickPlaybackThroughAudioEngine() {
        let engine = AudioEngine.shared
        
        // Both downbeat (1600Hz accent) and standard beat (1000Hz) clicks must play without throwing
        engine.setMuted(false)
        engine.playMetronomeClick(isAccent: true)
        engine.playMetronomeClick(isAccent: false)
        
        // When muted, click should be safely discarded
        engine.setMuted(true)
        engine.playMetronomeClick(isAccent: true)
        engine.setMuted(false)
    }
    
    func testAcousticPianoStereoImagingAndNaturalDecay() {
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
        guard let buffer = DSPMath.renderPianoBuffer(
            midi: 48, // C3 (bass-left stereo imaging + long sustain)
            velocity: 0.80,
            duration: 1.8,
            sampleRate: 44100.0,
            format: stereoFormat
        ), let channelData = buffer.floatChannelData else {
            XCTFail("Failed to render stereo piano buffer")
            return
        }
        
        let frames = Int(buffer.frameLength)
        let left = channelData[0]
        let right = channelData[1]
        
        // Early attack energy (first 100ms) must exceed tail energy (last 100ms)
        let window = 4410
        var earlyEnergy: Double = 0.0
        var tailEnergy: Double = 0.0
        var channelDiff: Double = 0.0
        
        for i in 0..<window {
            let l = Double(left[i])
            let r = Double(right[i])
            earlyEnergy += l * l + r * r
            channelDiff += abs(l - r)
        }
        for i in (frames - window)..<frames {
            let l = Double(left[i])
            let r = Double(right[i])
            tailEnergy += l * l + r * r
        }
        
        XCTAssertGreaterThan(earlyEnergy, tailEnergy * 4.0, "Piano tone should decay naturally from strike to tail")
        XCTAssertGreaterThan(channelDiff, 0.01, "Stereo piano buffer should exhibit subtle stereo imaging/unison width")
        XCTAssertTrue(AudioEngine.shared.isCached(instrument: "piano", midi: 36), "C2 (MIDI 36) should be pre-cached")
    }
}
