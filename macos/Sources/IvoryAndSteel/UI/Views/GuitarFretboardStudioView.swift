import SwiftUI

/// Guitar Fretboard Studio View: Dedicated 15-fret acoustic luthier console,
/// tuning selector, CAGED chord shapes, and real-time plucked string resonance.
public struct GuitarFretboardStudioView: View {
    @Environment(AppState.self) private var appState
    
    public enum GuitarTuning: String, CaseIterable, Identifiable, Sendable {
        case standard = "Standard (E A D G B E)"
        case dropD = "Drop D (D A D G B E)"
        case dadgad = "DADGAD (Celtic / Folk)"
        case openG = "Open G (D G D G B D)"
        case openD = "Open D (D A D F# A D)"
        
        public var id: String { rawValue }
        
        // Open string MIDI note numbers: String 6 to 1
        public var openMidiNotes: [Int] {
            switch self {
            case .standard: return [40, 45, 50, 55, 59, 64] // E2, A2, D3, G3, B3, E4
            case .dropD:    return [38, 45, 50, 55, 59, 64] // D2, A2, D3, G3, B3, E4
            case .dadgad:   return [38, 45, 50, 55, 57, 62] // D2, A2, D3, G3, A3, D4
            case .openG:    return [38, 43, 50, 55, 59, 62] // D2, G2, D3, G3, B3, D4
            case .openD:    return [38, 45, 50, 54, 57, 62] // D2, A2, D3, F#3, A3, D4
            }
        }
    }
    
    @State private var selectedTuning: GuitarTuning = .standard
    @State private var selectedCAGED: CAGEDForm = .all
    @State private var showGuideSheet: Bool = false

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
            get: { appState.guitarGuideScaleId },
            set: { appState.guitarGuideScaleId = $0 }
        )
    }

    private var activeHighlights: [FretHighlightModel] {
        let targetPitchNotes: [String]
        if appState.guitarGuideEnabled {
            targetPitchNotes = theory.notes(forScale: appState.guitarGuideScaleId, rootKey: appState.rootKey)
        } else if !appState.activeVoicingNotes.isEmpty {
            targetPitchNotes = appState.activeVoicingNotes
        } else {
            return []
        }

        let scaleNotes = targetPitchNotes.map {
            $0.replacingOccurrences(of: "[0-9-]", with: "", options: .regularExpression).uppercased()
        }
        let openNotes = selectedTuning.openMidiNotes
        var highlights: [FretHighlightModel] = []

        for (idx, openMidi) in openNotes.enumerated() {
            let stringNum = 6 - idx // 6 = Low, 1 = High
            for fret in 0...15 {
                if let range = selectedCAGED.fretRange, !range.contains(fret), fret != 0 {
                    continue
                }

                let midi = openMidi + fret
                let pc = midi % 12
                let noteName = KeyDefinitions.formatPitchName(pitchClass: pc, preferFlat: appState.preferFlat)

                if scaleNotes.contains(where: { KeyDefinitions.rootPitchMap[$0.uppercased()] == pc }) {
                    let isRoot = (KeyDefinitions.rootPitchMap[appState.rootKey.uppercased()] == pc)
                    highlights.append(
                        FretHighlightModel(
                            stringNum: stringNum,
                            fret: fret,
                            label: noteName,
                            isRoot: isRoot
                        )
                    )
                }
            }
        }
        return highlights
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Master Fretboard Control Header
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tuning")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.gray)

                        LuxuryDropdown(
                            selection: $selectedTuning,
                            options: GuitarTuning.allCases.map {
                                LuxuryDropdownOption(value: $0, title: $0.rawValue)
                            },
                            minWidth: 210,
                            popoverWidth: 250
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CAGED Position")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.gray)

                        LuxuryDropdown(
                            selection: $selectedCAGED,
                            options: CAGEDForm.allCases.map {
                                LuxuryDropdownOption(value: $0, title: $0.rawValue)
                            },
                            minWidth: 160,
                            popoverWidth: 200
                        )
                    }

                    Spacer()

                    Button(action: { showGuideSheet = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                            Text("CAGED Guide")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .foregroundColor(Color.musicianIvory.opacity(0.85))
                        .background(Color.musicianSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8))
                    }
                    .studioPressable()

                    Button(action: strumOpenStrings) {
                        HStack(spacing: 6) {
                            Image(systemName: "guitars.fill")
                                .font(.system(size: 11))
                            Text("Strum Open")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .foregroundColor(Color.musicianEbony)
                        .background(Color.musicianGold)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .studioPressable()
                }
                .padding(14)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Scale Guide Bar
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { appState.guitarGuideEnabled },
                        set: { appState.guitarGuideEnabled = $0 }
                    )) {
                        Text("Scale Guide")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.musicianGold)

                    if appState.guitarGuideEnabled {
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
                                minWidth: 190,
                                popoverWidth: 250
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
                .padding(12)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(StudioMotion.cardGlide, value: appState.guitarGuideEnabled)

                // 15-Fret Interactive Neck
                NativeFretboardView(
                    highlights: activeHighlights,
                    title: "6-String Fretboard",
                    subtitle: "\(selectedTuning.rawValue) · \(selectedCAGED.rawValue)",
                    onPlayFret: { _, midi in
                        appState.playGuitar(midi: midi, velocity: 0.88, duration: 2.2)
                    }
                )
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .sheet(isPresented: $showGuideSheet) {
            fretboardGuideSheetContent
        }
    }

    private var fretboardGuideSheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fretboard & CAGED Guide")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                Spacer()
                Button(action: { showGuideSheet = false }) {
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Fret Inlay Markers")
                    .font(.system(size: 12.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.subdominantEmerald)
                Text("Single markers indicate frets 3, 5, 7, 9, and 15. The double marker at fret 12 is one octave above the open strings.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("The CAGED System")
                    .font(.system(size: 12.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.subdominantEmerald)
                Text("Connects five movable neck regions (C, A, G, E, D) across all 15 frets. Anchor roots on string 6 (E/G shapes) and string 5 (A/C shapes).")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(22)
        .frame(width: 460)
        .background(Color.musicianEbony)
        .preferredColorScheme(.dark)
    }
    
    private func strumOpenStrings() {
        let openNotes = selectedTuning.openMidiNotes
        for (index, midi) in openNotes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                self.appState.playGuitar(midi: midi, velocity: 0.85, duration: 2.4)
            }
        }
    }
}

