import Foundation
import AVFoundation

/// Individual managed voice in the polyphonic synthesizer pool.
public final class VoiceNode: @unchecked Sendable {
    public let id: Int
    public let playerNode: AVAudioPlayerNode
    public fileprivate(set) var isPlaying: Bool = false
    public fileprivate(set) var currentMidi: Int? = nil
    public fileprivate(set) var playStartTime: TimeInterval = 0.0
    
    init(id: Int) {
        self.id = id
        self.playerNode = AVAudioPlayerNode()
    }
    
    func markPlaying(midi: Int?) {
        self.isPlaying = true
        self.currentMidi = midi
        self.playStartTime = ProcessInfo.processInfo.systemUptime
    }
    
    func markStopped() {
        self.isPlaying = false
        self.currentMidi = nil
    }
}

/// 16-voice circular allocation ring buffer of `AVAudioPlayerNode` instances.
/// Features micro-fadeout (3ms cosine ramp) on voice stealing to prevent click pops.
public final class VoiceNodePool: @unchecked Sendable {
    
    public static let poolCapacity: Int = 16
    
    private let lock = NSLock()
    private var voices: [VoiceNode] = []
    private var ringIndex: Int = 0
    private var isConnected: Bool = false
    
    public var count: Int {
        return voices.count
    }
    
    public init() {
        self.voices = (0..<Self.poolCapacity).map { VoiceNode(id: $0) }
    }
    
    /// Attach all 16 player nodes to the engine and connect them to the mixer.
    public func attachAndConnect(
        to engine: AVAudioEngine,
        mixerNode: AVAudioMixerNode,
        format: AVAudioFormat? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        for voice in voices {
            if voice.playerNode.engine == nil {
                engine.attach(voice.playerNode)
            }
            engine.connect(voice.playerNode, to: mixerNode, format: format)
        }
        isConnected = true
    }
    
    /// Allocate a voice using circular ring buffer mechanics.
    /// If the selected voice is currently playing, a 3ms cosine micro-fadeout is performed
    /// to steal the voice without audible clicks or speaker pops.
    public func allocateVoice() -> VoiceNode {
        lock.lock()
        defer { lock.unlock() }
        
        let voice = voices[ringIndex]
        ringIndex = (ringIndex + 1) % Self.poolCapacity
        
        if voice.isPlaying {
            performMicroFadeoutVoiceSteal(voice: voice)
        }
        
        return voice
    }
    
    /// Schedule and play an audio PCM buffer on the next ring-allocated voice.
    @discardableResult
    public func play(
        buffer: AVAudioPCMBuffer,
        midi: Int? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> VoiceNode {
        let voice = allocateVoice()
        
        lock.lock()
        voice.markPlaying(midi: midi)
        lock.unlock()
        
        voice.playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak voice] in
            guard let voice = voice else { return }
            self.lock.lock()
            voice.markStopped()
            self.lock.unlock()
            completion?()
        }
        
        if !voice.playerNode.isPlaying {
            voice.playerNode.play()
        }
        
        return voice
    }
    
    /// Stop all active voices immediately without deadlocking completion queues.
    public func stopAll() {
        lock.lock()
        let activeVoices = voices.filter { $0.isPlaying }
        for voice in activeVoices {
            voice.markStopped()
        }
        lock.unlock()
        
        for voice in activeVoices {
            voice.playerNode.stop()
        }
    }
    
    // MARK: - Voice Stealing & Click Prevention
    
    /// Executes a 3ms cosine fadeout ramp on the active player node before stopping it.
    /// Formula: factor = cos((pi/2) * (step / totalSteps))
    private func performMicroFadeoutVoiceSteal(voice: VoiceNode) {
        let node = voice.playerNode
        let initialVolume = node.volume
        
        // 3ms cosine fadeout over 6 discrete micro-steps (0.5ms each)
        let steps = 6
        let stepDuration = 0.003 / Double(steps) // 0.0005 seconds
        
        for step in 1...steps {
            let t = Double(step) / Double(steps)
            let factor = Float(cos(t * (Double.pi / 2.0)))
            node.volume = initialVolume * factor
            Thread.sleep(forTimeInterval: stepDuration)
        }
        
        node.stop()
        node.volume = initialVolume // Restore full calibrated volume for new voice
        voice.markStopped()
    }
}
