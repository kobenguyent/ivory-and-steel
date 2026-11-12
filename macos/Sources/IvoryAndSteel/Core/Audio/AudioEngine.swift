import Foundation
import AVFoundation

/// Primary audio engine for Ivory & Steel Native macOS.
/// Manages high-performance AVFoundation graph (AVAudioEngine, AVAudioMixerNode, AVAudioUnitEQ, VoiceNodePool),
/// pre-computed PCM buffer caching for common register notes, and discrete-time DSP rendering.
public final class AudioEngine: AudioEngineProtocol, @unchecked Sendable {
    
    public static let shared = AudioEngine()
    
    public let engine: AVAudioEngine
    public let mixerNode: AVAudioMixerNode
    public let eqNode: AVAudioUnitEQ
    public let voicePool: VoiceNodePool
    
    private let lock = NSLock()
    private var isMutedState: Bool = false
    private let sampleRate: Double
    private let standardFormat: AVAudioFormat
    
    // Cache for pre-computed PCM buffers
    private struct CacheKey: Hashable {
        let instrument: String
        let midi: Int
    }
    private var bufferCache: [CacheKey: AVAudioPCMBuffer] = [:]
    
    // Pre-rendered Metronome click buffers (stereo, 44.1kHz)
    private var metronomeDownbeatBuffer: AVAudioPCMBuffer?
    private var metronomeStandardBeatBuffer: AVAudioPCMBuffer?
    
    public init() {
        self.engine = AVAudioEngine()
        self.mixerNode = AVAudioMixerNode()
        self.eqNode = AVAudioUnitEQ(numberOfBands: 3)
        self.voicePool = VoiceNodePool()
        
        // 44.1 kHz standard audio format
        self.sampleRate = DSPMath.standardSampleRate
        self.standardFormat = AVAudioFormat(standardFormatWithSampleRate: DSPMath.standardSampleRate, channels: 2)
            ?? AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: DSPMath.standardSampleRate, channels: 2, interleaved: false)!
        
        setupAudioGraph()
        configureAcousticEQ()
        precomputeCommonRegister()
        precomputeMetronomeClicks()
        startEngine()
    }
    
    // MARK: - Graph Configuration
    
    private func setupAudioGraph() {
        engine.attach(mixerNode)
        engine.attach(eqNode)
        
        // Connect 16-voice pool to submixer
        voicePool.attachAndConnect(to: engine, mixerNode: mixerNode, format: standardFormat)
        
        // Connect mixerNode -> eqNode -> mainMixerNode
        engine.connect(mixerNode, to: eqNode, format: standardFormat)
        engine.connect(eqNode, to: engine.mainMixerNode, format: standardFormat)
    }
    
    private func configureAcousticEQ() {
        // Band 0: Low-shelf for acoustic soundboard body warmth (+1.2 dB @ 120Hz)
        let lowShelf = eqNode.bands[0]
        lowShelf.filterType = .lowShelf
        lowShelf.frequency = 120.0
        lowShelf.gain = 1.2
        lowShelf.bypass = false
        
        // Band 1: Parametric presence band (+0.8 dB @ 2500Hz, Q = 1.4)
        let presenceBand = eqNode.bands[1]
        presenceBand.filterType = .parametric
        presenceBand.frequency = 2500.0
        presenceBand.bandwidth = 1.4
        presenceBand.gain = 0.8
        presenceBand.bypass = false
        
        // Band 2: High-shelf roll-off to eliminate digital aliasing (-1.0 dB @ 9000Hz)
        let highShelf = eqNode.bands[2]
        highShelf.filterType = .highShelf
        highShelf.frequency = 9000.0
        highShelf.gain = -1.0
        highShelf.bypass = false
    }
    
    public func startEngine() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            // In headless/CI environments, output device may not be active
        }
    }
    
    // MARK: - Pre-Computed Buffer Caching
    
    /// Pre-renders PCM buffers for common concert piano register (C3-C6, MIDI 48-84)
    /// and standard guitar register (E2-E5, MIDI 40-76).
    public func precomputeCommonRegister() {
        lock.lock()
        defer { lock.unlock() }
        
        // Common Piano Register (C3 to C6)
        for midi in 48...84 {
            let key = CacheKey(instrument: "piano", midi: midi)
            if let buffer = DSPMath.renderPianoBuffer(
                midi: midi,
                velocity: 0.80,
                duration: 1.6,
                sampleRate: sampleRate,
                format: standardFormat
            ) {
                bufferCache[key] = buffer
            }
        }
        
        // Common Guitar Register (E2 to E5)
        for midi in 40...76 {
            let key = CacheKey(instrument: "guitar", midi: midi)
            if let buffer = DSPMath.renderGuitarBuffer(
                midi: midi,
                velocity: 0.85,
                duration: 1.8,
                sampleRate: sampleRate,
                format: standardFormat
            ) {
                bufferCache[key] = buffer
            }
        }
    }
    
    /// Pre-renders high-precision woodblock clicks for metronome downbeats (1600Hz) and standard beats (1000Hz).
    public func precomputeMetronomeClicks() {
        self.metronomeDownbeatBuffer = DSPMath.renderMetronomeDownbeatBuffer(sampleRate: sampleRate, format: standardFormat)
        self.metronomeStandardBeatBuffer = DSPMath.renderMetronomeStandardBeatBuffer(sampleRate: sampleRate, format: standardFormat)
    }
    
    /// Check whether a buffer exists in the pre-computed cache.
    public func isCached(instrument: String, midi: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return bufferCache[CacheKey(instrument: instrument, midi: midi)] != nil
    }
    
    // MARK: - AudioEngineProtocol Implementation
    
    public func setMuted(_ muted: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self.isMutedState = muted
        mixerNode.outputVolume = muted ? 0.0 : 1.0
        if muted {
            voicePool.stopAll()
        }
    }
    
    public func getMuted() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isMutedState
    }
    
    public func playPianoDSP(midi: Int, velocity: Float = 0.8, duration: Double = 1.6) {
        if getMuted() { return }
        
        startEngine()
        
        let key = CacheKey(instrument: "piano", midi: midi)
        let isStandardProfile = abs(velocity - 0.80) <= 0.05 && abs(duration - 1.6) <= 0.1
        
        let bufferToPlay: AVAudioPCMBuffer?
        
        lock.lock()
        if isStandardProfile, let cached = bufferCache[key] {
            bufferToPlay = cached
            lock.unlock()
        } else {
            lock.unlock()
            bufferToPlay = DSPMath.renderPianoBuffer(
                midi: midi,
                velocity: velocity,
                duration: duration,
                sampleRate: sampleRate,
                format: standardFormat
            )
        }
        
        guard let buffer = bufferToPlay else { return }
        voicePool.play(buffer: buffer, midi: midi)
    }
    
    public func playGuitarDSP(midi: Int, velocity: Float = 0.85, duration: Double = 1.8) {
        if getMuted() { return }
        
        startEngine()
        
        let key = CacheKey(instrument: "guitar", midi: midi)
        let isStandardProfile = abs(velocity - 0.85) <= 0.05 && abs(duration - 1.8) <= 0.1
        
        let bufferToPlay: AVAudioPCMBuffer?
        
        lock.lock()
        if isStandardProfile, let cached = bufferCache[key] {
            bufferToPlay = cached
            lock.unlock()
        } else {
            lock.unlock()
            bufferToPlay = DSPMath.renderGuitarBuffer(
                midi: midi,
                velocity: velocity,
                duration: duration,
                sampleRate: sampleRate,
                format: standardFormat
            )
        }
        
        guard let buffer = bufferToPlay else { return }
        voicePool.play(buffer: buffer, midi: midi)
    }
    
    public func playMetronomeClick(isAccent: Bool) {
        if getMuted() { return }
        startEngine()
        guard let buffer = isAccent ? metronomeDownbeatBuffer : metronomeStandardBeatBuffer else { return }
        voicePool.play(buffer: buffer)
    }
}
