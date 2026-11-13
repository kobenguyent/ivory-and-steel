import SwiftUI
import AppKit

/// Studio Engine & Hardware Preferences Sheet:
/// Unified editorial inspector layout with sample-accurate AVFoundation parameters,
/// live CoreMIDI port scanning, persistent StorageManager synchronization,
/// aligned LuxuryDropdown rails, and responsive Voice Audition controls.
public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private let onDismiss: (() -> Void)?

    // Persisted Studio Settings (hydrated from StorageManager on appear)
    @State private var bufferSize: Int = 256
    @State private var selectedSynthModel: String = "Steinway Concert Grand (Acoustic DSP)"
    @State private var selectedGuitarModel: String = "Boutique Luthier Steel String"

    // Live UI & Feedback State
    @State private var statusFeedback: String? = nil
    @State private var statusIsAccent: Bool = true
    @State private var statusClearTask: DispatchWorkItem? = nil

    @State private var isAuditioningA4: Bool = false
    @State private var isAuditioningPianoVoice: Bool = false
    @State private var isAuditioningGuitarVoice: Bool = false
    @State private var rescanSpinCount: Int = 0

    // Two-step safe destructive arming (prevents accidental wipes without modal alerts)
    @State private var armedClearPractice: Bool = false
    @State private var armedClearQuiz: Bool = false

    @State private var practiceLogsCount: Int = 0
    @State private var quizRecordsCount: Int = 0

    private let controlRailWidth: CGFloat = 264

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    private var latencyEstimateText: String {
        switch bufferSize {
        case 64: return "~1.4 ms"
        case 128: return "~2.9 ms"
        case 256: return "~5.8 ms"
        default: return "~11.6 ms"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            editorialHeaderBar

            Divider()
                .background(Color.hairlineDivider)

            ScrollView {
                VStack(spacing: 14) {
                    audioEngineSection
                    coreMIDISection
                    acousticModelingSection
                    storageSection
                    softwareUpdateSection
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }

            Divider()
                .background(Color.hairlineDivider)

            editorialFooterBar
        }
        .background(Color.musicianEbony)
        .onAppear {
            loadPersistedState()
        }
    }

    // MARK: - Pinned Top Header Bar

    private var editorialHeaderBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Preferences")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Text("Audio, MIDI hardware, instruments, and local data")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button(action: closeSheet) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.musicianIvory.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7))
                    .contentShape(Circle())
            }
            .studioPressable()
            .keyboardShortcut(.cancelAction)
            .help("Close Preferences (Esc)")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(Color.musicianSurface.opacity(0.92))
    }

    // MARK: - Section 1: Audio

    private var audioEngineSection: some View {
        PreferenceSectionCard(title: "Audio") {
            VStack(spacing: 0) {
                PreferenceRow(
                    title: "Buffer Size",
                    subtitle: "Lower values reduce key-to-sound delay"
                ) {
                    LuxuryDropdown(
                        selection: $bufferSize,
                        options: [
                            LuxuryDropdownOption(value: 64, title: "64 samples", subtitle: "~1.4 ms latency"),
                            LuxuryDropdownOption(value: 128, title: "128 samples", subtitle: "~2.9 ms latency"),
                            LuxuryDropdownOption(value: 256, title: "256 samples", subtitle: "~5.8 ms balanced"),
                            LuxuryDropdownOption(value: 512, title: "512 samples", subtitle: "~11.6 ms stability")
                        ],
                        minWidth: controlRailWidth,
                        popoverWidth: 268
                    ) { newSize in
                        StorageManager.shared.updateSettings { $0.audioBufferSize = newSize }
                        showFeedback("Buffer size saved (\(newSize) samples · \(latencyEstimateText))")
                    }
                    .frame(width: controlRailWidth)
                }

                rowHairline

                PreferenceRow(
                    title: "Sample Rate",
                    subtitle: "Studio output format"
                ) {
                    Text("44.1 kHz")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.musicianIvory.opacity(0.85))
                        .frame(width: controlRailWidth, alignment: .trailing)
                }

                rowHairline

                PreferenceRow(
                    title: "Reference Pitch",
                    subtitle: "Concert tuning tone (A4)"
                ) {
                    HStack {
                        Spacer()
                        StudioPillActionButton(
                            icon: isAuditioningA4 ? "waveform" : "play.fill",
                            title: appState.isMuted ? "Audio Muted" : "Play A4 (440 Hz)",
                            accent: Color.musicianGold,
                            isActive: isAuditioningA4,
                            isDisabled: appState.isMuted
                        ) {
                            appState.playPiano(midi: 69, velocity: 0.82, duration: 1.6)
                            withAnimation(StudioMotion.snappyControl) { isAuditioningA4 = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                withAnimation(StudioMotion.softHover) { isAuditioningA4 = false }
                            }
                        }
                    }
                    .frame(width: controlRailWidth, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Section 2: MIDI & Keyboard

    private var coreMIDISection: some View {
        let hasMIDI = !appState.connectedMIDIDevices.isEmpty
        return PreferenceSectionCard(title: "MIDI & Keyboard") {
            VStack(spacing: 0) {
                PreferenceRow(
                    title: "External MIDI",
                    subtitle: "Connected USB or Bluetooth controllers"
                ) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(hasMIDI ? Color.subdominantEmerald : Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)

                            Text(hasMIDI ? appState.connectedMIDIDevices.joined(separator: ", ") : "None connected")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(hasMIDI ? Color.subdominantEmerald : Color.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer(minLength: 6)

                        Button(action: rescanMIDI) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .bold))
                                    .rotationEffect(.degrees(Double(rescanSpinCount) * 360.0))
                                    .animation(StudioMotion.cardGlide, value: rescanSpinCount)
                                Text("Scan")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .foregroundColor(Color.musicianIvory)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7))
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .studioPressable()
                        .help("Rescan USB & Bluetooth MIDI inputs")
                    }
                    .frame(width: controlRailWidth, alignment: .trailing)
                }

                rowHairline

                PreferenceRow(
                    title: "Computer Keyboard",
                    subtitle: "Play notes directly on Virtual Piano"
                ) {
                    Text("A–K white · W–P black")
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.musicianIvory.opacity(0.75))
                        .frame(width: controlRailWidth, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Section 3: Instruments

    private var acousticModelingSection: some View {
        PreferenceSectionCard(title: "Instruments") {
            VStack(spacing: 0) {
                PreferenceRow(
                    title: "Piano Sound",
                    subtitle: "Tone character used across views"
                ) {
                    LuxuryDropdown(
                        selection: $selectedSynthModel,
                        options: [
                            LuxuryDropdownOption(value: "Steinway Concert Grand (Acoustic DSP)", title: "Concert Grand"),
                            LuxuryDropdownOption(value: "Pure 12-TET Harmonic Sine", title: "Harmonic Sine"),
                            LuxuryDropdownOption(value: "Bright Upright Felt", title: "Upright Felt")
                        ],
                        minWidth: controlRailWidth,
                        popoverWidth: 268
                    ) { newModel in
                        StorageManager.shared.updateSettings { $0.soundfontModel = newModel }
                        showFeedback("Piano sound saved")
                    }
                    .frame(width: controlRailWidth)
                }

                rowHairline

                PreferenceRow(
                    title: "Guitar Sound",
                    subtitle: "Body character used for plucked notes"
                ) {
                    LuxuryDropdown(
                        selection: $selectedGuitarModel,
                        options: [
                            LuxuryDropdownOption(value: "Boutique Luthier Steel String", title: "Steel String"),
                            LuxuryDropdownOption(value: "Nylon String Classical", title: "Classical Nylon"),
                            LuxuryDropdownOption(value: "Archtop Semi-Hollow", title: "Archtop Hollow")
                        ],
                        minWidth: controlRailWidth,
                        popoverWidth: 268
                    ) { newModel in
                        StorageManager.shared.updateSettings { $0.guitarModel = newModel }
                        showFeedback("Guitar sound saved")
                    }
                    .frame(width: controlRailWidth)
                }

                rowHairline

                PreferenceRow(
                    title: "Sound Check",
                    subtitle: "Preview sample voicings"
                ) {
                    HStack(spacing: 8) {
                        StudioPillActionButton(
                            icon: "pianokeys",
                            title: "Piano Cmaj7",
                            accent: Color.musicianGold,
                            isActive: isAuditioningPianoVoice,
                            isDisabled: appState.isMuted
                        ) {
                            appState.playChordVoicing(notes: ["C4", "E4", "G4", "B4"], isGuitar: false, stepDelay: 0.03)
                            withAnimation(StudioMotion.snappyControl) { isAuditioningPianoVoice = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                withAnimation(StudioMotion.softHover) { isAuditioningPianoVoice = false }
                            }
                        }

                        StudioPillActionButton(
                            icon: "guitars",
                            title: "Guitar Em9",
                            accent: Color.subdominantEmerald,
                            isActive: isAuditioningGuitarVoice,
                            isDisabled: appState.isMuted
                        ) {
                            appState.playChordVoicing(notes: ["E3", "B3", "D4", "G4", "F#5"], isGuitar: true, stepDelay: 0.045)
                            withAnimation(StudioMotion.snappyControl) { isAuditioningGuitarVoice = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                withAnimation(StudioMotion.softHover) { isAuditioningGuitarVoice = false }
                            }
                        }
                    }
                    .frame(width: controlRailWidth, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Section 4: Data & Storage

    private var storageSection: some View {
        PreferenceSectionCard(title: "Data & Storage") {
            VStack(spacing: 0) {
                PreferenceRow(
                    title: "Saved Data",
                    subtitle: "Local JSON file in Application Support"
                ) {
                    HStack {
                        Spacer()
                        Button(action: revealStorageInFinder) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Reveal in Finder")
                                    .font(.system(size: 11.5, weight: .semibold))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .foregroundColor(Color.musicianIvory)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7))
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .studioPressable()
                    }
                    .frame(width: controlRailWidth, alignment: .trailing)
                }

                rowHairline

                PreferenceRow(
                    title: "History Logs",
                    subtitle: "Practice: \(practiceLogsCount) · Quizzes: \(quizRecordsCount)"
                ) {
                    HStack(spacing: 8) {
                        Button(action: handleClearPractice) {
                            HStack(spacing: 5) {
                                Image(systemName: armedClearPractice ? "exclamationmark.triangle.fill" : "trash")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(armedClearPractice ? "Confirm?" : "Clear Practice")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .foregroundColor(armedClearPractice ? Color.musicianIvory : Color.gray.opacity(0.95))
                            .background(armedClearPractice ? Color.steinwayCrimson : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .strokeBorder(armedClearPractice ? Color.steinwayCrimson : Color.white.opacity(0.10), lineWidth: 0.7)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .studioPressable()
                        .disabled(practiceLogsCount == 0 && !armedClearPractice)
                        .opacity(practiceLogsCount == 0 && !armedClearPractice ? 0.45 : 1.0)

                        Button(action: handleClearQuiz) {
                            HStack(spacing: 5) {
                                Image(systemName: armedClearQuiz ? "exclamationmark.triangle.fill" : "trash")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(armedClearQuiz ? "Confirm?" : "Clear Quizzes")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .foregroundColor(armedClearQuiz ? Color.musicianIvory : Color.gray.opacity(0.95))
                            .background(armedClearQuiz ? Color.steinwayCrimson : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .strokeBorder(armedClearQuiz ? Color.steinwayCrimson : Color.white.opacity(0.10), lineWidth: 0.7)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .studioPressable()
                        .disabled(quizRecordsCount == 0 && !armedClearQuiz)
                        .opacity(quizRecordsCount == 0 && !armedClearQuiz ? 0.45 : 1.0)
                    }
                    .frame(width: controlRailWidth, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Pinned Bottom Footer Bar

    private var editorialFooterBar: some View {
        HStack(spacing: 12) {
            if let statusFeedback {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11.5))
                        .foregroundColor(statusIsAccent ? Color.subdominantEmerald : Color.musicianGold)
                    Text(statusFeedback)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.musicianIvory.opacity(0.9))
                }
                .transition(.studioPill)
            } else {
                Text("Latency \(latencyEstimateText) · Auto-saved")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.gray)
            }

            Spacer()

            Button(action: closeSheet) {
                Text("Done")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 7)
                    .foregroundColor(Color.musicianEbony)
                    .background(LinearGradient.goldGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.musicianGold.opacity(0.25), radius: 6, y: 2)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .studioPressable()
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(Color.musicianSurface.opacity(0.94))
        .animation(StudioMotion.snappyControl, value: statusFeedback)
    }

    private var rowHairline: some View {
        Rectangle()
            .fill(Color.hairlineDivider)
            .frame(height: 0.5)
    }

    // MARK: - State & Actions

    private func loadPersistedState() {
        let stored = StorageManager.shared.settings
        bufferSize = stored.audioBufferSize
        selectedSynthModel = stored.soundfontModel
        selectedGuitarModel = stored.guitarModel
        practiceLogsCount = StorageManager.shared.practiceSessions.count
        quizRecordsCount = StorageManager.shared.quizResults.count
        appState.connectedMIDIDevices = MIDIManager.shared.refreshSources()
    }

    private func rescanMIDI() {
        rescanSpinCount &+= 1
        let devices = MIDIManager.shared.refreshSources()
        appState.connectedMIDIDevices = devices
        showFeedback(devices.isEmpty ? "MIDI scan complete · 0 external sources" : "Detected \(devices.count) MIDI source(s)")
    }

    private func revealStorageInFinder() {
        let url = StorageManager.shared.storageFileURL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }

    private func handleClearPractice() {
        if !armedClearPractice {
            withAnimation(StudioMotion.snappyControl) {
                armedClearQuiz = false
                armedClearPractice = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(StudioMotion.softHover) { armedClearPractice = false }
            }
            return
        }
        StorageManager.shared.clearPracticeSessions()
        withAnimation(StudioMotion.snappyControl) {
            armedClearPractice = false
            practiceLogsCount = StorageManager.shared.practiceSessions.count
        }
        showFeedback("Practice routine logs cleared")
    }

    private func handleClearQuiz() {
        if !armedClearQuiz {
            withAnimation(StudioMotion.snappyControl) {
                armedClearPractice = false
                armedClearQuiz = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(StudioMotion.softHover) { armedClearQuiz = false }
            }
            return
        }
        StorageManager.shared.clearQuizResults()
        withAnimation(StudioMotion.snappyControl) {
            armedClearQuiz = false
            quizRecordsCount = StorageManager.shared.quizResults.count
        }
        showFeedback("Quiz assessment history cleared")
    }

    private func showFeedback(_ message: String, isAccent: Bool = true) {
        statusClearTask?.cancel()
        withAnimation(StudioMotion.snappyControl) {
            statusIsAccent = isAccent
            statusFeedback = message
        }
        let work = DispatchWorkItem {
            withAnimation(StudioMotion.softHover) {
                self.statusFeedback = nil
            }
        }
        statusClearTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
    }

    private func closeSheet() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
    
    // MARK: - Section 5: Software Updates & GitHub Releases
    
    private var softwareUpdateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.down.circle.dotted")
                    .foregroundColor(Color.musicianGold)
                Text("Software Updates & GitHub Releases")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                
                Spacer()
                
                Text("v\(appState.currentAppVersion)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.musicianSurface)
                    .foregroundColor(Color.musicianGold)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Update Status:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    Text(updateStatusSummary)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(updateStatusColor)
                }
                
                if let lastCheck = appState.lastUpdateCheckDate {
                    HStack {
                        Text("Last Checked:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                        
                        Spacer()
                        
                        Text(lastCheck.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundColor(Color.musicianIvory.opacity(0.8))
                    }
                }
                
                Toggle(
                    "Automatically check for updates on launch",
                    isOn: Binding(
                        get: { appState.autoCheckForUpdates },
                        set: { appState.setAutoCheckForUpdates($0) }
                    )
                )
                .font(.system(size: 12))
                .foregroundColor(Color.musicianIvory)
                .toggleStyle(.switch)
                
                Toggle(
                    "Include pre-release / beta builds",
                    isOn: Binding(
                        get: { appState.includePrereleases },
                        set: { appState.setIncludePrereleases($0) }
                    )
                )
                .font(.system(size: 12))
                .foregroundColor(Color.musicianIvory)
                .toggleStyle(.switch)
                
                HStack(spacing: 12) {
                    Button(action: {
                        appState.checkForUpdates(userInitiated: true)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(appState.updateStatus.isChecking ? "Checking…" : "Check for Updates Now")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.musicianGold)
                    .foregroundColor(Color.musicianEbony)
                    .disabled(appState.updateStatus.isChecking)
                    
                    Button("View GitHub Releases") {
                        NSWorkspace.shared.open(appState.updateChecker.releasesWebURL)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var updateStatusSummary: String {
        switch appState.updateStatus {
        case .idle:
            return "Ready to check"
        case .checking:
            return "Checking GitHub Releases…"
        case .upToDate(let ver, _):
            return "Up to date (v\(ver))"
        case .updateAvailable(let release, _):
            return "Update available: \(release.tagName)"
        case .error(let msg):
            return msg
        }
    }
    
    private var updateStatusColor: Color {
        switch appState.updateStatus {
        case .idle, .checking:
            return Color.musicianIvory
        case .upToDate:
            return Color.subdominantEmerald
        case .updateAvailable:
            return Color.musicianGold
        case .error:
            return Color.steinwayCrimson
        }
    }
}

// MARK: - Reusable Studio Inspector Components

private struct PreferenceSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            content()
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.9)
        )
    }
}

private struct PreferenceRow<Control: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Color.musicianIvory.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color.gray.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            control()
        }
        .padding(.vertical, 9)
    }
}

private struct StudioPillActionButton: View {
    let icon: String
    let title: String
    let accent: Color
    let isActive: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 11)
            .frame(height: 28)
            .foregroundColor(isActive ? Color.musicianEbony : accent)
            .background(isActive ? accent : (isHovered ? accent.opacity(0.18) : accent.opacity(0.11)))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(accent.opacity(isActive ? 0.9 : 0.32), lineWidth: 0.8)
            )
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .studioPressable()
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
    }
}
