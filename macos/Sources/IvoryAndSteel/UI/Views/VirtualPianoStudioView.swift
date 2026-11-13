import SwiftUI

/// Virtual Piano Studio View: Full-width 2-octave piano console,
/// octave shift, arpeggio/strum controls, and CoreMIDI device connection status.
public struct VirtualPianoStudioView: View {
    @Environment(AppState.self) private var appState
    @Namespace private var consoleNS

    @State private var sustainPedalDown: Bool = false
    @State private var isSustainHovered: Bool = false
    @State private var isGuideToggleHovered: Bool = false
    @State private var isOctaveResetHovered: Bool = false
    @State private var showKeyboardGuideSheet: Bool = false

    private let theory = MusicTheoryEngine.shared

    public init() {}

    private var guideRootBinding: Binding<String> {
        Binding(
            get: { appState.rootKey },
            set: { appState.setRootKey($0) }
        )
    }

    private var guideScaleBinding: Binding<String> {
        Binding(
            get: { appState.pianoGuideScaleId },
            set: { appState.pianoGuideScaleId = $0 }
        )
    }

    private var activeGuideScaleName: String {
        ScaleDefinitions.scale(for: appState.pianoGuideScaleId)?.name ?? "Major Scale"
    }

    private var highlightedNotes: [String] {
        guard appState.pianoGuideEnabled else {
            return appState.activeVoicingNotes
        }
        let scaleNotes = theory.notes(forScale: appState.pianoGuideScaleId, rootKey: appState.rootKey)
        return scaleNotes.map { note in
            let baseMidi = theory.midiNote(for: note)
            let shifted = max(0, min(127, baseMidi + (appState.octaveShift * 12)))
            let pc = shifted % 12
            let oct = (shifted / 12) - 1
            let name = KeyDefinitions.formatPitchName(pitchClass: pc, preferFlat: appState.preferFlat)
            return "\(name)\(oct)"
        }
    }

    private var activeCompassRange: String {
        "C\(4 + appState.octaveShift)–C\(6 + appState.octaveShift)"
    }

    private var consoleSubtitle: String {
        if appState.pianoGuideEnabled {
            return "\(appState.rootKey) \(activeGuideScaleName)"
        }
        if !appState.activeVoicingNotes.isEmpty {
            return appState.activeVoicingNotes.joined(separator: " · ")
        }
        return "Play using letter keys (A–K) or a connected MIDI keyboard"
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Hardware & Guide Control Bar
                HStack(spacing: 12) {
                    midiStatusBadge

                    Spacer(minLength: 10)

                    HStack(spacing: 10) {
                        octaveConsoleStepper
                        sustainPedalSwitch

                        Button(action: { showKeyboardGuideSheet = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "keyboard")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Shortcuts")
                                    .font(.system(size: 11.5, weight: .medium))
                            }
                            .foregroundColor(Color.musicianIvory.opacity(0.85))
                            .padding(.horizontal, 11)
                            .frame(height: 34)
                            .background(Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.9)
                            )
                        }
                        .studioPressable()
                        .help("View computer keyboard note mapping")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.glassBorder, lineWidth: 1)
                )

                // Scale Guide Bar
                HStack(spacing: 12) {
                    practiceGuideTogglePill

                    if appState.pianoGuideEnabled {
                        HStack(spacing: 10) {
                            LuxuryDropdown(
                                selection: guideRootBinding,
                                options: KeyDefinitions.chromaticRoots.map {
                                    LuxuryDropdownOption(value: $0, title: "Key of \($0)")
                                },
                                minWidth: 125,
                                popoverWidth: 185
                            )

                            LuxuryDropdown(
                                selection: guideScaleBinding,
                                options: ScaleDefinitions.allScales.map {
                                    LuxuryDropdownOption(value: $0.id, title: $0.name)
                                },
                                minWidth: 180,
                                popoverWidth: 240
                            )
                        }
                        .transition(.studioPill)
                    } else if !appState.activeVoicingNotes.isEmpty {
                        Text("Voicing: \(appState.activeVoicingNotes.joined(separator: " · "))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight)

                        Button(action: { appState.activeVoicingNotes = [] }) {
                            Text("Clear")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.gray)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(appState.pianoGuideEnabled ? Color.goldHairline : Color.glassBorder, lineWidth: 0.9)
                )
                .animation(StudioMotion.cardGlide, value: appState.pianoGuideEnabled)

                // Full Concert Grand Piano Console (2 Octaves)
                NativePianoView(
                    highlightedNotes: highlightedNotes,
                    externalActiveMidiNotes: appState.activeMidiNotes,
                    rootNote: appState.rootKey,
                    preferFlat: appState.preferFlat,
                    title: "Piano Keyboard (\(activeCompassRange))",
                    subtitle: consoleSubtitle,
                    onPlayNote: { _, midi in
                        let shiftedMidi = midi + (appState.octaveShift * 12)
                        let duration = sustainPedalDown ? 3.5 : 1.6
                        appState.playPiano(midi: shiftedMidi, velocity: 0.85, duration: duration)
                    }
                )
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .sheet(isPresented: $showKeyboardGuideSheet) {
            keyboardGuideSheetContent
        }
    }

    private var keyboardGuideSheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                Spacer()
                Button(action: { showKeyboardGuideSheet = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.musicianIvory.opacity(0.75))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }

            Divider().background(Color.hairlineDivider)

            VStack(alignment: .leading, spacing: 10) {
                keycapLegendRow(
                    category: "White Keys",
                    pairs: [("A", "C4"), ("S", "D4"), ("D", "E4"), ("F", "F4"), ("G", "G4"), ("H", "A4"), ("J", "B4"), ("K", "C5"), ("L", "D5"), (";", "E5")]
                )
                keycapLegendRow(
                    category: "Black Keys",
                    pairs: [("W", "C#"), ("E", "D#"), ("T", "F#"), ("Y", "G#"), ("U", "A#"), ("O", "C#5"), ("P", "D#5")]
                )
            }
        }
        .padding(22)
        .frame(width: 520)
        .background(Color.musicianEbony)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Console Subviews
    
    private var midiStatusBadge: some View {
        let isConnected = !appState.connectedMIDIDevices.isEmpty
        return HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.musicianGold : Color.white.opacity(0.28))
                .frame(width: 7, height: 7)

            Text(isConnected ? appState.connectedMIDIDevices.joined(separator: ", ") : "Virtual Keyboard Ready")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(isConnected ? Color.musicianIvory : Color.gray)
                .lineLimit(1)
        }
        .animation(StudioMotion.snappyControl, value: isConnected)
    }
    
    private var octaveConsoleStepper: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                Text("Octave")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.gray)
                Text(activeCompassRange)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(appState.octaveShift == 0 ? Color.white.opacity(0.65) : Color.musicianGoldLight)
                    .contentTransition(.numericText())
            }
            
            HStack(spacing: 0) {
                OctaveStepButton(
                    systemImage: "minus",
                    accessibilityText: "Decrease octave",
                    isDisabled: appState.octaveShift <= -2
                ) {
                    if appState.octaveShift > -2 {
                        withAnimation(StudioMotion.snappyControl) {
                            appState.octaveShift -= 1
                        }
                    }
                }
                
                Rectangle()
                    .fill(Color.hairlineDivider)
                    .frame(width: 0.7, height: 18)
                
                Button(action: {
                    guard appState.octaveShift != 0 else { return }
                    withAnimation(StudioMotion.snappyControl) {
                        appState.octaveShift = 0
                    }
                }) {
                    VStack(spacing: 2.5) {
                        Text(appState.octaveShift > 0 ? "+\(appState.octaveShift)" : "\(appState.octaveShift)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(appState.octaveShift == 0 ? Color.musicianIvory : Color.musicianGoldLight)
                            .contentTransition(.numericText())
                        
                        // 5-pip Octave Range Rail (-2 ... +2)
                        HStack(spacing: 3.5) {
                            ForEach(-2...2, id: \.self) { step in
                                let isActive = (appState.octaveShift == step)
                                ZStack {
                                    Circle()
                                        .fill(step == 0 ? Color.white.opacity(0.28) : Color.white.opacity(0.14))
                                        .frame(width: 3, height: 3)
                                    if isActive {
                                        Circle()
                                            .fill(Color.musicianGold)
                                            .frame(width: 4.5, height: 4.5)
                                            .shadow(color: Color.musicianGold.opacity(0.65), radius: 2.5)
                                            .matchedGeometryEffect(id: "octave_active_pip", in: consoleNS)
                                    }
                                }
                                .frame(width: 4.5, height: 4.5)
                            }
                        }
                    }
                    .frame(width: 50, height: 34)
                    .background(isOctaveResetHovered && appState.octaveShift != 0 ? Color.glassSurfaceHover : Color.clear)
                    .contentShape(Rectangle())
                }
                .studioPressable(scale: 0.96)
                .onHover { hovering in
                    withAnimation(StudioMotion.softHover) {
                        isOctaveResetHovered = hovering
                    }
                }
                .help(appState.octaveShift == 0 ? "Standard Concert Range (C4–C6)" : "Click to reset octave to 0 (C4–C6)")
                .accessibilityLabel("Current octave shift \(appState.octaveShift), range \(activeCompassRange)")
                
                Rectangle()
                    .fill(Color.hairlineDivider)
                    .frame(width: 0.7, height: 18)
                
                OctaveStepButton(
                    systemImage: "plus",
                    accessibilityText: "Increase octave",
                    isDisabled: appState.octaveShift >= 2
                ) {
                    if appState.octaveShift < 2 {
                        withAnimation(StudioMotion.snappyControl) {
                            appState.octaveShift += 1
                        }
                    }
                }
            }
            .frame(height: 34)
            .background(Color.musicianSurface)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(appState.octaveShift != 0 ? Color.goldHairline : Color.white.opacity(0.09), lineWidth: 0.9)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 4, y: 1)
        }
    }
    
    private var sustainPedalSwitch: some View {
        Button(action: {
            withAnimation(StudioMotion.snappyControl) {
                sustainPedalDown.toggle()
            }
        }) {
            HStack(spacing: 8) {
                // Damper LED Indicator
                ZStack {
                    if sustainPedalDown {
                        Circle()
                            .fill(Color.musicianEbony.opacity(0.22))
                            .frame(width: 12, height: 12)
                    }
                    Circle()
                        .fill(sustainPedalDown ? Color.musicianEbony : Color.white.opacity(isSustainHovered ? 0.42 : 0.24))
                        .frame(width: 6, height: 6)
                }
                .frame(width: 12, height: 12)
                
                Text("Sustain Pedal")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(sustainPedalDown ? Color.musicianEbony : Color.musicianIvory.opacity(isSustainHovered ? 1.0 : 0.88))
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background {
                if sustainPedalDown {
                    LinearGradient.goldGlow
                } else {
                    isSustainHovered ? Color.glassSurfaceHover : Color.musicianSurface
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(
                        sustainPedalDown
                            ? Color.white.opacity(0.32)
                            : Color.white.opacity(isSustainHovered ? 0.17 : 0.09),
                        lineWidth: 0.9
                    )
            )
            .shadow(
                color: sustainPedalDown ? Color.musicianGold.opacity(0.28) : Color.black.opacity(0.22),
                radius: sustainPedalDown ? 9 : 4,
                y: sustainPedalDown ? 2 : 1
            )
        }
        .studioPressable(scale: 0.965)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isSustainHovered = hovering
            }
        }
        .help(sustainPedalDown ? "Damper engaged (3.5s acoustic resonance decay)" : "Engage acoustic sustain damper pedal (3.5s decay)")
        .accessibilityLabel("Sustain Pedal")
        .accessibilityValue(sustainPedalDown ? "On, 3.5 second decay" : "Off, 1.6 second decay")
    }
    
    private var practiceGuideTogglePill: some View {
        Button(action: {
            withAnimation(StudioMotion.snappyControl) {
                appState.pianoGuideEnabled.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Text("Scale Guide")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(appState.pianoGuideEnabled ? Color.musicianIvory : Color.white.opacity(0.82))

                // Compact recessed switch track
                ZStack(alignment: appState.pianoGuideEnabled ? .trailing : .leading) {
                    Capsule()
                        .fill(appState.pianoGuideEnabled ? Color.musicianGold : Color.white.opacity(0.14))
                        .frame(width: 28, height: 16)

                    Circle()
                        .fill(appState.pianoGuideEnabled ? Color.musicianEbony : Color.musicianIvory.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .padding(2)
                        .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 0.5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(appState.pianoGuideEnabled ? Color.musicianGold.opacity(0.10) : (isGuideToggleHovered ? Color.glassSurfaceHover : Color.white.opacity(0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(appState.pianoGuideEnabled ? Color.goldHairline : Color.glassBorder, lineWidth: 0.8)
            )
        }
        .studioPressable(scale: 0.97)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isGuideToggleHovered = hovering
            }
        }
        .accessibilityLabel("Scale Guide")
        .accessibilityValue(appState.pianoGuideEnabled ? "Enabled" : "Disabled")
    }
    
    private func keycapLegendRow(category: String, pairs: [(key: String, note: String)]) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(category)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.48))
                .frame(width: 62, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(pairs, id: \.key) { pair in
                        HStack(spacing: 3) {
                            Text(pair.key)
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.musicianGoldLight)
                                .padding(.horizontal, 4.5)
                                .padding(.vertical, 1.5)
                                .background(Color.musicianSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                                )
                            
                            Text(pair.note)
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Console Step Button Helper

private struct OctaveStepButton: View {
    let systemImage: String
    let accessibilityText: String
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(isDisabled ? Color.white.opacity(0.2) : (isHovered ? Color.musicianGoldLight : Color.musicianIvory))
                .frame(width: 32, height: 34)
                .background(isHovered && !isDisabled ? Color.glassSurfaceHover : Color.clear)
                .contentShape(Rectangle())
        }
        .studioPressable(scale: 0.92)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(accessibilityText)
    }
}

