import Foundation

public protocol AudioEngineProtocol: Sendable {
    func playPianoDSP(midi: Int, velocity: Float, duration: Double)
    func playGuitarDSP(midi: Int, velocity: Float, duration: Double)
    func playMetronomeClick(isAccent: Bool)
    func setMuted(_ muted: Bool)
    func getMuted() -> Bool
}

public protocol MetronomeProtocol: AnyObject, Sendable {
    func start(bpm: Double, timeSignature: (beats: Int, value: Int))
    func stop()
    func updateBPM(_ bpm: Double)
    var isRunning: Bool { get }
}

