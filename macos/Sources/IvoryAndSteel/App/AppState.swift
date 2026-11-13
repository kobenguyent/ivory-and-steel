import Foundation
import SwiftUI
import Observation

/// Central observable application state for Ivory & Steel Native macOS.
/// Marked with `@Observable` macro for Swift 5.9+ / Swift 6 fine-grained reactivity.
@Observable
public final class AppState: @unchecked Sendable {
    
    // MARK: - Navigation & Active Views
    public var selectedTab: AppTab = .theoryExplorer
    public var masterclassSelectedTipId: String? = nil

    // MARK: - Instrument Studio Guide Sync
    public var pianoGuideEnabled: Bool = false
    public var pianoGuideScaleId: String = "major"
    public var guitarGuideEnabled: Bool = true
    public var guitarGuideScaleId: String = "minor_pentatonic"
    
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
    private var chordPlaybackGeneration: Int = 0
    
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

    // MARK: - Cross-Page Handoffs

    public func openInPianoStudio(
        root: String? = nil,
        scaleId: String? = nil,
        voicingNotes: [String]? = nil
    ) {
        if let root { setRootKey(root) }
        self.activeInstrument = "piano"
        if let voicingNotes, !voicingNotes.isEmpty {
            self.activeVoicingNotes = voicingNotes
            self.pianoGuideEnabled = false
        } else if let scaleId {
            self.selectedScaleId = scaleId
            self.pianoGuideScaleId = scaleId
            self.pianoGuideEnabled = true
        }
        selectTab(.virtualPiano)
    }

    public func openInGuitarStudio(
        root: String? = nil,
        scaleId: String? = nil,
        voicingNotes: [String]? = nil
    ) {
        if let root { setRootKey(root) }
        self.activeInstrument = "guitar"
        if let scaleId {
            self.selectedScaleId = scaleId
            self.guitarGuideScaleId = scaleId
            self.guitarGuideEnabled = true
        } else if let voicingNotes, !voicingNotes.isEmpty {
            self.activeVoicingNotes = voicingNotes
            self.guitarGuideEnabled = false
        }
        selectTab(.guitarFretboard)
    }

    public func openMetronome(atBPM bpm: Double? = nil) {
        if let bpm { setBPM(bpm) }
        selectTab(.metronome)
    }

    public func openMasterclassTopic(id: String) {
        self.masterclassSelectedTipId = id
        selectTab(.masterclassHub)
    }

    public func addTaskToPracticeRoutine(
        title: String,
        details: String = "",
        estimatedMinutes: Int? = 5,
        targetBPM: Double? = nil,
        navigate: Bool = true,
        storage: StorageManager = .shared
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var tasks = storage.practiceTasks
        if !tasks.contains(where: { $0.title.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            let task = PracticeChecklistTask(
                title: trimmed,
                details: details,
                estimatedMinutes: estimatedMinutes,
                targetBPM: targetBPM,
                isCompleted: false
            )
            tasks.append(task)
            storage.savePracticeTasks(tasks)
        }
        if navigate {
            selectTab(.practiceRoutine)
        }
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
    
    public func playChordVoicing(notes: [String], isGuitar: Bool = false, stepDelay: Double? = nil) {
        guard !isMuted else { return }
        self.activeVoicingNotes = notes
        self.chordPlaybackGeneration &+= 1
        let generation = self.chordPlaybackGeneration
        
        let resolvedDelay = stepDelay ?? (isGuitar ? 0.035 : 0.022) // natural guitar strum vs pianist rolled chord
        for (index, note) in notes.enumerated() {
            let midi = MusicTheoryEngine.shared.midiNote(for: note)
            let delay = Double(index) * resolvedDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.chordPlaybackGeneration == generation else { return }
                if isGuitar {
                    self.playGuitar(midi: midi, velocity: 0.82, duration: 2.2)
                } else {
                    self.playPiano(midi: midi, velocity: 0.80, duration: 1.8)
                }
            }
        }
    }

    /// Stops any in-flight scheduled chord/scale/cadence playback immediately.
    public func stopQuizPlayback() {
        self.chordPlaybackGeneration &+= 1
        self.activeVoicingNotes = []
    }

    /// Plays a multi-modal conservatory `QuizAudioCue` (melodic intervals, harmonic/arpeggiated chords, scales, or chord progressions).
    /// Supports overriding articulation style (e.g. toggling Harmonic vs Arpeggio inside the Audio Audition Deck).
    public func playQuizCue(_ cue: QuizAudioCue, overrideStyle: AudioPlaybackStyle? = nil) {
        guard !isMuted else { return }
        self.chordPlaybackGeneration &+= 1
        let generation = self.chordPlaybackGeneration
        let effectiveStyle = overrideStyle ?? cue.style

        switch effectiveStyle {
        case .chordProgression:
            let sequence = cue.progressions ?? (cue.notes.isEmpty ? [] : [cue.notes])
            let step = max(0.35, cue.stepDuration)
            for (chordIdx, chordNotes) in sequence.enumerated() {
                let chordDelay = Double(chordIdx) * step
                DispatchQueue.main.asyncAfter(deadline: .now() + chordDelay) { [weak self] in
                    guard let self = self, self.chordPlaybackGeneration == generation else { return }
                    self.activeVoicingNotes = chordNotes
                    for (noteIdx, note) in chordNotes.enumerated() {
                        let midi = MusicTheoryEngine.shared.midiNote(for: note)
                        let microRoll = Double(noteIdx) * (cue.isGuitar ? 0.025 : 0.015)
                        DispatchQueue.main.asyncAfter(deadline: .now() + microRoll) { [weak self] in
                            guard let self = self, self.chordPlaybackGeneration == generation else { return }
                            if cue.isGuitar {
                                self.playGuitar(midi: midi, velocity: 0.80, duration: step * 1.15)
                            } else {
                                self.playPiano(midi: midi, velocity: 0.78, duration: step * 1.15)
                            }
                        }
                    }
                }
            }

        case .melodic, .scale:
            self.activeVoicingNotes = cue.notes
            let step = max(0.18, cue.stepDuration)
            for (idx, note) in cue.notes.enumerated() {
                let midi = MusicTheoryEngine.shared.midiNote(for: note)
                let delay = Double(idx) * step
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self, self.chordPlaybackGeneration == generation else { return }
                    if cue.isGuitar {
                        self.playGuitar(midi: midi, velocity: 0.84, duration: 1.4)
                    } else {
                        self.playPiano(midi: midi, velocity: 0.82, duration: 1.2)
                    }
                }
            }

        case .arpeggiated:
            playChordVoicing(notes: cue.notes, isGuitar: cue.isGuitar, stepDelay: max(0.28, cue.stepDuration))

        case .harmonic:
            playChordVoicing(notes: cue.notes, isGuitar: cue.isGuitar, stepDelay: cue.isGuitar ? 0.028 : 0.016)
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

