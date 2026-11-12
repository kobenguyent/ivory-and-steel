import XCTest
import AVFoundation
@testable import IvoryAndSteel

final class MetronomeEngineTests: XCTestCase {
    
    // MARK: - Pre-Rendered Click Buffers
    
    func testMetronomeDownbeatClickCharacteristics() {
        let sampleRate: Double = 44100.0
        guard let buffer = DSPMath.renderMetronomeDownbeatBuffer(sampleRate: sampleRate) else {
            XCTFail("Failed to render downbeat click buffer")
            return
        }
        
        let expectedFrames = DSPMath.sampleFrameCount(duration: 0.012, sampleRate: sampleRate)
        XCTAssertEqual(Int(buffer.frameLength), expectedFrames, "Downbeat click duration must be exactly 12ms")
        
        guard let channelData = buffer.floatChannelData else {
            XCTFail("Missing float channel data")
            return
        }
        
        let ptr = channelData[0]
        for f in 0..<Int(buffer.frameLength) {
            let sample = ptr[f]
            XCTAssertGreaterThanOrEqual(sample, -1.0, "Downbeat click clipped below -1.0")
            XCTAssertLessThanOrEqual(sample, 1.0, "Downbeat click clipped above 1.0")
        }
    }
    
    func testMetronomeStandardBeatClickCharacteristics() {
        let sampleRate: Double = 44100.0
        guard let buffer = DSPMath.renderMetronomeStandardBeatBuffer(sampleRate: sampleRate) else {
            XCTFail("Failed to render standard beat click buffer")
            return
        }
        
        let expectedFrames = DSPMath.sampleFrameCount(duration: 0.012, sampleRate: sampleRate)
        XCTAssertEqual(Int(buffer.frameLength), expectedFrames, "Standard beat click duration must be exactly 12ms")
        
        guard let channelData = buffer.floatChannelData else {
            XCTFail("Missing float channel data")
            return
        }
        
        let ptr = channelData[0]
        for f in 0..<Int(buffer.frameLength) {
            let sample = ptr[f]
            XCTAssertGreaterThanOrEqual(sample, -1.0, "Standard beat click clipped below -1.0")
            XCTAssertLessThanOrEqual(sample, 1.0, "Standard beat click clipped above 1.0")
        }
    }
    
    // MARK: - Sample Frame Calculation Accuracy
    
    func testBeatIntervalFrameCalculations() {
        let sampleRate: Double = 44100.0
        
        // At 120 BPM: 60 / 120 = 0.5s -> 22,050 samples per beat
        let frames120 = Int(( (60.0 / 120.0) * sampleRate ).rounded())
        XCTAssertEqual(frames120, 22050)
        
        // At 60 BPM: 60 / 60 = 1.0s -> 44,100 samples per beat
        let frames60 = Int(( (60.0 / 60.0) * sampleRate ).rounded())
        XCTAssertEqual(frames60, 44100)
        
        // At 140 BPM: 60 / 140 = 0.428571s -> 18,900 samples per beat
        let frames140 = Int(( (60.0 / 140.0) * sampleRate ).rounded())
        XCTAssertEqual(frames140, 18900)
    }
    
    // MARK: - Metronome Protocol & State Lifecycle
    
    func testMetronomeLifecycle() {
        let metronome = MetronomeEngine()
        XCTAssertFalse(metronome.isRunning)
        
        // Start metronome at 120 BPM with 4/4 time signature
        metronome.start(bpm: 120.0, timeSignature: (beats: 4, value: 4))
        XCTAssertTrue(metronome.isRunning)
        XCTAssertEqual(metronome.bpm, 120.0)
        
        // Dynamic BPM update
        metronome.updateBPM(144.0)
        XCTAssertEqual(metronome.bpm, 144.0)
        XCTAssertTrue(metronome.isRunning)
        
        // Clamping check
        metronome.updateBPM(500.0)
        XCTAssertEqual(metronome.bpm, 320.0, "BPM should be clamped to 320 max")
        
        metronome.updateBPM(5.0)
        XCTAssertEqual(metronome.bpm, 20.0, "BPM should be clamped to 20 min")
        
        // Stop metronome
        metronome.stop()
        XCTAssertFalse(metronome.isRunning)
    }
    
    func testMetronomeRapidStartStopCycles() {
        let metronome = MetronomeEngine()
        
        // Rapid toggle cycles must remain stable and idempotent
        for _ in 0..<5 {
            metronome.start(bpm: 132.0, timeSignature: (beats: 4, value: 4))
            XCTAssertTrue(metronome.isRunning)
            metronome.stop()
            XCTAssertFalse(metronome.isRunning)
        }
    }
    
    func testMetronomeStateIntegration() {
        let state = AppState(audioEngine: nil, metronomeEngine: MetronomeEngine())
        XCTAssertFalse(state.isMetronomePlaying)
        
        // Single toggle activates
        state.toggleMetronome()
        XCTAssertTrue(state.isMetronomePlaying)
        XCTAssertTrue(state.metronomeEngine?.isRunning ?? false)
        
        // Second toggle deactivates
        state.toggleMetronome()
        XCTAssertFalse(state.isMetronomePlaying)
        XCTAssertFalse(state.metronomeEngine?.isRunning ?? true)
    }
}
