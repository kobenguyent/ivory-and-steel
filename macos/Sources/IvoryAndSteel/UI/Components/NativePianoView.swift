import SwiftUI

// MARK: - Piano Key Definition Model

public struct PianoKeyModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let note: String
    public let isBlack: Bool
    public let label: String
    public let flatLabel: String?
    public let keyTrigger: String?
    public let offsetPercent: Double? // For black key absolute positioning (0.0 to 100.0)
    public let midiNote: Int
    
    public init(
        note: String,
        isBlack: Bool,
        label: String,
        flatLabel: String? = nil,
        keyTrigger: String? = nil,
        offsetPercent: Double? = nil,
        midiNote: Int
    ) {
        self.id = note
        self.note = note
        self.isBlack = isBlack
        self.label = label
        self.flatLabel = flatLabel
        self.keyTrigger = keyTrigger
        self.offsetPercent = offsetPercent
        self.midiNote = midiNote
    }
}

// MARK: - Piano Range: 2 Octaves (15 White Keys C4..C6 + 10 Black Keys)

public enum PianoGeometry {
    public static let whiteKeyCount: Int = 15
    public static let octave4WhiteCount: Int = 7
    public static let octave4WidthPercent: Double = 46.66667 // (7.0 / 15.0) * 100.0
    public static let blackKeyWidthPercent: Double = 4.2
    public static let blackKeyHeightRatio: CGFloat = 0.62
    
    public static let keys: [PianoKeyModel] = [
        // Octave 4
        PianoKeyModel(note: "C4", isBlack: false, label: "C4", keyTrigger: "A", midiNote: 60),
        PianoKeyModel(note: "C#4", isBlack: true, label: "C#4", flatLabel: "Db4", keyTrigger: "W", offsetPercent: 4.35, midiNote: 61),
        PianoKeyModel(note: "D4", isBlack: false, label: "D4", keyTrigger: "S", midiNote: 62),
        PianoKeyModel(note: "D#4", isBlack: true, label: "D#4", flatLabel: "Eb4", keyTrigger: "E", offsetPercent: 11.45, midiNote: 63),
        PianoKeyModel(note: "E4", isBlack: false, label: "E4", keyTrigger: "D", midiNote: 64),
        PianoKeyModel(note: "F4", isBlack: false, label: "F4", keyTrigger: "F", midiNote: 65),
        PianoKeyModel(note: "F#4", isBlack: true, label: "F#4", flatLabel: "Gb4", keyTrigger: "T", offsetPercent: 24.20, midiNote: 66),
        PianoKeyModel(note: "G4", isBlack: false, label: "G4", keyTrigger: "G", midiNote: 67),
        PianoKeyModel(note: "G#4", isBlack: true, label: "G#4", flatLabel: "Ab4", keyTrigger: "Y", offsetPercent: 31.25, midiNote: 68),
        PianoKeyModel(note: "A4", isBlack: false, label: "A4", keyTrigger: "H", midiNote: 69),
        PianoKeyModel(note: "A#4", isBlack: true, label: "A#4", flatLabel: "Bb4", keyTrigger: "U", offsetPercent: 38.25, midiNote: 70),
        PianoKeyModel(note: "B4", isBlack: false, label: "B4", keyTrigger: "J", midiNote: 71),
        
        // Octave 5 (shifted by exactly +46.66667% for seamless white-key boundary alignment)
        PianoKeyModel(note: "C5", isBlack: false, label: "C5", keyTrigger: "K", midiNote: 72),
        PianoKeyModel(note: "C#5", isBlack: true, label: "C#5", flatLabel: "Db5", keyTrigger: "O", offsetPercent: 4.35 + 46.66667, midiNote: 73),
        PianoKeyModel(note: "D5", isBlack: false, label: "D5", keyTrigger: "L", midiNote: 74),
        PianoKeyModel(note: "D#5", isBlack: true, label: "D#5", flatLabel: "Eb5", keyTrigger: "P", offsetPercent: 11.45 + 46.66667, midiNote: 75),
        PianoKeyModel(note: "E5", isBlack: false, label: "E5", keyTrigger: ";", midiNote: 76),
        PianoKeyModel(note: "F5", isBlack: false, label: "F5", keyTrigger: "'", midiNote: 77),
        PianoKeyModel(note: "F#5", isBlack: true, label: "F#5", flatLabel: "Gb5", keyTrigger: "]", offsetPercent: 24.20 + 46.66667, midiNote: 78),
        PianoKeyModel(note: "G5", isBlack: false, label: "G5", midiNote: 79),
        PianoKeyModel(note: "G#5", isBlack: true, label: "G#5", flatLabel: "Ab5", offsetPercent: 31.25 + 46.66667, midiNote: 80),
        PianoKeyModel(note: "A5", isBlack: false, label: "A5", midiNote: 81),
        PianoKeyModel(note: "A#5", isBlack: true, label: "A#5", flatLabel: "Bb5", offsetPercent: 38.25 + 46.66667, midiNote: 82),
        PianoKeyModel(note: "B5", isBlack: false, label: "B5", midiNote: 83),
        
        // Resolution Key
        PianoKeyModel(note: "C6", isBlack: false, label: "C6", midiNote: 84)
    ]
    
    public static let whiteKeys = keys.filter { !$0.isBlack }
    public static let blackKeys = keys.filter { $0.isBlack }
}

// MARK: - Native Grand Piano View

public struct NativePianoView: View {
    public let highlightedNotes: [String]
    public let rootNote: String?
    public let intervals: [String]
    public let preferFlat: Bool
    public let title: String
    public let subtitle: String
    public let onPlayNote: ((String, Int) -> Void)?
    
    @State private var activeNotes: Set<String> = []
    @State private var showLabels: Bool = true
    @State private var showKeyShortcuts: Bool = true
    @State private var showDegrees: Bool = true
    @State private var isArpeggiating: Bool = false
    
    public init(
        highlightedNotes: [String] = [],
        rootNote: String? = nil,
        intervals: [String] = [],
        preferFlat: Bool = false,
        title: String = "Interactive Grand Piano",
        subtitle: String = "2-Octave Physical Model (C4–C6) · 12-TET Acoustic Grand",
        onPlayNote: ((String, Int) -> Void)? = nil
    ) {
        self.highlightedNotes = highlightedNotes
        self.rootNote = rootNote
        self.intervals = intervals
        self.preferFlat = preferFlat
        self.title = title
        self.subtitle = subtitle
        self.onPlayNote = onPlayNote
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            fallboardRail
            keybedView
            footerSpecBar
        }
        .background(Color.musicianEbony)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Image(systemName: "pianokeys")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.musicianGold)
                        .padding(6)
                        .background(Color.musicianGold.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)
                    
                    if !highlightedNotes.isEmpty {
                        Text("\(highlightedNotes.count) Active")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
            
            // Actions & View Toggles
            HStack(spacing: 8) {
                if !highlightedNotes.isEmpty {
                    // Arpeggiate Button
                    Button(action: runArpeggio) {
                        HStack(spacing: 4) {
                            Image(systemName: isArpeggiating ? "waveform" : "play.fill")
                                .font(.system(size: 9))
                            Text("Arpeggio")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(isArpeggiating ? Color.musicianEbony : Color.musicianGold)
                        .background(isArpeggiating ? Color.musicianGold : Color.musicianGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.musicianGold.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isArpeggiating)
                    
                    // Strum Button
                    Button(action: runStrum) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 9))
                            Text("Strum")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(Color.musicianIvory)
                        .background(Color.musicianCharcoal)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Toggles Capsule
                HStack(spacing: 2) {
                    togglePill("Notes", isOn: $showLabels)
                    togglePill("Roles", isOn: $showDegrees)
                    togglePill("Keys", isOn: $showKeyShortcuts)
                }
                .padding(3)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianSurface.opacity(0.95))
    }
    
    private func togglePill(_ title: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isOn.wrappedValue ? Color.musicianGold : Color.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isOn.wrappedValue ? Color.musicianGold.opacity(0.18) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Steinway Crimson Felt Rail & Brass Fallboard
    
    private var fallboardRail: some View {
        ZStack(alignment: .bottom) {
            LinearGradient.steinwayFelt
                .frame(height: 12)
            
            // Gold Inlay String Line
            Rectangle()
                .fill(Color.musicianGold.opacity(0.35))
                .frame(height: 0.8)
            
            HStack {
                Text("STEINWAY & SONS · CONCERT MODEL")
                    .font(.system(size: 7, weight: .semibold, design: .serif))
                    .tracking(1.8)
                    .foregroundColor(Color.musicianGoldLight.opacity(0.65))
                
                Spacer()
                
                Text("12-TET · C4–C6")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .tracking(1.0)
                    .foregroundColor(Color.musicianGoldLight.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)
        }
    }
    
    // MARK: - Keybed View with Exact Seam-Centering Geometry
    
    private var keybedView: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let totalHeight = proxy.size.height
            let whiteKeyWidth = totalWidth / CGFloat(PianoGeometry.whiteKeyCount)
            let blackKeyWidth = totalWidth * (PianoGeometry.blackKeyWidthPercent / 100.0)
            let blackKeyHeight = totalHeight * PianoGeometry.blackKeyHeightRatio
            
            ZStack(alignment: .topLeading) {
                // 1. Natural Ivory White Keys (15 keys)
                HStack(spacing: 0) {
                    ForEach(PianoGeometry.whiteKeys) { key in
                        renderWhiteKey(key: key, width: whiteKeyWidth, height: totalHeight)
                    }
                }
                
                // 2. Upward Acoustic Light Beams for Depressed White Keys
                ForEach(PianoGeometry.whiteKeys.indices, id: \.self) { idx in
                    let key = PianoGeometry.whiteKeys[idx]
                    if activeNotes.contains(key.note) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.musicianGold.opacity(0.4), Color.musicianGoldLight.opacity(0.1), Color.clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: whiteKeyWidth, height: totalHeight)
                            .offset(x: CGFloat(idx) * whiteKeyWidth, y: 0)
                            .allowsHitTesting(false)
                    }
                }
                
                // 3. Satin Ebony Black Keys (10 keys with exact seam centering)
                ForEach(PianoGeometry.blackKeys) { key in
                    let offsetPct = key.offsetPercent ?? 0
                    let xPos = totalWidth * (offsetPct / 100.0)
                    renderBlackKey(key: key, width: blackKeyWidth, height: blackKeyHeight)
                        .offset(x: xPos, y: 0)
                }
            }
        }
        .frame(height: 220)
        .background(Color(hex: 0x07080B))
    }
    
    // MARK: - White Key Rendering
    
    private func renderWhiteKey(key: PianoKeyModel, width: CGFloat, height: CGFloat) -> some View {
        let isActive = activeNotes.contains(key.note)
        let isHighlighted = isKeyHighlighted(key)
        let isRoot = isHighlighted && isKeyRoot(key)
        let intervalLabel = isHighlighted ? getIntervalLabel(key) : ""
        
        return Button(action: { playKey(key) }) {
            ZStack(alignment: .bottom) {
                // Key Body Background: Natural Acoustic Ivory (Never Saturated Yellow)
                RoundedRectangle(cornerRadius: 3.5)
                    .fill(isActive ? LinearGradient.ivoryKeyPressed : LinearGradient.ivoryKey)
                    .overlay(
                        // Whisper-soft warm luminescence wash when active in scale/chord
                        Group {
                            if isHighlighted {
                                RoundedRectangle(cornerRadius: 3.5)
                                    .fill(Color.musicianGold.opacity(isRoot ? 0.08 : 0.04))
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5)
                            .strokeBorder(
                                isHighlighted
                                    ? (isRoot ? Color.musicianGold.opacity(0.7) : Color.musicianGold.opacity(0.35))
                                    : Color.black.opacity(0.12),
                                lineWidth: isHighlighted ? 1.0 : 0.6
                            )
                    )
                
                // Active Depression Shadow & Glow
                if isActive {
                    Color.musicianGold.opacity(0.15)
                        .clipShape(RoundedRectangle(cornerRadius: 3.5))
                }
                
                // Label Stack inside Key
                VStack(spacing: 3) {
                    // Top: Harmonic Role Badge
                    if isHighlighted && showDegrees && !intervalLabel.isEmpty {
                        HarmonicRoleBadge(intervalLabel, isRoot: isRoot, size: .mini, showIcon: false)
                            .padding(.top, 5)
                    } else {
                        Spacer().frame(height: 16)
                    }
                    
                    Spacer()
                    
                    // Middle: Keyboard Shortcut
                    if showKeyShortcuts, let shortcut = key.keyTrigger {
                        Text(shortcut)
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 2.5))
                    }
                    
                    // Bottom: Note Name & Illuminated Jewel Pip
                    if showLabels {
                        Text(key.note)
                            .font(.system(size: 10.5, weight: isHighlighted ? .bold : .medium))
                            .foregroundColor(
                                isHighlighted
                                    ? (isRoot ? Color.musicianGoldDark : Color(hex: 0x1E293B))
                                    : Color(hex: 0x475569)
                            )
                            .padding(.bottom, isHighlighted ? 1 : 6)
                    }
                    
                    // Illuminated Champagne Gold Jewel Pip at Key Foot
                    if isHighlighted {
                        Capsule()
                            .fill(isRoot ? Color.musicianGold : Color.musicianGold.opacity(0.75))
                            .frame(width: isRoot ? 12 : 7, height: 3)
                            .padding(.bottom, 4)
                    }
                }
                .frame(width: width)
            }
            .frame(width: width, height: height)
            // 3D Key Depression Physics: 5px downward translation with spring bounce
            .offset(y: isActive ? 5 : 0)
            .animation(.spring(response: 0.12, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Black Key Rendering
    
    private func renderBlackKey(key: PianoKeyModel, width: CGFloat, height: CGFloat) -> some View {
        let isActive = activeNotes.contains(key.note)
        let isHighlighted = isKeyHighlighted(key)
        let isRoot = isHighlighted && isKeyRoot(key)
        let intervalLabel = isHighlighted ? getIntervalLabel(key) : ""
        let displayPitch = (preferFlat && key.flatLabel != nil) ? key.flatLabel! : key.label
        let cleanName = displayPitch.replacingOccurrences(of: "[0-9]", with: "", options: .regularExpression)
        
        return Button(action: { playKey(key) }) {
            ZStack(alignment: .bottom) {
                // Key Body Background: Satin Matte Graphite Ebony
                RoundedRectangle(cornerRadius: 3.5)
                    .fill(isActive ? LinearGradient.ebonyKeyPressed : LinearGradient.ebonyKey)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5)
                            .strokeBorder(
                                isHighlighted
                                    ? (isRoot ? Color.musicianGold : Color.musicianGold.opacity(0.6))
                                    : Color.black.opacity(0.9),
                                lineWidth: isHighlighted ? 1.0 : 0.8
                            )
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 3)
                
                // Top Luminous Crown on Black Key
                VStack {
                    if isHighlighted {
                        Rectangle()
                            .fill(LinearGradient.goldGlow)
                            .frame(height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1))
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1.5)
                    }
                    Spacer()
                }
                
                // Upward Acoustic Light Beam when active
                if isActive {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.musicianGold.opacity(0.5), Color.musicianGoldLight.opacity(0.15), Color.clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 3.5))
                }
                
                // Label Stack inside Black Key
                VStack(spacing: 3) {
                    if isHighlighted && showDegrees && !intervalLabel.isEmpty {
                        HarmonicRoleBadge(intervalLabel, isRoot: isRoot, size: .mini, showIcon: false)
                            .padding(.top, 4)
                    } else {
                        Spacer().frame(height: 14)
                    }
                    
                    Spacer()
                    
                    if showKeyShortcuts, let shortcut = key.keyTrigger {
                        Text(shortcut)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight.opacity(0.75))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 2.5))
                    }
                    
                    if showLabels {
                        Text(cleanName)
                            .font(.system(size: 9.5, weight: isHighlighted ? .black : .bold))
                            .foregroundColor(isHighlighted ? (isRoot ? Color.musicianGoldLight : Color.musicianGold) : Color.musicianIvory.opacity(0.9))
                            .shadow(color: Color.black, radius: 2, x: 0, y: 1)
                            .padding(.bottom, 6)
                    }
                }
                .frame(width: width)
            }
            .frame(width: width, height: height)
            // 3D Depression Physics: 5px translation down + scale-y bounce
            .offset(y: isActive ? 5 : 0)
            .scaleEffect(x: 1.0, y: isActive ? 0.97 : 1.0, anchor: .top)
            .animation(.spring(response: 0.12, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Footer Spec Bar
    
    private var footerSpecBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(Color.musicianGold)
                Text("12-TET Physical Resonance")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.gray)
                Text("·")
                    .foregroundColor(Color.gray.opacity(0.5))
                Text("25-Key Dual Octave Studio Keyboard")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(Color.gray.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 5) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.musicianGold.opacity(0.8))
                Text("Polyphonic Stereo Acoustic Grand")
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.musicianSurface.opacity(0.85))
    }
    
    // MARK: - Interactions & Helpers
    
    private func playKey(_ key: PianoKeyModel) {
        onPlayNote?(key.note, key.midiNote)
        activeNotes.insert(key.note)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)
            activeNotes.remove(key.note)
        }
    }
    
    private func runArpeggio() {
        guard !highlightedNotes.isEmpty, !isArpeggiating else { return }
        isArpeggiating = true
        
        let sorted = PianoGeometry.keys
            .filter { key in isKeyHighlighted(key) }
            .sorted { $0.midiNote < $1.midiNote }
        
        Task { @MainActor in
            for key in sorted {
                playKey(key)
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            isArpeggiating = false
        }
    }
    
    private func runStrum() {
        guard !highlightedNotes.isEmpty else { return }
        let matching = PianoGeometry.keys.filter { isKeyHighlighted($0) }
        
        Task { @MainActor in
            for (idx, key) in matching.enumerated() {
                playKey(key)
                if idx < matching.count - 1 {
                    try? await Task.sleep(nanoseconds: 35_000_000)
                }
            }
        }
    }
    
    private func isKeyHighlighted(_ key: PianoKeyModel) -> Bool {
        if highlightedNotes.contains(key.note) { return true }
        if let flat = key.flatLabel, highlightedNotes.contains(flat) { return true }
        
        // Pitch class check
        let keyPitchClass = pitchClass(of: key.note)
        return highlightedNotes.contains { pitchClass(of: $0) == keyPitchClass }
    }
    
    private func isKeyRoot(_ key: PianoKeyModel) -> Bool {
        guard let root = rootNote else {
            // Fallback to first highlighted note
            guard let first = highlightedNotes.first else { return false }
            return pitchClass(of: key.note) == pitchClass(of: first)
        }
        return pitchClass(of: key.note) == pitchClass(of: root)
    }
    
    private func getIntervalLabel(_ key: PianoKeyModel) -> String {
        guard let root = rootNote ?? highlightedNotes.first else { return "" }
        let rootPC = pitchClassNumber(of: root)
        let keyPC = pitchClassNumber(of: key.note)
        let semitones = (keyPC - rootPC + 12) % 12
        
        // If intervals array matches highlightedNotes
        if let idx = highlightedNotes.firstIndex(where: { pitchClass(of: $0) == pitchClass(of: key.note) }),
           idx < intervals.count {
            let label = intervals[idx]
            if label.lowercased().contains("root") || label == "1" { return "ROOT" }
            return label
        }
        
        let intervalNames: [Int: String] = [
            0: "ROOT",
            1: "b2",
            2: "2ND",
            3: "m3",
            4: "3RD",
            5: "4TH",
            6: "b5",
            7: "5TH",
            8: "b6",
            9: "6TH",
            10: "m7",
            11: "7TH"
        ]
        return intervalNames[semitones] ?? ""
    }
    
    private func pitchClass(of note: String) -> String {
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let stripped = cleaned.replacingOccurrences(of: "[0-9\\-]", with: "", options: .regularExpression)
        return stripped
    }
    
    private func pitchClassNumber(of note: String) -> Int {
        let pc = pitchClass(of: note)
        switch pc {
        case "C", "B#": return 0
        case "C#", "DB": return 1
        case "D": return 2
        case "D#", "EB": return 3
        case "E", "FB": return 4
        case "F", "E#": return 5
        case "F#", "GB": return 6
        case "G": return 7
        case "G#", "AB": return 8
        case "A": return 9
        case "A#", "BB": return 10
        case "B", "CB": return 11
        default: return 0
        }
    }
}

#Preview {
    NativePianoView(
        highlightedNotes: ["C4", "E4", "G4", "B4"],
        rootNote: "C",
        intervals: ["ROOT", "3RD", "5TH", "7TH"],
        preferFlat: false
    )
    .frame(width: 820)
    .padding()
}
