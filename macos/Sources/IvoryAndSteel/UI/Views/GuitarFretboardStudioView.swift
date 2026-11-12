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
    @State private var guideRoot: String = "C"
    @State private var guideScale: String = "minor_pentatonic"
    @State private var isScaleGuideActive: Bool = true
    
    private let theory = MusicTheoryEngine.shared
    
    public init() {}
    
    private var activeHighlights: [FretHighlightModel] {
        guard isScaleGuideActive else { return [] }
        let scaleNotes = theory.notes(forScale: guideScale, rootKey: guideRoot)
        let openNotes = selectedTuning.openMidiNotes
        var highlights: [FretHighlightModel] = []
        
        for (idx, openMidi) in openNotes.enumerated() {
            let stringNum = 6 - idx // 6 = Low, 1 = High
            for fret in 0...15 {
                // If CAGED form is selected and fret is outside range, filter it
                if let range = selectedCAGED.fretRange, !range.contains(fret), fret != 0 {
                    continue
                }
                
                let midi = openMidi + fret
                let pc = midi % 12
                let noteName = KeyDefinitions.formatPitchName(pitchClass: pc, preferFlat: appState.preferFlat)
                
                if scaleNotes.contains(where: { KeyDefinitions.rootPitchMap[$0.uppercased()] == pc }) {
                    let isRoot = (KeyDefinitions.rootPitchMap[guideRoot.uppercased()] == pc)
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
            VStack(spacing: 20) {
                // Master Fretboard Control Header
                HStack(spacing: 16) {
                    // Tuning Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tuning System:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.gray)
                        
                        Picker("Tuning", selection: $selectedTuning) {
                            ForEach(GuitarTuning.allCases) { tuning in
                                Text(tuning.rawValue).tag(tuning)
                            }
                        }
                        .frame(width: 220)
                    }
                    
                    // CAGED Shape Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CAGED Box System:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.gray)
                        
                        Picker("CAGED", selection: $selectedCAGED) {
                            ForEach(CAGEDForm.allCases) { form in
                                Text(form.rawValue).tag(form)
                            }
                        }
                        .frame(width: 160)
                    }
                    
                    Spacer()
                    
                    // Strum Open Strings Button
                    Button(action: strumOpenStrings) {
                        HStack(spacing: 6) {
                            Image(systemName: "guitars.fill")
                                .font(.system(size: 11))
                            Text("Strum Open Strings")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .foregroundColor(Color.musicianEbony)
                        .background(Color.musicianGold)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // 12-Key Fretboard Scale Guide Bar
                HStack(spacing: 12) {
                    Toggle(isOn: $isScaleGuideActive) {
                        Label("Fretboard Scale Boxes", systemImage: "circle.grid.3x3.fill")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.musicianGold)
                    
                    if isScaleGuideActive {
                        Picker("Key", selection: $guideRoot) {
                            ForEach(KeyDefinitions.chromaticRoots, id: \.self) { root in
                                Text("Key of \(root)").tag(root)
                            }
                        }
                        .frame(width: 140)
                        
                        Picker("Scale", selection: $guideScale) {
                            ForEach(ScaleDefinitions.allScales) { scale in
                                Text(scale.name).tag(scale.id)
                            }
                        }
                        .frame(width: 200)
                    }
                    
                    Spacer()
                    
                    Text("\(activeHighlights.count) Active Fret Positions")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.musicianGoldLight)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 15-Fret Interactive Neck
                NativeFretboardView(
                    highlights: activeHighlights,
                    title: "Boutique Luthier 6-String Rosewood Neck",
                    subtitle: "\(selectedTuning.rawValue) · \(selectedCAGED.rawValue) · 15 Frets with Logarithmic Spacing",
                    onPlayFret: { noteName, midi in
                        appState.playGuitar(midi: midi, velocity: 0.88, duration: 2.2)
                    }
                )
                
                // Fretboard Landmarks & Acoustic Guidance
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pearloid Inlay Landmarks")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.subdominantEmerald)
                        
                        Text("• Single mother-of-pearl dots at frets 3, 5, 7, 9, and 15.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                        
                        Text("• Double dot at fret 12 marks the exact physical octave center where open string frequency doubles (2x).")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("The CAGED Harmonization Framework")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.subdominantEmerald)
                        
                        Text("• Connects 5 primary open chord forms across the entire neck.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                        
                        Text("• Anchor root notes on String 6 (E-shape, G-shape) and String 5 (A-shape, C-shape) to navigate movable barres.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
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

