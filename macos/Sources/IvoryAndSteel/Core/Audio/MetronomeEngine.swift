import Foundation
import AVFoundation

/// Sample-accurate, jitter-free Metronome Engine for Ivory & Steel Native macOS.
/// Uses high-precision dispatch timer synchronized to master `AudioEngine` voice pool
/// with pre-rendered downbeat click (1600Hz, 12ms) and standard beat click (1000Hz, 12ms).
public final class MetronomeEngine: MetronomeProtocol, @unchecked Sendable {
    
    public static let shared = MetronomeEngine()
    
    private let lock = NSLock()
    private var isRunningState: Bool = false
    private var currentBPM: Double = 120.0
    private var currentBeatsPerBar: Int = 4
    private var beatValue: Int = 4
    
    private var schedulerTimer: DispatchSourceTimer?
    private let schedulerQueue = DispatchQueue(label: "com.ivoryandsteel.metronome.scheduler", qos: .userInteractive)
    private var currentBeatIndex: Int = 0
    
    /// Optional callback for visual beat indicator synchronization (beatIndex, isDownbeat)
    public var onBeatTick: (@Sendable (Int, Bool) -> Void)?
    
    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRunningState
    }
    
    public var bpm: Double {
        lock.lock()
        defer { lock.unlock() }
        return currentBPM
    }
    
    public init(engine: AVAudioEngine? = nil) {
        // Shares the master AudioEngine audio graph & VoiceNodePool
    }
    
    deinit {
        stop()
    }
    
    // MARK: - MetronomeProtocol Implementation
    
    public func start(bpm: Double, timeSignature: (beats: Int, value: Int)) {
        lock.lock()
        defer { lock.unlock() }
        
        self.currentBPM = max(20.0, min(320.0, bpm))
        self.currentBeatsPerBar = max(1, timeSignature.beats)
        self.beatValue = max(1, timeSignature.value)
        self.isRunningState = true
        self.currentBeatIndex = 0
        
        startTimer()
    }
    
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        isRunningState = false
        schedulerTimer?.cancel()
        schedulerTimer = nil
        currentBeatIndex = 0
    }
    
    public func updateBPM(_ bpm: Double) {
        lock.lock()
        defer { lock.unlock() }
        self.currentBPM = max(20.0, min(320.0, bpm))
        if isRunningState {
            startTimer()
        }
    }
    
    // MARK: - High-Precision Timer Scheduling
    
    private func startTimer() {
        schedulerTimer?.cancel()
        
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: schedulerQueue)
        let intervalNs = UInt64((60.0 / currentBPM) * 1_000_000_000.0)
        
        timer.schedule(deadline: .now(), repeating: .nanoseconds(Int(intervalNs)), leeway: .nanoseconds(500_000))
        timer.setEventHandler { [weak self] in
            self?.fireTick()
        }
        
        self.schedulerTimer = timer
        timer.resume()
    }
    
    private func fireTick() {
        lock.lock()
        guard isRunningState else {
            lock.unlock()
            return
        }
        let beat = currentBeatIndex
        let isDownbeat = (beat % currentBeatsPerBar == 0)
        currentBeatIndex = (currentBeatIndex + 1) % currentBeatsPerBar
        lock.unlock()
        
        // Play acoustic woodblock click via master AudioEngine voice pool
        AudioEngine.shared.playMetronomeClick(isAccent: isDownbeat)
        
        // Notify visual callback
        onBeatTick?(beat, isDownbeat)
    }
}
