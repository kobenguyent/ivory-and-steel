import Foundation
import AVFoundation

/// High-performance digital signal processing math and waveform synthesis for Ivory & Steel.
/// Adheres strictly to 12-TET equal temperament, clickless exponential envelopes with non-zero floors,
/// and Direct Form II Transposed biquad filtering for realistic acoustic resonance.
public enum DSPMath: Sendable {
    
    /// Default high-fidelity sample rate (44.1 kHz).
    public static let standardSampleRate: Double = 44100.0
    
    /// Non-zero envelope floor to prevent WebAudio/AVAudio click pops and division by zero.
    public static let envelopeFloor: Float = 0.0001
    
    // MARK: - Pitch and Frequency Math
    
    /// Convert MIDI note number (0...127) to frequency in Hertz based on 12-TET A4 = 440 Hz.
    /// Formula: f = 440.0 * 2^((midi - 69) / 12)
    @inlinable
    public static func midiToFrequency(midi: Int) -> Double {
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
    
    /// Calculate the exact number of sample frames for a given duration in seconds.
    @inlinable
    public static func sampleFrameCount(duration: Double, sampleRate: Double) -> Int {
        guard duration > 0, sampleRate > 0 else { return 0 }
        return max(1, Int((duration * sampleRate).rounded()))
    }
    
    // MARK: - Envelopes
    
    /// Steinway Acoustic Piano ADSR Envelope.
    /// - 8ms linear attack to (velocity * 0.45)
    /// - 240ms exponential decay to (velocity * 0.18)
    /// - Smooth exponential release down to 0.0001 floor (never 0.0).
    public static func pianoEnvelope(time: Double, duration: Double, velocity: Float) -> Float {
        let clampedVelocity = max(0.01, min(1.0, velocity))
        let peak = max(envelopeFloor, clampedVelocity * 0.45)
        let sustain = max(envelopeFloor, clampedVelocity * 0.18)
        
        let attackTime: Double = 0.008 // 8ms
        let decayTime: Double = 0.240  // 240ms
        let decayEnd: Double = attackTime + decayTime // 0.248s
        
        if time <= 0.0 {
            return envelopeFloor
        }
        
        // Short note handling
        let effectiveReleaseStart = min(decayEnd, max(attackTime, duration * 0.8))
        
        if time <= attackTime {
            // Linear attack from floor to peak
            let t = Float(time / attackTime)
            return envelopeFloor + (peak - envelopeFloor) * t
        } else if time <= effectiveReleaseStart {
            // Exponential decay from peak to sustain
            let t = Float((time - attackTime) / decayTime)
            let ratio = sustain / peak
            let gain = peak * pow(ratio, min(1.0, t))
            return max(envelopeFloor, gain)
        } else if time <= duration {
            // Smooth exponential release down to envelopeFloor (never 0.0)
            let releaseDuration = max(0.001, duration - effectiveReleaseStart)
            let t = Float((time - effectiveReleaseStart) / releaseDuration)
            let ratio = envelopeFloor / sustain
            let gain = sustain * pow(ratio, min(1.0, t))
            return max(envelopeFloor, gain)
        } else {
            return envelopeFloor
        }
    }
    
    /// Acoustic Guitar Pluck Envelope.
    /// - 4ms linear attack to (velocity * 0.50)
    /// - 150ms exponential decay to (velocity * 0.22)
    /// - Smooth exponential release down to 0.0001 floor (never 0.0).
    public static func guitarEnvelope(time: Double, duration: Double, velocity: Float) -> Float {
        let clampedVelocity = max(0.01, min(1.0, velocity))
        let peak = max(envelopeFloor, clampedVelocity * 0.50)
        let sustain = max(envelopeFloor, clampedVelocity * 0.22)
        
        let attackTime: Double = 0.004 // 4ms
        let decayTime: Double = 0.150  // 150ms
        let decayEnd: Double = attackTime + decayTime // 0.154s
        
        if time <= 0.0 {
            return envelopeFloor
        }
        
        let effectiveReleaseStart = min(decayEnd, max(attackTime, duration * 0.75))
        
        if time <= attackTime {
            let t = Float(time / attackTime)
            return envelopeFloor + (peak - envelopeFloor) * t
        } else if time <= effectiveReleaseStart {
            let t = Float((time - attackTime) / decayTime)
            let ratio = sustain / peak
            let gain = peak * pow(ratio, min(1.0, t))
            return max(envelopeFloor, gain)
        } else if time <= duration {
            let releaseDuration = max(0.001, duration - effectiveReleaseStart)
            let t = Float((time - effectiveReleaseStart) / releaseDuration)
            let ratio = envelopeFloor / sustain
            let gain = sustain * pow(ratio, min(1.0, t))
            return max(envelopeFloor, gain)
        } else {
            return envelopeFloor
        }
    }
    
    /// Fast metallic decay envelope for guitar string ping (80ms exponential decay).
    public static func guitarStringPingGain(time: Double) -> Float {
        guard time >= 0 else { return 0.001 }
        let pingDuration = 0.080 // 80ms
        if time <= pingDuration {
            let t = Float(time / pingDuration)
            let startVal: Float = 0.18
            let endVal: Float = 0.001
            return startVal * pow(endVal / startVal, t)
        } else {
            return 0.001
        }
    }
    
    // MARK: - Waveform Generators
    
    /// Sine wave in range [-1.0, 1.0].
    @inlinable
    public static func sineWave(freq: Double, time: Double) -> Double {
        return sin(2.0 * Double.pi * freq * time)
    }
    
    /// Triangle wave in range [-1.0, 1.0], phase-aligned with sine wave.
    @inlinable
    public static func triangleWave(freq: Double, time: Double) -> Double {
        let phase = freq * time
        let p = phase - floor(phase)
        return 2.0 * abs(2.0 * (p - floor(p + 0.5))) - 1.0
    }
    
    /// Band-limited or bipolar sawtooth wave in range [-1.0, 1.0].
    @inlinable
    public static func sawtoothWave(freq: Double, time: Double) -> Double {
        let phase = freq * time
        let p = phase - floor(phase)
        return 2.0 * p - 1.0
    }
    
    // MARK: - Discrete-Time Harmonic Modeling
    
    /// Discrete-time sample generation for Steinway acoustic piano overtones:
    /// - 1x fundamental (sine): gain 0.60
    /// - 2x second harmonic (sine): gain 0.25
    /// - 3x third harmonic (triangle): gain 0.10
    /// - 4x fourth harmonic (sine): gain 0.05
    /// Total peak overtone gain sum = 1.00 (inherently non-clipping).
    public static func pianoOvertoneSample(fundamentalFreq: Double, time: Double) -> Double {
        let h1 = 0.60 * sineWave(freq: fundamentalFreq, time: time)
        let h2 = 0.25 * sineWave(freq: fundamentalFreq * 2.0, time: time)
        let h3 = 0.10 * triangleWave(freq: fundamentalFreq * 3.0, time: time)
        let h4 = 0.05 * sineWave(freq: fundamentalFreq * 4.0, time: time)
        return h1 + h2 + h3 + h4
    }
    
    /// Acoustic guitar model:
    /// - Triangle wave body resonance
    /// - Sawtooth wave string ping with fast 80ms metallic decay
    /// Total peak sample is normalized to ensure never clipping [-1.0, 1.0].
    public static func guitarAcousticSample(fundamentalFreq: Double, time: Double) -> Double {
        let body = triangleWave(freq: fundamentalFreq, time: time)
        let pingGain = Double(guitarStringPingGain(time: time))
        let ping = sawtoothWave(freq: fundamentalFreq, time: time) * pingGain
        // Normalize body (1.0) + peak ping (0.18) = 1.18
        return (body + ping) / 1.18
    }
    
    // MARK: - Micro-Fades for Clickless Voice Stealing
    
    /// Applies a 3ms cosine ramp-down micro-fade to prevent click pops on voice stealing.
    /// v(t) = cos((pi/2) * (t / fadeDuration))
    public static func applyCosineFadeOut(
        samples: inout [Float],
        sampleRate: Double,
        fadeDuration: Double = 0.003
    ) {
        guard !samples.isEmpty else { return }
        let fadeFrames = min(samples.count, max(1, Int((fadeDuration * sampleRate).rounded())))
        let startIndex = samples.count - fadeFrames
        
        for i in 0..<fadeFrames {
            let t = Double(i) / Double(fadeFrames)
            let factor = Float(cos(t * (Double.pi / 2.0)))
            samples[startIndex + i] *= factor
        }
    }
    
    /// Applies a 3ms cosine ramp-up micro-fade to ensure smooth onset.
    public static func applyCosineFadeIn(
        samples: inout [Float],
        sampleRate: Double,
        fadeDuration: Double = 0.003
    ) {
        guard !samples.isEmpty else { return }
        let fadeFrames = min(samples.count, max(1, Int((fadeDuration * sampleRate).rounded())))
        
        for i in 0..<fadeFrames {
            let t = Double(i) / Double(fadeFrames)
            let factor = Float(sin(t * (Double.pi / 2.0)))
            samples[i] *= factor
        }
    }
    
    // MARK: - Full Discrete-Time Buffer Rendering
    
    /// Renders an acoustic concert grand piano tone with:
    /// - Pitch-dependent string stiffness inharmonicity (f_k = k * f0 * sqrt(1 + B * k^2))
    /// - 10 Nyquist-safe partials with velocity-sensitive hammer brightness and per-partial decay
    /// - Trichord unison detuning for organic acoustic chorus and beating
    /// - Felt hammer strike transient and soundboard body resonance
    /// - Natural stereo piano imaging (bass left, treble right) and clickless non-zero floor.
    public static func renderPianoBuffer(
        midi: Int,
        velocity: Float,
        duration: Double,
        sampleRate: Double = standardSampleRate,
        format: AVAudioFormat? = nil
    ) -> AVAudioPCMBuffer? {
        let frameCount = sampleFrameCount(duration: duration, sampleRate: sampleRate)
        guard frameCount > 0 else { return nil }
        
        let clampedMidi = max(21, min(108, midi))
        let clampedVelocity = Double(max(0.05, min(1.0, velocity)))
        let freq = midiToFrequency(midi: clampedMidi)
        let audioFormat = format ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)
        
        let channelCount = Int(audioFormat.channelCount)
        var leftSamples = [Float](repeating: 0.0, count: frameCount)
        var rightSamples = [Float](repeating: 0.0, count: frameCount)
        
        // String stiffness inharmonicity coefficient B (scales with pitch)
        let inharmonicityB = max(0.00005, min(0.003, 0.00014 * pow(2.0, Double(clampedMidi - 60) / 18.0)))
        
        // Pitch-dependent overall decay scaling (bass sustains longer, treble decays faster)
        let pitchDecayScale = max(0.45, min(2.4, pow(2.0, Double(60 - clampedMidi) / 28.0)))
        
        // Partial weights (10 partials) with velocity-dependent brightness roll-off
        let baseWeights: [Double] = [1.00, 0.50, 0.27, 0.15, 0.09, 0.055, 0.035, 0.022, 0.014, 0.009]
        let nyquistLimit = sampleRate * 0.44
        
        struct PartialState {
            let phaseInc: Double
            var phase: Double
            var amp: Double
            let decayPerSample: Double
        }
        
        var partials: [PartialState] = []
        partials.reserveCapacity(baseWeights.count)
        
        for (idx, weight) in baseWeights.enumerated() {
            let k = Double(idx + 1)
            let partialFreq = k * freq * sqrt(1.0 + inharmonicityB * k * k)
            if partialFreq >= nyquistLimit { break }
            
            // Softer velocity dulls upper harmonics like a real felt hammer
            let brightnessFactor = pow(clampedVelocity, 0.25 + Double(idx) * 0.14)
            let amp = weight * brightnessFactor
            
            // Higher partials decay faster than the fundamental; bass notes decay slower
            let baseDecayRate = (0.75 + 0.55 * pow(k, 1.32)) / pitchDecayScale
            let decayPerSample = exp(-baseDecayRate / sampleRate)
            
            partials.append(PartialState(
                phaseInc: 2.0 * Double.pi * partialFreq / sampleRate,
                phase: 0.0,
                amp: amp,
                decayPerSample: decayPerSample
            ))
        }
        
        // Trichord unison detuning for partials 1..3 (real grand pianos have 2-3 strings per key)
        // Gives natural acoustic shimmer and stereo width without harsh phasing
        let detuneCents = clampedMidi >= 45 ? 0.65 : 0.30
        let detuneRatio = pow(2.0, detuneCents / 1200.0)
        var unison1Phase: Double = 0.21
        let unison1Inc = 2.0 * Double.pi * (freq * detuneRatio) / sampleRate
        var unison2Phase: Double = 1.07
        let unison2Inc = 2.0 * Double.pi * (freq * 2.0 / detuneRatio) / sampleRate
        let unisonDecay1 = exp(-(0.85 / pitchDecayScale) / sampleRate)
        let unisonDecay2 = exp(-(1.45 / pitchDecayScale) / sampleRate)
        var unisonAmp1 = 0.34 * clampedVelocity
        var unisonAmp2 = 0.16 * pow(clampedVelocity, 0.4)
        
        // Felt hammer strike transient (percussive woody knock + damped felt noise in first ~18ms)
        let hammerFreq = min(freq * 1.4 + 140.0, 820.0)
        let hammerInc = 2.0 * Double.pi * hammerFreq / sampleRate
        var hammerPhase: Double = 0.0
        var hammerAmp = 0.16 * pow(clampedVelocity, 0.85)
        let hammerDecay = exp(-180.0 / sampleRate) // ~5.5ms time constant
        
        // Fast 3ms attack + compound release toward end of buffer
        let attackSamples = max(1, Int(0.003 * sampleRate))
        let releaseStartFrame = max(attackSamples, Int(Double(frameCount) * 0.72))
        let releaseFrames = max(1, frameCount - releaseStartFrame)
        
        // Warm soundboard lowpass filter (gentle, opens on attack and mellows smoothly)
        let initialCutoff = min(freq * 8.0 + 1200.0, 9500.0)
        let finalCutoff = min(freq * 2.6 + 350.0, 3200.0)
        var biquadL = DirectForm2TransposedBiquad()
        var biquadR = DirectForm2TransposedBiquad()
        biquadL.configureLowpass(cutoff: initialCutoff, q: 0.7071, sampleRate: sampleRate)
        biquadR.configureLowpass(cutoff: initialCutoff, q: 0.7071, sampleRate: sampleRate)
        let updateInterval = max(1, Int(sampleRate * 0.01))
        
        // Stereo panorama: bass slightly left, middle centered, treble slightly right
        let pan = max(-0.32, min(0.32, (Double(clampedMidi - 60) / 36.0) * 0.32))
        let leftGain = Float(cos((pan + 1.0) * Double.pi / 4.0))
        let rightGain = Float(sin((pan + 1.0) * Double.pi / 4.0))
        
        // Calibrated output level so single notes are clear and 4-note chords never clip
        let masterScale = 0.30 * clampedVelocity
        
        // Deterministic LCG for subtle felt hammer noise (zero global state)
        var noiseSeed: UInt32 = UInt32(clampedMidi * 2654435761 & 0xFFFF_FFFF)
        
        for frame in 0..<frameCount {
            if frame % updateInterval == 0 {
                let progress = Double(frame) / Double(frameCount)
                let currentCutoff = initialCutoff * pow(finalCutoff / initialCutoff, progress)
                biquadL.configureLowpass(cutoff: currentCutoff, q: 0.7071, sampleRate: sampleRate)
                biquadR.configureLowpass(cutoff: currentCutoff, q: 0.7071, sampleRate: sampleRate)
            }
            
            var monoBody = 0.0
            for i in 0..<partials.count {
                monoBody += partials[i].amp * sin(partials[i].phase)
                partials[i].phase += partials[i].phaseInc
                partials[i].amp *= partials[i].decayPerSample
            }
            
            // Unison detuned strings contribute subtle stereo chorus
            let u1 = unisonAmp1 * sin(unison1Phase)
            let u2 = unisonAmp2 * sin(unison2Phase)
            unison1Phase += unison1Inc
            unison2Phase += unison2Inc
            unisonAmp1 *= unisonDecay1
            unisonAmp2 *= unisonDecay2
            
            // Felt hammer transient
            var hammer = 0.0
            if hammerAmp > 0.0002 {
                noiseSeed = noiseSeed &* 1664525 &+ 1013904223
                let white = (Double(noiseSeed >> 16) / 32768.0) - 1.0
                hammer = hammerAmp * (0.70 * sin(hammerPhase) + 0.30 * white)
                hammerPhase += hammerInc
                hammerAmp *= hammerDecay
            }
            
            // Smooth 3ms attack + natural release tail down to envelopeFloor
            var env = 1.0
            if frame < attackSamples {
                let t = Double(frame) / Double(attackSamples)
                env = Double(envelopeFloor) + (1.0 - Double(envelopeFloor)) * sin(t * Double.pi / 2.0)
            } else if frame >= releaseStartFrame {
                let t = Double(frame - releaseStartFrame) / Double(releaseFrames)
                env = max(Double(envelopeFloor), pow(Double(envelopeFloor), t * 0.65))
            }
            
            // Normalize harmonic sum (~1.8 peak) into clean [-1, 1] range
            let rawL = (monoBody + u1 * 0.85 + u2 * 0.65 + hammer) * 0.56
            let rawR = (monoBody + u1 * 0.65 + u2 * 0.85 + hammer) * 0.56
            
            let filtL = biquadL.process(sample: rawL)
            let filtR = biquadR.process(sample: rawR)
            
            let outL = Float(filtL * env * masterScale) * (channelCount > 1 ? leftGain * 1.414 : 1.0)
            let outR = Float(filtR * env * masterScale) * (channelCount > 1 ? rightGain * 1.414 : 1.0)
            
            leftSamples[frame] = max(-1.0, min(1.0, outL))
            rightSamples[frame] = max(-1.0, min(1.0, outR))
        }
        
        // Micro-fade at end to guarantee zero DC offset / click
        applyCosineFadeOut(samples: &leftSamples, sampleRate: sampleRate, fadeDuration: 0.004)
        if channelCount > 1 {
            applyCosineFadeOut(samples: &rightSamples, sampleRate: sampleRate, fadeDuration: 0.004)
        }
        
        // Copy to AVAudioPCMBuffer
        guard let channelData = pcmBuffer.floatChannelData else { return nil }
        let leftPtr = channelData[0]
        for frame in 0..<frameCount {
            leftPtr[frame] = leftSamples[frame]
        }
        if channelCount > 1 {
            let rightPtr = channelData[1]
            for frame in 0..<frameCount {
                rightPtr[frame] = rightSamples[frame]
            }
        }
        
        return pcmBuffer
    }
    
    /// Renders an acoustic guitar tone with plucked body resonance, fast metallic decay ping,
    /// body bandpass filtering, and warm lowpass dampening.
    public static func renderGuitarBuffer(
        midi: Int,
        velocity: Float,
        duration: Double,
        sampleRate: Double = standardSampleRate,
        format: AVAudioFormat? = nil
    ) -> AVAudioPCMBuffer? {
        let frameCount = sampleFrameCount(duration: duration, sampleRate: sampleRate)
        guard frameCount > 0 else { return nil }
        
        let freq = midiToFrequency(midi: midi)
        let audioFormat = format ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)
        
        var samples = [Float](repeating: 0.0, count: frameCount)
        
        // Body bandpass filter at 1.5x fundamental
        var bandpass = DirectForm2TransposedBiquad()
        bandpass.configureBandpass(centerFreq: freq * 1.5, q: 1.2, sampleRate: sampleRate)
        
        // Dynamic acoustic dampening lowpass filter from 5000Hz down to 600Hz
        var lowpass = DirectForm2TransposedBiquad()
        lowpass.configureLowpass(cutoff: 5000.0, q: 0.7071, sampleRate: sampleRate)
        
        let updateInterval = max(1, Int(sampleRate * 0.01))
        
        for frame in 0..<frameCount {
            let t = Double(frame) / sampleRate
            
            if frame % updateInterval == 0 {
                let progress = min(1.0, t / duration)
                let currentCutoff = 5000.0 * pow(600.0 / 5000.0, progress)
                lowpass.configureLowpass(cutoff: currentCutoff, q: 0.7071, sampleRate: sampleRate)
            }
            
            let rawSample = guitarAcousticSample(fundamentalFreq: freq, time: t)
            let bpOut = bandpass.process(sample: rawSample)
            let lpOut = lowpass.process(sample: rawSample)
            
            // Blend acoustic body and string resonance
            let blended = (bpOut * 0.45) + (lpOut * 0.55)
            let env = guitarEnvelope(time: t, duration: duration, velocity: velocity)
            
            let sampleVal = Float(blended) * env
            samples[frame] = max(-1.0, min(1.0, sampleVal))
        }
        
        applyCosineFadeOut(samples: &samples, sampleRate: sampleRate, fadeDuration: 0.004)
        
        guard let channelData = pcmBuffer.floatChannelData else { return nil }
        for channel in 0..<Int(audioFormat.channelCount) {
            let channelPtr = channelData[channel]
            for frame in 0..<frameCount {
                channelPtr[frame] = samples[frame]
            }
        }
        
        return pcmBuffer
    }
    
    // MARK: - Metronome Pre-Rendered Clicks
    
    /// Pre-rendered 1600Hz, 12ms downbeat click with exponential decay.
    public static func renderMetronomeDownbeatBuffer(
        sampleRate: Double = standardSampleRate,
        format: AVAudioFormat? = nil
    ) -> AVAudioPCMBuffer? {
        let duration: Double = 0.012 // 12ms
        let frameCount = sampleFrameCount(duration: duration, sampleRate: sampleRate)
        let audioFormat = format ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)
        
        var samples = [Float](repeating: 0.0, count: frameCount)
        let baseFreq = 1600.0
        let peakGain: Float = 0.80
        
        for frame in 0..<frameCount {
            let t = Double(frame) / sampleRate
            let progress = Float(t / duration)
            // Frequency drops slightly for a crisp woodblock/beep feel
            let currentFreq = baseFreq * pow(0.4, Double(progress))
            let wave = sineWave(freq: currentFreq, time: t)
            let gain = max(envelopeFloor, peakGain * pow(envelopeFloor / peakGain, progress))
            samples[frame] = max(-1.0, min(1.0, Float(wave) * gain))
        }
        
        applyCosineFadeOut(samples: &samples, sampleRate: sampleRate, fadeDuration: 0.002)
        
        guard let channelData = pcmBuffer.floatChannelData else { return nil }
        for channel in 0..<Int(audioFormat.channelCount) {
            let channelPtr = channelData[channel]
            for frame in 0..<frameCount {
                channelPtr[frame] = samples[frame]
            }
        }
        
        return pcmBuffer
    }
    
    /// Pre-rendered 1000Hz, 12ms standard beat click with exponential decay.
    public static func renderMetronomeStandardBeatBuffer(
        sampleRate: Double = standardSampleRate,
        format: AVAudioFormat? = nil
    ) -> AVAudioPCMBuffer? {
        let duration: Double = 0.012 // 12ms
        let frameCount = sampleFrameCount(duration: duration, sampleRate: sampleRate)
        let audioFormat = format ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)
        
        var samples = [Float](repeating: 0.0, count: frameCount)
        let baseFreq = 1000.0
        let peakGain: Float = 0.45
        
        for frame in 0..<frameCount {
            let t = Double(frame) / sampleRate
            let progress = Float(t / duration)
            let currentFreq = baseFreq * pow(0.4, Double(progress))
            let wave = sineWave(freq: currentFreq, time: t)
            let gain = max(envelopeFloor, peakGain * pow(envelopeFloor / peakGain, progress))
            samples[frame] = max(-1.0, min(1.0, Float(wave) * gain))
        }
        
        applyCosineFadeOut(samples: &samples, sampleRate: sampleRate, fadeDuration: 0.002)
        
        guard let channelData = pcmBuffer.floatChannelData else { return nil }
        for channel in 0..<Int(audioFormat.channelCount) {
            let channelPtr = channelData[channel]
            for frame in 0..<frameCount {
                channelPtr[frame] = samples[frame]
            }
        }
        
        return pcmBuffer
    }
}

// MARK: - Direct Form II Transposed Biquad Filter

/// High-precision, numerically stable Direct Form II Transposed Biquad Filter.
/// Difference equations:
///   y[n] = b0 * x[n] + s1[n-1]
///   s1[n] = b1 * x[n] - a1 * y[n] + s2[n-1]
///   s2[n] = b2 * x[n] - a2 * y[n]
public struct DirectForm2TransposedBiquad: Sendable {
    public var b0: Double = 1.0
    public var b1: Double = 0.0
    public var b2: Double = 0.0
    public var a1: Double = 0.0
    public var a2: Double = 0.0
    
    // Internal delay states
    public var s1: Double = 0.0
    public var s2: Double = 0.0
    
    public init() {}
    
    /// Resets the internal filter state.
    public mutating func reset() {
        s1 = 0.0
        s2 = 0.0
    }
    
    /// Process a single discrete-time input sample.
    @inlinable
    public mutating func process(sample x: Double) -> Double {
        let y = b0 * x + s1
        s1 = b1 * x - a1 * y + s2
        s2 = b2 * x - a2 * y
        return y
    }
    
    /// Configures a 2nd-order Butterworth / RBJ Lowpass filter.
    public mutating func configureLowpass(cutoff: Double, q: Double = 0.7071, sampleRate: Double) {
        let clampedCutoff = max(10.0, min(sampleRate * 0.49, cutoff))
        let w0 = 2.0 * Double.pi * (clampedCutoff / sampleRate)
        let alpha = sin(w0) / (2.0 * max(0.001, q))
        let cosW0 = cos(w0)
        
        let a0 = 1.0 + alpha
        self.b0 = ((1.0 - cosW0) / 2.0) / a0
        self.b1 = (1.0 - cosW0) / a0
        self.b2 = ((1.0 - cosW0) / 2.0) / a0
        self.a1 = (-2.0 * cosW0) / a0
        self.a2 = (1.0 - alpha) / a0
    }
    
    /// Configures a 2nd-order constant 0dB peak gain Bandpass filter.
    public mutating func configureBandpass(centerFreq: Double, q: Double = 1.2, sampleRate: Double) {
        let clampedFreq = max(10.0, min(sampleRate * 0.49, centerFreq))
        let w0 = 2.0 * Double.pi * (clampedFreq / sampleRate)
        let alpha = sin(w0) / (2.0 * max(0.001, q))
        let cosW0 = cos(w0)
        
        let a0 = 1.0 + alpha
        self.b0 = alpha / a0
        self.b1 = 0.0
        self.b2 = -alpha / a0
        self.a1 = (-2.0 * cosW0) / a0
        self.a2 = (1.0 - alpha) / a0
    }
}
