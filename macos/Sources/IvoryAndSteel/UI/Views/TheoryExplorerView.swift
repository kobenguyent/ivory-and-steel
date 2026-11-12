import SwiftUI

/// Theory Explorer Studio View: 12-key selector, Diatonic Suite cards,
/// StudioSelectorBar, and embedded CircleOfFifthsView & NativePianoView / NativeFretboardView.
public struct TheoryExplorerView: View {
    @Environment(AppState.self) private var appState
    
    @State private var instrument: StudioInstrument = .piano
    @State private var viewMode: StudioViewMode = .diatonic
    @State private var showCircleOfFifths: Bool = true
    @State private var selectedDiatonicDegree: Int = 0
    
    private let theory = MusicTheoryEngine.shared
    
    public init() {}
    
    private var diatonicChords: [DiatonicChordModel] {
        theory.diatonicChords(for: appState.rootKey)
    }
    
    private var activeChord: DiatonicChordModel? {
        guard !diatonicChords.isEmpty, selectedDiatonicDegree < diatonicChords.count else {
            return diatonicChords.first
        }
        return diatonicChords[selectedDiatonicDegree]
    }
    
    private var activeNotesForPiano: [String] {
        if viewMode == .diatonic {
            return activeChord?.notes.map { "\($0)4" } ?? []
        } else if viewMode == .scales {
            let notes = theory.notes(forScale: appState.selectedScaleId, rootKey: appState.rootKey)
            return notes.map { "\($0)4" }
        } else {
            let chord = ChordDefinitions.allChords.first { $0.id == appState.selectedChordId } ?? ChordDefinitions.allChords[0]
            let rootMidi = theory.midiNote(for: "\(appState.rootKey)4")
            return chord.semitones.map { semitone in
                let noteMidi = rootMidi + semitone
                let pc = (noteMidi % 12)
                let name = KeyDefinitions.formatPitchName(pitchClass: pc, preferFlat: appState.preferFlat)
                let oct = (noteMidi / 12) - 1
                return "\(name)\(oct)"
            }
        }
    }
    
    private var activeFretHighlights: [FretHighlightModel] {
        let notes: [String]
        if viewMode == .diatonic {
            notes = activeChord?.notes ?? []
        } else if viewMode == .scales {
            notes = theory.notes(forScale: appState.selectedScaleId, rootKey: appState.rootKey)
        } else {
            let chord = ChordDefinitions.allChords.first { $0.id == appState.selectedChordId } ?? ChordDefinitions.allChords[0]
            let rootMidi = theory.midiNote(for: "\(appState.rootKey)4")
            notes = chord.semitones.map {
                KeyDefinitions.formatPitchName(pitchClass: (rootMidi + $0) % 12, preferFlat: appState.preferFlat)
            }
        }
        
        let standardTuningNotes = [40, 45, 50, 55, 59, 64] // E2, A2, D3, G3, B3, E4
        var results: [FretHighlightModel] = []
        
        for (stringIdx, openMidi) in standardTuningNotes.enumerated() {
            let stringNum = 6 - stringIdx // 6 = Low E, 1 = High E
            for fret in 0...15 {
                let fretMidi = openMidi + fret
                let pc = fretMidi % 12
                let noteName = KeyDefinitions.formatPitchName(pitchClass: pc, preferFlat: appState.preferFlat)
                if notes.contains(where: { KeyDefinitions.rootPitchMap[$0.uppercased()] == pc }) {
                    let isRoot = (KeyDefinitions.rootPitchMap[appState.rootKey.uppercased()] == pc)
                    results.append(FretHighlightModel(stringNum: stringNum, fret: fret, label: noteName, isRoot: isRoot))
                }
            }
        }
        return results
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Top Control Deck: StudioSelectorBar (Apple-Craft Segmented Strip)
                StudioSelectorBar(
                    instrument: $instrument,
                    viewMode: $viewMode,
                    selectedRoot: Binding(
                        get: { appState.rootKey },
                        set: { appState.setRootKey($0) }
                    ),
                    selectedScaleId: Binding(
                        get: { appState.selectedScaleId },
                        set: { appState.setScaleId($0) }
                    ),
                    selectedChordId: Binding(
                        get: { appState.selectedChordId },
                        set: { appState.setChordId($0) }
                    ),
                    onPlayAudition: {
                        appState.playChordVoicing(notes: activeNotesForPiano, isGuitar: (instrument == .guitar))
                    }
                )
                
                // 2. Circle of Fifths Section (Seamless Apple-Tier Deck, No Nested Card Borders)
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "safari.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.musicianGold)
                            
                            Text("Circle of Fifths Compass")
                                .font(.system(size: 14.5, weight: .bold, design: .serif))
                                .foregroundColor(Color.musicianIvory)
                            
                            Text("Harmonic Astrolabe")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.musicianGoldLight.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                showCircleOfFifths.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(showCircleOfFifths ? "Collapse" : "Expand")
                                Image(systemName: showCircleOfFifths ? "chevron.up" : "chevron.down")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.musicianSurface)
                    
                    if showCircleOfFifths {
                        CircleOfFifthsView(
                            selectedRoot: appState.rootKey,
                            onSelectKey: { newKey in
                                appState.setRootKey(newKey)
                            },
                            onAuditionTone: { tone in
                                let midi = theory.midiNote(for: "\(tone)4")
                                appState.playPiano(midi: midi)
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // 3. Diatonic Suite 7-Chord Cards (Zero-Truncation Luxury Row)
                if viewMode == .diatonic {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            HStack(spacing: 6) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.musicianGold)
                                
                                Text("Diatonic Harmony Suite for \(appState.rootKey) Major")
                                    .font(.system(size: 14.5, weight: .bold, design: .serif))
                                    .foregroundColor(Color.musicianIvory)
                            }
                            
                            Spacer()
                            
                            Text("7 Parent Triads & 7ths")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(diatonicChords.enumerated()), id: \.offset) { index, chord in
                                    DiatonicChordCard(
                                        chord: chord,
                                        isSelected: selectedDiatonicDegree == index,
                                        onSelect: {
                                            selectedDiatonicDegree = index
                                            appState.playChordVoicing(notes: chord.notes.map { "\($0)4" }, isGuitar: (instrument == .guitar))
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // 4. Active Instrument Visualization (Piano or Guitar)
                if instrument == .piano {
                    NativePianoView(
                        highlightedNotes: activeNotesForPiano,
                        rootNote: appState.rootKey,
                        intervals: activeChord?.notes ?? [],
                        preferFlat: appState.preferFlat,
                        title: "Acoustic Grand Voice Leading: \(viewMode.shortTitle)",
                        subtitle: "Harmonized chord tones illuminated across C4–C6 range with physical string resonance",
                        onPlayNote: { noteName, midi in
                            appState.playPiano(midi: midi)
                        }
                    )
                } else {
                    NativeFretboardView(
                        highlights: activeFretHighlights,
                        title: "6-String Guitar Voicing: \(viewMode.shortTitle)",
                        subtitle: "Harmonized intervals illuminated across 15 frets with logarithmic spacing",
                        onPlayFret: { noteName, midi in
                            appState.playGuitar(midi: midi)
                        }
                    )
                }
            }
            .padding(18)
        }
        .background(Color.musicianEbony)
    }
}

// MARK: - Diatonic Chord Card (Apple-Craft Zero Truncation)

private struct DiatonicChordCard: View {
    let chord: DiatonicChordModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                cardHeader
                cardBody
                Spacer(minLength: 2)
                cardNotes
            }
            .padding(12)
            .frame(width: 154, height: 118)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(cardBorder)
            .offset(y: isHovered && !isSelected ? -2 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
    
    @ViewBuilder
    private var cardHeader: some View {
        HStack(alignment: .center) {
            Text(chord.degree)
                .font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundColor(chord.isTonic ? Color.musicianGold : Color.musicianIvory)
            
            Spacer()
            
            if chord.isTonic {
                HarmonicRoleBadge("ROOT", isRoot: true, size: .compact)
            } else if chord.isDominant {
                HarmonicRoleBadge("DOMINANT", isRoot: false, size: .compact)
            } else {
                Text(chord.quality.uppercased())
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.55))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Capsule())
            }
        }
    }
    
    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chord.root)\(shorthandSymbol(for: chord.quality))")
                .font(.system(size: 15.5, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)
            
            Text(cleanQualityName(for: chord.quality))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
    
    @ViewBuilder
    private var cardNotes: some View {
        HStack(spacing: 3) {
            ForEach(chord.notes, id: \.self) { note in
                Text(note)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.musicianGold.opacity(0.2) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 3.5))
                    .foregroundColor(isSelected ? Color.musicianGoldLight : Color.white.opacity(0.85))
            }
        }
    }
    
    private var cardBackground: some View {
        Group {
            if isSelected {
                Color.musicianGold.opacity(0.12)
            } else if isHovered {
                Color.white.opacity(0.06)
            } else {
                Color.white.opacity(0.035)
            }
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                isSelected
                    ? Color.musicianGold.opacity(0.8)
                    : (isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.06)),
                lineWidth: isSelected ? 1.0 : 0.6
            )
    }
    
    private func shorthandSymbol(for quality: String) -> String {
        switch quality.lowercased() {
        case "major 7th", "major": return "maj7"
        case "minor 7th", "minor": return "m7"
        case "dominant 7th": return "7"
        case "half-diminished 7th", "half-diminished": return "m7♭5"
        case "diminished 7th", "diminished": return "dim7"
        default: return ""
        }
    }
    
    private func cleanQualityName(for quality: String) -> String {
        switch quality.lowercased() {
        case "major 7th": return "Major 7th"
        case "minor 7th": return "Minor 7th"
        case "dominant 7th": return "Dominant 7th"
        case "half-diminished 7th": return "Half-Diminished"
        case "diminished 7th": return "Diminished 7th"
        default: return quality
        }
    }
}
