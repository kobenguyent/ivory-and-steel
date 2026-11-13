import SwiftUI

/// Theory Explorer Studio View: 12-key selector, Diatonic Suite cards,
/// dedicated Chord & Scale Studio Inspectors + Library Browsers,
/// CircleOfFifthsView, and real-time NativePianoView / NativeFretboardView.
public struct TheoryExplorerView: View {
    @Environment(AppState.self) private var appState
    
    @State private var instrument: StudioInstrument = .piano
    @State private var viewMode: StudioViewMode = .diatonic
    @State private var showCircleOfFifths: Bool = true
    @State private var selectedDiatonicDegree: Int = 0
    @State private var chordInversion: Int = 0
    @State private var chordFilter: ChordLibraryFilter = .all
    @State private var scaleFilter: ScaleLibraryFilter = .all
    @Namespace private var explorerNS
    
    private let theory = MusicTheoryEngine.shared
    
    public init() {}
    
    private enum ChordLibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case triads = "Triads & Sus"
        case sevenths = "7ths"
        case extended = "Extended"
        
        var id: String { rawValue }
        
        var mappedCategory: StudioChordItem.Category? {
            switch self {
            case .all: return nil
            case .triads: return .triads
            case .sevenths: return .sevenths
            case .extended: return .extended
            }
        }
    }
    
    private enum ScaleLibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case diatonic = "Modes"
        case minor = "Minor"
        case pentatonic = "Pentatonic & Blues"
        
        var id: String { rawValue }
        
        var mappedCategory: StudioScaleItem.Category? {
            switch self {
            case .all: return nil
            case .diatonic: return .diatonic
            case .minor: return .minorVariation
            case .pentatonic: return .pentatonicBlues
            }
        }
    }
    
    // MARK: - Derived Harmonic Models
    
    private var diatonicChords: [DiatonicChordModel] {
        theory.diatonicChords(for: appState.rootKey)
    }
    
    private var activeDiatonicChord: DiatonicChordModel? {
        guard !diatonicChords.isEmpty, selectedDiatonicDegree < diatonicChords.count else {
            return diatonicChords.first
        }
        return diatonicChords[selectedDiatonicDegree]
    }
    
    private var activeChordModel: ChordQualityModel {
        ChordDefinitions.chord(for: appState.selectedChordId) ?? ChordDefinitions.allChords[0]
    }
    
    private var activeScaleModel: ScaleQualityModel {
        ScaleDefinitions.scale(for: appState.selectedScaleId) ?? ScaleDefinitions.allScales[0]
    }
    
    private var activeVoicingTones: [(note: String, intervalLabel: String)] {
        theory.chordVoicing(root: appState.rootKey, qualityId: activeChordModel.id, inversion: chordInversion)
    }
    
    private var activeScaleNotes: [String] {
        theory.notes(forScale: activeScaleModel.id, rootKey: appState.rootKey)
    }
    
    private var activeRootForPiano: String {
        if viewMode == .diatonic {
            return activeDiatonicChord?.root ?? appState.rootKey
        }
        return appState.rootKey
    }
    
    private var activeNotesForPiano: [String] {
        if viewMode == .diatonic {
            // DiatonicChordModel.notes already include scientific octaves (e.g., ["C4", "E4", "G4", "B4"])
            return activeDiatonicChord?.notes ?? []
        } else if viewMode == .scales {
            // MusicTheoryEngine.notes(forScale:rootKey:) already returns ascending C4..C5 scientific octaves
            return activeScaleNotes
        } else {
            return activeVoicingTones.map { $0.note }
        }
    }
    
    private var activeSelectionLabel: String {
        switch viewMode {
        case .diatonic:
            if let chord = activeDiatonicChord {
                return "\(chord.degree) · \(formattedSymbol(chord.root)) \(chord.quality)"
            }
            return "\(formattedSymbol(appState.rootKey)) Major"
        case .chords:
            return "\(formattedSymbol(appState.rootKey))\(prettySymbol(activeChordModel.symbol)) · \(activeChordModel.name)"
        case .scales:
            return "\(formattedSymbol(appState.rootKey)) \(activeScaleModel.name)"
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 1. Top Control Deck: StudioSelectorBar
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
                        playCurrentSelection()
                    }
                )
                
                // 2. Circle of Fifths Section (Expanded in Diatonic; collapsed by default in Chords/Scales)
                circleOfFifthsSection
                
                // 3. Mode-Specific Workspace (Diatonic / Chord Studio / Scale Studio)
                Group {
                    if viewMode == .diatonic {
                        diatonicSection
                            .transition(.studioSection)
                    } else if viewMode == .chords {
                        chordStudioSection
                            .transition(.studioSection)
                    } else {
                        scaleStudioSection
                            .transition(.studioSection)
                    }
                }
                .animation(StudioMotion.cardGlide, value: viewMode)
                
                // 4. Compact Voicing Summary & Studio Handoff Bar
                activeVoicingHandoffBar
                    .transition(.studioSection)
            }
            .padding(18)
        }
        .background(Color.musicianEbony)
        .onChange(of: viewMode) { _, newMode in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                showCircleOfFifths = (newMode == .diatonic)
            }
        }
        .onChange(of: appState.selectedChordId) { _, _ in
            chordInversion = 0
        }
    }
    
    // MARK: - Sections
    
    private var activeVoicingHandoffBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activeSelectionLabel)
                    .font(.system(size: 13.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Text(activeNotesForPiano.map { formattedSymbol($0) }.joined(separator: " · "))
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button(action: playCurrentSelection) {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Audition")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(Color.musicianIvory)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7))
            }
            .studioPressable()

            Button(action: {
                let scaleArg = (viewMode == .scales) ? activeScaleModel.id : nil
                let voicingArg = (viewMode == .scales) ? nil : activeNotesForPiano
                appState.openInPianoStudio(root: activeRootForPiano, scaleId: scaleArg, voicingNotes: voicingArg)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "pianokeys")
                        .font(.system(size: 10.5))
                    Text("Open in Piano Studio")
                        .font(.system(size: 11.5, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9.5, weight: .bold))
                }
                .foregroundColor(Color.musicianEbony)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(LinearGradient.goldGlow)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .studioPressable()

            Button(action: {
                let scaleArg = (viewMode == .scales) ? activeScaleModel.id : nil
                let voicingArg = (viewMode == .scales) ? nil : activeNotesForPiano
                appState.openInGuitarStudio(root: activeRootForPiano, scaleId: scaleArg, voicingNotes: voicingArg)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "guitars")
                        .font(.system(size: 10.5))
                    Text("Guitar Studio")
                        .font(.system(size: 11.5, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9.5, weight: .bold))
                }
                .foregroundColor(Color.subdominantEmerald)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color.subdominantEmerald.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.subdominantEmerald.opacity(0.28), lineWidth: 0.8))
            }
            .studioPressable()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8))
    }

    private var circleOfFifthsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Circle of Fifths")
                    .font(.system(size: 14.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Spacer()
                
                Button(action: {
                    withAnimation(StudioMotion.cardGlide) {
                        showCircleOfFifths.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(showCircleOfFifths ? "Collapse" : "Expand")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showCircleOfFifths ? 180 : 0))
                            .animation(StudioMotion.snappyControl, value: showCircleOfFifths)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.65))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Capsule())
                }
                .studioPressable()
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
                .transition(.studioSection)
            }
        }
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var diatonicSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Diatonic Chords in \(formattedSymbol(appState.rootKey)) Major")
                    .font(.system(size: 14.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(diatonicChords.enumerated()), id: \.offset) { index, chord in
                        DiatonicChordCard(
                            chord: chord,
                            isSelected: selectedDiatonicDegree == index,
                            onSelect: {
                                withAnimation(StudioMotion.snappyControl) {
                                    selectedDiatonicDegree = index
                                }
                                appState.playChordVoicing(notes: chord.notes, isGuitar: (instrument == .guitar))
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var chordStudioSection: some View {
        let chord = activeChordModel
        let tones = activeVoicingTones
        let maxInversions = min(4, max(1, chord.semitones.count))
        let filteredItems = StudioPresets.chords.filter { item in
            guard let targetCat = chordFilter.mappedCategory else { return true }
            return item.category == targetCat
        }

        return VStack(alignment: .leading, spacing: 14) {
            // A. Chord Inspector Hero Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    // Left: Symbol, Name & Character
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(formattedSymbol(appState.rootKey))\(prettySymbol(chord.symbol))")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(Color.musicianGold)

                            Text("\(formattedSymbol(appState.rootKey)) \(chord.name)")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(Color.musicianIvory)
                        }
                        
                        Text(chord.description)
                            .font(.system(size: 12.5))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Right: Audition Actions & Voicing Inversion Picker
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: {
                                appState.playChordVoicing(notes: tones.map { $0.note }, isGuitar: (instrument == .guitar))
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10))
                                    Text("Play Chord")
                                        .font(.system(size: 11.5, weight: .bold))
                                }
                                .foregroundColor(Color.musicianEbony)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.musicianGold)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .studioPressable()
                            
                            Button(action: {
                                appState.playChordVoicing(
                                    notes: tones.map { $0.note },
                                    isGuitar: (instrument == .guitar),
                                    stepDelay: 0.24
                                )
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 10))
                                    Text("Arpeggio")
                                        .font(.system(size: 11.5, weight: .semibold))
                                }
                                .foregroundColor(Color.musicianIvory)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                            }
                            .studioPressable()
                        }
                        
                        // Inversion Selector (Root, 1st Inv, 2nd Inv, 3rd Inv)
                        HStack(spacing: 4) {
                            Text("Voicing:")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.45))
                            
                            HStack(spacing: 2) {
                                ForEach(0..<maxInversions, id: \.self) { inv in
                                    let isSelected = (chordInversion == inv)
                                    Button(action: {
                                        withAnimation(StudioMotion.snappyControl) {
                                            chordInversion = inv
                                        }
                                        let nextNotes = theory.chordVoicing(root: appState.rootKey, qualityId: chord.id, inversion: inv).map { $0.note }
                                        appState.playChordVoicing(notes: nextNotes, isGuitar: (instrument == .guitar))
                                    }) {
                                        Text(inversionTitle(inv))
                                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? Color.musicianGoldLight : Color.white.opacity(0.6))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background {
                                                if isSelected {
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(Color.musicianGold.opacity(0.18))
                                                        .matchedGeometryEffect(id: "chord_inversion_pill", in: explorerNS)
                                                }
                                            }
                                    }
                                    .studioPressable()
                                }
                            }
                            .padding(2)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.06))
                
                // Interactive Tone Breakdown Strip
                VStack(alignment: .leading, spacing: 7) {
                    Text("CHORD TONES — CLICK ANY NOTE TO HEAR ITS INTERVAL")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.45))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(tones.enumerated()), id: \.offset) { _, tone in
                                let shortDeg = extractShortDegree(tone.intervalLabel)
                                let roleName = stripDegreeParentheses(tone.intervalLabel)
                                let isRootTone = shortDeg == "1"
                                
                                Button(action: { playSingleTone(tone.note) }) {
                                    HStack(spacing: 8) {
                                        Text(shortDeg)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(isRootTone ? Color.musicianEbony : Color.musicianGoldLight)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(isRootTone ? Color.musicianGold : Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(formattedSymbol(tone.note))
                                                .font(.system(size: 13, weight: .bold, design: .serif))
                                                .foregroundColor(Color.musicianIvory)
                                            Text(roleName)
                                                .font(.system(size: 9.5, weight: .medium))
                                                .foregroundColor(Color.white.opacity(0.55))
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(isRootTone ? Color.musicianGold.opacity(0.1) : Color.white.opacity(0.035))
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9)
                                            .strokeBorder(isRootTone ? Color.musicianGold.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.musicianCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            
            // B. Visual Chord Library Strip
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Chord Library in \(formattedSymbol(appState.rootKey))")
                        .font(.system(size: 14.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)

                    Spacer()
                    
                    // Category Filter Pills
                    HStack(spacing: 4) {
                        ForEach(ChordLibraryFilter.allCases) { filter in
                            let isSelected = (chordFilter == filter)
                            Button(action: {
                                withAnimation(StudioMotion.snappyControl) {
                                    chordFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Color.musicianEbony : Color.white.opacity(0.65))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background {
                                        if isSelected {
                                            Capsule()
                                                .fill(Color.musicianGold)
                                                .matchedGeometryEffect(id: "chord_filter_pill", in: explorerNS)
                                        } else {
                                            Capsule()
                                                .fill(Color.white.opacity(0.04))
                                        }
                                    }
                            }
                            .studioPressable()
                        }
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            if let model = ChordDefinitions.chord(for: item.id) {
                                let isSelected = (activeChordModel.id == model.id)
                                ChordLibraryCard(
                                    rootKey: appState.rootKey,
                                    chord: model,
                                    isSelected: isSelected,
                                    onSelect: {
                                        withAnimation(StudioMotion.snappyControl) {
                                            appState.setChordId(model.id)
                                            chordInversion = 0
                                        }
                                        let nextNotes = theory.chordVoicing(root: appState.rootKey, qualityId: model.id, inversion: 0).map { $0.note }
                                        appState.playChordVoicing(notes: nextNotes, isGuitar: (instrument == .guitar))
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(StudioMotion.cardGlide, value: chordFilter)
                }
            }
        }
    }
    
    private var scaleStudioSection: some View {
        let scale = activeScaleModel
        let notes = activeScaleNotes
        let filteredScales = StudioPresets.scales.filter { item in
            guard let targetCat = scaleFilter.mappedCategory else { return true }
            return item.category == targetCat
        }
        
        return VStack(alignment: .leading, spacing: 14) {
            // A. Scale Inspector Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(formattedSymbol(appState.rootKey)) \(scale.name)")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)

                        Text(scale.description)
                            .font(.system(size: 12.5))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer(minLength: 8)
                    
                    Button(action: {
                        appState.playChordVoicing(notes: notes, isGuitar: (instrument == .guitar), stepDelay: 0.22)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text("Play Scale")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(Color.musicianEbony)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.musicianGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider().background(Color.white.opacity(0.06))
                
                VStack(alignment: .leading, spacing: 7) {
                    Text("SCALE DEGREES — CLICK ANY TONE TO HEAR IT")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(Color.white.opacity(0.45))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(notes.enumerated()), id: \.offset) { idx, note in
                                let deg = idx < scale.intervalLabels.count ? formattedSymbol(scale.intervalLabels[idx]) : "\(idx + 1)"
                                let isRootTone = (deg == "1" || deg == "8")
                                Button(action: { playSingleTone(note) }) {
                                    HStack(spacing: 6) {
                                        Text(deg)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(isRootTone ? Color.musicianEbony : Color.musicianGoldLight)
                                            .padding(.horizontal, 5.5)
                                            .padding(.vertical, 2.5)
                                            .background(isRootTone ? Color.musicianGold : Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 4.5))
                                        
                                        Text(formattedSymbol(note))
                                            .font(.system(size: 12.5, weight: .bold, design: .serif))
                                            .foregroundColor(Color.musicianIvory)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(isRootTone ? Color.musicianGold.opacity(0.1) : Color.white.opacity(0.035))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(isRootTone ? Color.musicianGold.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.7)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.musicianCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            
            // B. Visual Scale Library Strip
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.musicianGold)
                        
                        Text("Scales & Modes in \(formattedSymbol(appState.rootKey))")
                            .font(.system(size: 14.5, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(ScaleLibraryFilter.allCases) { filter in
                            let isSelected = (scaleFilter == filter)
                            Button(action: {
                                withAnimation(StudioMotion.snappyControl) {
                                    scaleFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Color.musicianEbony : Color.white.opacity(0.65))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background {
                                        if isSelected {
                                            Capsule()
                                                .fill(Color.musicianGold)
                                                .matchedGeometryEffect(id: "scale_filter_pill", in: explorerNS)
                                        } else {
                                            Capsule()
                                                .fill(Color.white.opacity(0.04))
                                        }
                                    }
                            }
                            .studioPressable()
                        }
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filteredScales) { item in
                            if let model = ScaleDefinitions.scale(for: item.id) {
                                let isSelected = (activeScaleModel.id == model.id)
                                ScaleLibraryCard(
                                    rootKey: appState.rootKey,
                                    scale: model,
                                    isSelected: isSelected,
                                    onSelect: {
                                        appState.setScaleId(model.id)
                                        let nextNotes = theory.notes(forScale: model.id, rootKey: appState.rootKey)
                                        appState.playChordVoicing(notes: nextNotes, isGuitar: (instrument == .guitar), stepDelay: 0.22)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Playback & Formatting Helpers
    
    private func playCurrentSelection() {
        if viewMode == .scales {
            appState.playChordVoicing(notes: activeNotesForPiano, isGuitar: (instrument == .guitar), stepDelay: 0.22)
        } else {
            appState.playChordVoicing(notes: activeNotesForPiano, isGuitar: (instrument == .guitar))
        }
    }
    
    private func playSingleTone(_ note: String) {
        let midi = theory.midiNote(for: note)
        if instrument == .guitar {
            appState.playGuitar(midi: midi, velocity: 0.85, duration: 2.0)
        } else {
            appState.playPiano(midi: midi, velocity: 0.82, duration: 1.6)
        }
    }
    
    private func inversionTitle(_ index: Int) -> String {
        switch index {
        case 0: return "Root Pos"
        case 1: return "1st Inv"
        case 2: return "2nd Inv"
        default: return "3rd Inv"
        }
    }
    
    private func extractShortDegree(_ intervalLabel: String) -> String {
        if let open = intervalLabel.lastIndex(of: "("), let close = intervalLabel.lastIndex(of: ")"), open < close {
            return formattedSymbol(String(intervalLabel[intervalLabel.index(after: open)..<close]))
        }
        return formattedSymbol(intervalLabel)
    }
    
    private func stripDegreeParentheses(_ intervalLabel: String) -> String {
        if let open = intervalLabel.lastIndex(of: "(") {
            return String(intervalLabel[..<open]).trimmingCharacters(in: .whitespaces)
        }
        return intervalLabel
    }
    
    private func prettySymbol(_ symbol: String) -> String {
        symbol.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯")
    }
    
    private func formattedSymbol(_ raw: String) -> String {
        var out = ""
        for (i, ch) in raw.enumerated() {
            if i > 0 && ch == "b" {
                out.append("♭")
            } else if ch == "#" {
                out.append("♯")
            } else if i == 0 && ch == "b" && raw.count <= 3 {
                out.append("♭")
            } else {
                out.append(ch)
            }
        }
        return out
    }
}

// MARK: - Diatonic Chord Card

private struct DiatonicChordCard: View {
    let chord: DiatonicChordModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chord.degree)
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundColor(chord.isTonic ? Color.musicianGold : Color.musicianIvory)

                    Spacer()

                    if chord.isTonic {
                        Text("Tonic")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.musicianGold)
                    } else if chord.isDominant {
                        Text("Dominant")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.gray)
                    }
                }

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

                Spacer(minLength: 2)

                Text(chord.notes.joined(separator: " · "))
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? Color.musicianGoldLight : Color.white.opacity(0.65))
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 154, height: 112)
            .background(isSelected ? Color.musicianGold.opacity(0.12) : (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.035)))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected
                            ? Color.musicianGold.opacity(0.8)
                            : (isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.06)),
                        lineWidth: isSelected ? 1.0 : 0.6
                    )
            )
            .offset(y: isHovered && !isSelected ? -2 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
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

// MARK: - Chord Library Card

private struct ChordLibraryCard: View {
    let rootKey: String
    let chord: ChordQualityModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var displayTitle: String {
        let root = rootKey.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯")
        let sym = chord.symbol.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯")
        return "\(root)\(sym)"
    }
    
    private var formulaPreview: String {
        chord.intervalLabels.map { label in
            if let open = label.lastIndex(of: "("), let close = label.lastIndex(of: ")"), open < close {
                return String(label[label.index(after: open)..<close]).replacingOccurrences(of: "b", with: "♭")
            }
            return label
        }
        .joined(separator: " ")
    }
    
    private var cardBackgroundColor: Color {
        if isSelected {
            return Color.musicianGold.opacity(0.12)
        }
        return isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.035)
    }

    private var cardBorderColor: Color {
        if isSelected {
            return Color.musicianGold.opacity(0.85)
        }
        return isHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.06)
    }

    @ViewBuilder
    private var cardLabelContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(displayTitle)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(isSelected ? Color.musicianGold : Color.musicianIvory)

            Text(chord.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 2)

            Text(formulaPreview)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundColor(isSelected ? Color.musicianGoldLight : Color.gray)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 152, height: 96, alignment: .leading)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(cardBorderColor, lineWidth: isSelected ? 1.0 : 0.6)
        )
        .offset(y: isHovered && !isSelected ? -2 : 0)
    }

    var body: some View {
        Button(action: onSelect) {
            cardLabelContent
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Scale Library Card

private struct ScaleLibraryCard: View {
    let rootKey: String
    let scale: ScaleQualityModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var formulaPreview: String {
        Array(scale.intervalLabels.dropLast())
            .joined(separator: " · ")
            .replacingOccurrences(of: "b", with: "♭")
    }
    
    private var cardBackgroundColor: Color {
        if isSelected { return Color.musicianGold.opacity(0.12) }
        return isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.035)
    }
    
    private var cardBorderColor: Color {
        if isSelected { return Color.musicianGold.opacity(0.85) }
        return isHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.06)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 5) {
                Text(scale.category.capitalized)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? Color.musicianGoldLight : Color.gray)

                Text(scale.name)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(isSelected ? Color.musicianGold : Color.musicianIvory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 2)

                Text(formulaPreview)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? Color.musicianGoldLight : Color.gray)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 178, height: 92, alignment: .leading)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(cardBorderColor, lineWidth: isSelected ? 1.0 : 0.6)
            )
            .offset(y: isHovered && !isSelected ? -2 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
