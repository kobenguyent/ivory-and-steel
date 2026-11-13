import Foundation
import SwiftUI
import Observation

/// Central observable application state for Ivory & Steel Native macOS.
/// Marked with `@Observable` macro for Swift 5.9+ / Swift 6 fine-grained reactivity.
@Observable
public final class AppState: @unchecked Sendable {
    
    // MARK: - Navigation & Active Views
    public var selectedTab: AppTab = .theoryExplorer
    
    // MARK: - Music Theory & Selection State
    public var rootKey: String = "C" {
        didSet {
            updatePreferFlat()
        }
    }
    public var selectedScaleId: String = "major"
    public var selectedChordId: String = "major"
    public var preferFlat: Bool = false
    public var selectedDiatonicIndex: Int = 0
    public var activeInstrument: String = "piano" // "piano" or "guitar"
    public var octaveShift: Int = 0 // -2 to +2
    
    // MARK: - Interactive Voice & MIDI Tracking
    public var activeMidiNotes: Set<Int> = []
    public var activeVoicingNotes: [String] = []
    public var isMuted: Bool = false
    public var connectedMIDIDevices: [String] = []
    
    // MARK: - Metronome State
    public var metronomeBPM: Double = 120.0 {
        didSet {
            metronomeEngine?.updateBPM(metronomeBPM)
        }
    }
    public var isMetronomePlaying: Bool = false
    public var metronomeTimeSignature: (beats: Int, value: Int) = (4, 4)
    public var currentBeatTick: Int = 0
    public var isDownbeatTick: Bool = false
    
    // MARK: - Software Update State (GitHub Releases)
    public var updateStatus: UpdateStatus = .idle
    public var showingUpdateSheet: Bool = false
    public var autoCheckForUpdates: Bool = true
    public var includePrereleases: Bool = false
    public var lastUpdateCheckDate: Date? = nil
    
    // MARK: - Injected Services (Optional / Protocol Conformances)
    public var audioEngine: AudioEngineProtocol?
    public var metronomeEngine: MetronomeProtocol?
    public var updateChecker: UpdateCheckerProtocol
    
    public var currentAppVersion: String {
        updateChecker.currentVersion
    }
    
    // MARK: - Initialization
    public init(
        audioEngine: AudioEngineProtocol? = nil,
        metronomeEngine: MetronomeProtocol? = nil,
        updateChecker: UpdateCheckerProtocol = UpdateChecker.shared
    ) {
        self.audioEngine = audioEngine
        self.metronomeEngine = metronomeEngine
        self.updateChecker = updateChecker
        let savedSettings = StorageManager.shared.settings
        self.autoCheckForUpdates = savedSettings.autoCheckForUpdates
        self.includePrereleases = savedSettings.includePrereleases
        self.lastUpdateCheckDate = savedSettings.lastUpdateCheckDate
        self.updatePreferFlat()
    }
    
    // MARK: - Tab Selection Shortcuts (⌘1 - ⌘7)
    
    public func selectTab(_ tab: AppTab) {
        self.selectedTab = tab
    }
    
    public func selectTabByIndex(_ index: Int) {
        let tabs = AppTab.allCases
        guard index >= 0 && index < tabs.count else { return }
        self.selectedTab = tabs[index]
    }
    
    // MARK: - Theory Selection Actions
    
    public func setRootKey(_ key: String) {
        self.rootKey = key
        self.selectedDiatonicIndex = 0
    }
    
    public func setScaleId(_ scaleId: String) {
        self.selectedScaleId = scaleId
    }
    
    public func setChordId(_ chordId: String) {
        self.selectedChordId = chordId
    }
    
    public func togglePreferFlat() {
        self.preferFlat.toggle()
    }
    
    private func updatePreferFlat() {
        let flatKeys = ["F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb", "D#", "A#", "G#"]
        if flatKeys.contains(rootKey) || rootKey.contains("b") || rootKey.contains("♭") {
            self.preferFlat = true
        } else {
            self.preferFlat = false
        }
    }
    
    // MARK: - Audio & Note Playback
    
    public func toggleMute() {
        isMuted.toggle()
        audioEngine?.setMuted(isMuted)
    }
    
    public func toggleMetronome() {
        isMetronomePlaying.toggle()
        if isMetronomePlaying {
            metronomeEngine?.start(bpm: metronomeBPM, timeSignature: metronomeTimeSignature)
        } else {
            metronomeEngine?.stop()
        }
    }
    
    public func setBPM(_ bpm: Double) {
        let clamped = max(30.0, min(300.0, bpm))
        self.metronomeBPM = clamped
    }
    
    public func playMetronomeClick(isAccent: Bool) {
        guard !isMuted else { return }
        audioEngine?.playMetronomeClick(isAccent: isAccent)
    }
    
    public func playPiano(midi: Int, velocity: Float = 0.8, duration: Double = 1.5) {
        guard !isMuted else { return }
        audioEngine?.playPianoDSP(midi: midi, velocity: velocity, duration: duration)
        
        DispatchQueue.main.async {
            self.activeMidiNotes.insert(midi)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.activeMidiNotes.remove(midi)
        }
    }
    
    public func playGuitar(midi: Int, velocity: Float = 0.85, duration: Double = 2.0) {
        guard !isMuted else { return }
        audioEngine?.playGuitarDSP(midi: midi, velocity: velocity, duration: duration)
        
        DispatchQueue.main.async {
            self.activeMidiNotes.insert(midi)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.activeMidiNotes.remove(midi)
        }
    }
    
    public func playChordVoicing(notes: [String], isGuitar: Bool = false) {
        guard !isMuted else { return }
        self.activeVoicingNotes = notes
        
        for (index, note) in notes.enumerated() {
            let midi = MusicTheoryEngine.shared.midiNote(for: note)
            let delay = Double(index) * 0.04 // micro-strum feel
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isGuitar {
                    self.playGuitar(midi: midi, velocity: 0.82, duration: 2.2)
                } else {
                    self.playPiano(midi: midi, velocity: 0.80, duration: 1.8)
                }
            }
        }
    }
    
    // MARK: - CoreMIDI Input Handlers
    
    public func handleMIDINoteOn(midi: Int, velocity: Float) {
        guard !isMuted else { return }
        DispatchQueue.main.async {
            self.activeMidiNotes.insert(midi)
        }
        audioEngine?.playPianoDSP(midi: midi, velocity: velocity, duration: 1.8)
    }
    
    public func handleMIDINoteOff(midi: Int) {
        DispatchQueue.main.async {
            self.activeMidiNotes.remove(midi)
        }
    }
    
    // MARK: - GitHub Releases Auto-Update Check
    
    /// Triggers an asynchronous GitHub Releases update check.
    /// - Parameter userInitiated: When `true`, opens the Update dialog immediately and ignores skipped release tags.
    public func checkForUpdates(userInitiated: Bool = false) {
        Task { @MainActor in
            await performUpdateCheck(userInitiated: userInitiated)
        }
    }
    
    /// Performs the update check and updates observable properties on the MainActor.
    @MainActor
    public func performUpdateCheck(userInitiated: Bool = false) async {
        guard !updateStatus.isChecking else {
            if userInitiated {
                showingUpdateSheet = true
            }
            return
        }
        
        updateStatus = .checking
        if userInitiated {
            showingUpdateSheet = true
        }
        
        let status = await updateChecker.checkForUpdates(includePrereleases: includePrereleases)
        let now = Date()
        updateStatus = status
        lastUpdateCheckDate = now
        
        StorageManager.shared.updateSettings { settings in
            settings.lastUpdateCheckDate = now
        }
        
        if case .updateAvailable(let release, _) = status {
            let skippedTag = StorageManager.shared.settings.skippedReleaseTag
            if userInitiated || skippedTag != release.tagName {
                showingUpdateSheet = true
            }
        }
    }
    
    /// Marks a specific release tag as skipped for automatic background prompts.
    public func skipRelease(tag: String) {
        StorageManager.shared.updateSettings { settings in
            settings.skippedReleaseTag = tag
        }
        showingUpdateSheet = false
    }
    
    public func setAutoCheckForUpdates(_ enabled: Bool) {
        autoCheckForUpdates = enabled
        StorageManager.shared.updateSettings { settings in
            settings.autoCheckForUpdates = enabled
        }
    }
    
    public func setIncludePrereleases(_ enabled: Bool) {
        includePrereleases = enabled
        StorageManager.shared.updateSettings { settings in
            settings.includePrereleases = enabled
        }
    }
}

