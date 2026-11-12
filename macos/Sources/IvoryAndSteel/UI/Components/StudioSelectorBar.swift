import SwiftUI

// MARK: - Studio Selection Models & Categories

public enum StudioInstrument: String, CaseIterable, Identifiable, Sendable {
    case piano = "Grand Piano"
    case guitar = "Acoustic Guitar"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .piano: return "pianokeys"
        case .guitar: return "guitars.fill"
        }
    }
}

public enum StudioViewMode: String, CaseIterable, Identifiable, Sendable {
    case diatonic = "Diatonic Suite"
    case scales = "Scales & Modes"
    case chords = "Chord Voicings"
    
    public var id: String { rawValue }
    
    public var shortTitle: String {
        switch self {
        case .diatonic: return "Diatonic"
        case .scales: return "Scales"
        case .chords: return "Chords"
        }
    }
    
    public var icon: String {
        switch self {
        case .diatonic: return "circle.grid.cross"
        case .scales: return "music.note.list"
        case .chords: return "sparkles"
        }
    }
}

public struct StudioScaleItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let category: Category
    
    public enum Category: String, CaseIterable, Sendable {
        case diatonic = "Diatonic Modes (Western Harmony)"
        case minorVariation = "Classical & Jazz Minor"
        case pentatonicBlues = "Pentatonic & Blues Soloing"
    }
    
    public init(id: String, name: String, category: Category) {
        self.id = id
        self.name = name
        self.category = category
    }
}

public struct StudioChordItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let category: Category
    
    public enum Category: String, CaseIterable, Sendable {
        case triads = "Triads (Fundamental Harmony)"
        case sevenths = "7th Chords (Jazz & Classical)"
        case extended = "Extended Chords (9th, 11th, 13th)"
    }
    
    public init(id: String, name: String, category: Category) {
        self.id = id
        self.name = name
        self.category = category
    }
}

public enum StudioPresets {
    public static let chromaticRoots = ["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"]
    
    public static let scales: [StudioScaleItem] = [
        // Diatonic Modes
        StudioScaleItem(id: "major", name: "Major Scale (Ionian)", category: .diatonic),
        StudioScaleItem(id: "dorian", name: "Dorian Mode", category: .diatonic),
        StudioScaleItem(id: "phrygian", name: "Phrygian Mode", category: .diatonic),
        StudioScaleItem(id: "lydian", name: "Lydian Mode", category: .diatonic),
        StudioScaleItem(id: "mixolydian", name: "Mixolydian Mode", category: .diatonic),
        StudioScaleItem(id: "natural_minor", name: "Natural Minor (Aeolian)", category: .diatonic),
        
        // Minor Variations
        StudioScaleItem(id: "harmonic_minor", name: "Harmonic Minor", category: .minorVariation),
        StudioScaleItem(id: "melodic_minor", name: "Melodic Minor (Jazz)", category: .minorVariation),
        
        // Pentatonic & Blues
        StudioScaleItem(id: "major_pentatonic", name: "Major Pentatonic", category: .pentatonicBlues),
        StudioScaleItem(id: "minor_pentatonic", name: "Minor Pentatonic", category: .pentatonicBlues),
        StudioScaleItem(id: "blues", name: "Blues Scale", category: .pentatonicBlues)
    ]
    
    public static let chords: [StudioChordItem] = [
        // Triads
        StudioChordItem(id: "major", name: "Major Triad", category: .triads),
        StudioChordItem(id: "minor", name: "Minor Triad", category: .triads),
        StudioChordItem(id: "diminished", name: "Diminished Triad", category: .triads),
        StudioChordItem(id: "augmented", name: "Augmented Triad", category: .triads),
        StudioChordItem(id: "sus4", name: "Suspended 4th (sus4)", category: .triads),
        
        // 7ths
        StudioChordItem(id: "dom7", name: "Dominant 7th", category: .sevenths),
        StudioChordItem(id: "maj7", name: "Major 7th", category: .sevenths),
        StudioChordItem(id: "m7", name: "Minor 7th", category: .sevenths),
        StudioChordItem(id: "m7b5", name: "Half-Diminished (m7♭5)", category: .sevenths),
        StudioChordItem(id: "dim7", name: "Diminished 7th", category: .sevenths),
        
        // Extended
        StudioChordItem(id: "9th", name: "Dominant 9th", category: .extended),
        StudioChordItem(id: "maj9", name: "Major 9th", category: .extended),
        StudioChordItem(id: "11th", name: "Dominant 11th", category: .extended),
        StudioChordItem(id: "13th", name: "Dominant 13th", category: .extended)
    ]
    
    public static let heroScaleChips = [
        (id: "major", label: "Major"),
        (id: "natural_minor", label: "Minor"),
        (id: "blues", label: "Blues"),
        (id: "dorian", label: "Dorian")
    ]
    
    public static let heroChordChips = [
        (id: "major", label: "Major"),
        (id: "minor", label: "Minor"),
        (id: "dom7", label: "7th"),
        (id: "maj7", label: "Maj7")
    ]
}

// MARK: - Single 42px Apple-Craft Control Strip

public struct StudioSelectorBar: View {
    @Binding public var instrument: StudioInstrument
    @Binding public var viewMode: StudioViewMode
    @Binding public var selectedRoot: String
    @Binding public var selectedScaleId: String
    @Binding public var selectedChordId: String
    
    public let onPlayAudition: (() -> Void)?
    
    public init(
        instrument: Binding<StudioInstrument>,
        viewMode: Binding<StudioViewMode>,
        selectedRoot: Binding<String>,
        selectedScaleId: Binding<String>,
        selectedChordId: Binding<String>,
        onPlayAudition: (() -> Void)? = nil
    ) {
        self._instrument = instrument
        self._viewMode = viewMode
        self._selectedRoot = selectedRoot
        self._selectedScaleId = selectedScaleId
        self._selectedChordId = selectedChordId
        self.onPlayAudition = onPlayAudition
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // 1. Instrument Switcher (Piano / Guitar)
            instrumentToggleGroup
            
            dividerLine
            
            // 2. View Mode Tabs (Diatonic / Scales / Chords - Unwrapped, zero truncation)
            viewModeToggleGroup
            
            dividerLine
            
            // 3. Root Key Selector Menu
            rootKeyPickerMenu
            
            dividerLine
            
            // 4. Contextual Menus & Steppers
            if viewMode == .scales {
                scaleGroupedMenu
                scaleAuditionSteppers
            } else if viewMode == .chords {
                chordGroupedMenu
                chordAuditionSteppers
            } else {
                diatonicSuiteBadge
            }
            
            Spacer(minLength: 4)
            
            // 5. Quick Chips (Clean neutral frosted buttons)
            heroQuickChips
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 18)
    }
    
    // MARK: - 1. Instrument Toggle Group
    
    private var instrumentToggleGroup: some View {
        HStack(spacing: 2) {
            ForEach(StudioInstrument.allCases) { inst in
                let isSelected = (instrument == inst)
                Button(action: { instrument = inst }) {
                    Image(systemName: inst.icon)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.musicianGold : Color.white.opacity(0.55))
                        .frame(width: 26, height: 26)
                        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("Switch to \(inst.rawValue)")
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
    
    // MARK: - 2. View Mode Toggle Group (Guaranteed Zero Truncation)
    
    private var viewModeToggleGroup: some View {
        HStack(spacing: 2) {
            ForEach(StudioViewMode.allCases) { mode in
                let isSelected = (viewMode == mode)
                Button(action: { viewMode = mode }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 9))
                        Text(mode.shortTitle)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(isSelected ? Color.musicianIvory : Color.white.opacity(0.55))
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(isSelected ? Color.white.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(isSelected ? Color.white.opacity(0.15) : Color.clear, lineWidth: 0.6)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
    
    // MARK: - 3. Root Key Picker Menu
    
    private var rootKeyPickerMenu: some View {
        Menu {
            ForEach(StudioPresets.chromaticRoots, id: \.self) { root in
                Button(action: { selectedRoot = root }) {
                    HStack {
                        Text("Key of \(root)")
                        if selectedRoot == root {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Key:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
                Text(selectedRoot.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯"))
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color.musicianGoldLight)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 7)
            .frame(height: 26)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - 4. Grouped Quality Menus (Scales / Chords / Diatonic)
    
    private var scaleGroupedMenu: some View {
        Menu {
            ForEach(StudioScaleItem.Category.allCases, id: \.rawValue) { category in
                Section(category.rawValue) {
                    ForEach(StudioPresets.scales.filter { $0.category == category }) { item in
                        Button(action: {
                            selectedScaleId = item.id
                            onPlayAudition?()
                        }) {
                            HStack {
                                Text(item.name)
                                if selectedScaleId == item.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(currentScaleName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.musicianIvory)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var chordGroupedMenu: some View {
        Menu {
            ForEach(StudioChordItem.Category.allCases, id: \.rawValue) { category in
                Section(category.rawValue) {
                    ForEach(StudioPresets.chords.filter { $0.category == category }) { item in
                        Button(action: {
                            selectedChordId = item.id
                            onPlayAudition?()
                        }) {
                            HStack {
                                Text(item.name)
                                if selectedChordId == item.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(currentChordName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.musicianIvory)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var diatonicSuiteBadge: some View {
        Text("I – ii – iii – IV – V – vi – vii°")
            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
            .foregroundColor(Color.musicianGoldLight.opacity(0.85))
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6))
            .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - Audition Steppers (◀ / ▶)
    
    private var scaleAuditionSteppers: some View {
        let allScales = StudioPresets.scales
        let currentIndex = allScales.firstIndex { $0.id == selectedScaleId } ?? 0
        
        return HStack(spacing: 2) {
            Button(action: {
                let prevIdx = (currentIndex - 1 + allScales.count) % allScales.count
                selectedScaleId = allScales[prevIdx].id
                onPlayAudition?()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 18, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Text("\(currentIndex + 1)/\(allScales.count)")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.5))
            
            Button(action: {
                let nextIdx = (currentIndex + 1) % allScales.count
                selectedScaleId = allScales[nextIdx].id
                onPlayAudition?()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 18, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 3)
        .frame(height: 26)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var chordAuditionSteppers: some View {
        let allChords = StudioPresets.chords
        let currentIndex = allChords.firstIndex { $0.id == selectedChordId } ?? 0
        
        return HStack(spacing: 2) {
            Button(action: {
                let prevIdx = (currentIndex - 1 + allChords.count) % allChords.count
                selectedChordId = allChords[prevIdx].id
                onPlayAudition?()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 18, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Text("\(currentIndex + 1)/\(allChords.count)")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.5))
            
            Button(action: {
                let nextIdx = (currentIndex + 1) % allChords.count
                selectedChordId = allChords[nextIdx].id
                onPlayAudition?()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 18, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 3)
        .frame(height: 26)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - 5. Hero Quick-Chips (Clean Neutral Frosted Glass Pills)
    
    private var heroQuickChips: some View {
        HStack(spacing: 4) {
            if viewMode == .scales {
                ForEach(StudioPresets.heroScaleChips, id: \.id) { chip in
                    let isSelected = (selectedScaleId == chip.id)
                    Button(action: {
                        selectedScaleId = chip.id
                        onPlayAudition?()
                    }) {
                        Text(chip.label)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Color.musicianEbony : Color.white.opacity(0.6))
                            .padding(.horizontal, 7)
                            .frame(height: 24)
                            .background(isSelected ? Color.musicianGold : Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isSelected ? Color.musicianGoldLight.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 0.6)
                            )
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                }
            } else if viewMode == .chords {
                ForEach(StudioPresets.heroChordChips, id: \.id) { chip in
                    let isSelected = (selectedChordId == chip.id)
                    Button(action: {
                        selectedChordId = chip.id
                        onPlayAudition?()
                    }) {
                        Text(chip.label)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Color.musicianEbony : Color.white.opacity(0.6))
                            .padding(.horizontal, 7)
                            .frame(height: 24)
                            .background(isSelected ? Color.musicianGold : Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isSelected ? Color.musicianGoldLight.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 0.6)
                            )
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
    
    private var currentScaleName: String {
        StudioPresets.scales.first { $0.id == selectedScaleId }?.name ?? "Major Scale"
    }
    
    private var currentChordName: String {
        StudioPresets.chords.first { $0.id == selectedChordId }?.name ?? "Major Triad"
    }
}

#Preview {
    StudioSelectorBar(
        instrument: .constant(.piano),
        viewMode: .constant(.scales),
        selectedRoot: .constant("C"),
        selectedScaleId: .constant("major"),
        selectedChordId: .constant("major")
    )
    .frame(width: 900)
    .padding()
}
