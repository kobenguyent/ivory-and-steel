import SwiftUI

// MARK: - Fretboard Models & CAGED Form Definitions

public struct FretHighlightModel: Identifiable, Sendable, Equatable {
    public var id: String { "\(stringNum)-\(fret)" }
    public let stringNum: Int // 1 (High E) to 6 (Low E)
    public let fret: Int      // 0 (Nut) to 15
    public let label: String?
    public let isRoot: Bool
    public let degree: String?
    
    public init(
        stringNum: Int,
        fret: Int,
        label: String? = nil,
        isRoot: Bool = false,
        degree: String? = nil
    ) {
        self.stringNum = stringNum
        self.fret = fret
        self.label = label
        self.isRoot = isRoot
        self.degree = degree
    }
}

public enum CAGEDForm: String, CaseIterable, Identifiable, Sendable {
    case all = "All Shapes"
    case cShape = "C-Shape"
    case aShape = "A-Shape"
    case gShape = "G-Shape"
    case eShape = "E-Shape"
    case dShape = "D-Shape"
    
    public var id: String { rawValue }
    
    /// Representative fret span for standard root positions
    public var fretRange: ClosedRange<Int>? {
        switch self {
        case .all: return nil
        case .cShape: return 0...3
        case .aShape: return 2...5
        case .gShape: return 4...8
        case .eShape: return 7...10
        case .dShape: return 9...13
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .all: return Color.musicianGold
        case .cShape: return Color.musicianGoldLight
        case .aShape: return Color.white.opacity(0.85)
        case .gShape: return Color.musicianGold
        case .eShape: return Color.white.opacity(0.85)
        case .dShape: return Color.musicianGoldLight
        }
    }
}

// MARK: - Guitar Tuning Constants (Standard EADGBE)

public enum GuitarTuning {
    // String 1 (High E) to String 6 (Low E)
    public static let baseMidi = [64, 59, 55, 50, 45, 40]
    public static let stringNames = ["e", "B", "G", "D", "A", "E"]
    public static let stringGauges: [CGFloat] = [1.2, 1.6, 2.0, 2.5, 3.0, 3.8]
    public static let chromaticNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    public static func noteName(forString stringNum: Int, fret: Int) -> String {
        let midi = baseMidi[stringNum - 1] + fret
        let noteIndex = midi % 12
        let octave = (midi / 12) - 1
        return "\(chromaticNames[noteIndex])\(octave)"
    }
    
    public static func pitchClass(forString stringNum: Int, fret: Int) -> String {
        let midi = baseMidi[stringNum - 1] + fret
        return chromaticNames[midi % 12]
    }
}

// MARK: - Native Guitar Fretboard View

public struct NativeFretboardView: View {
    public let highlights: [FretHighlightModel]
    public let title: String
    public let subtitle: String
    public let onPlayFret: ((String, Int) -> Void)?
    
    @State private var activeFret: (stringNum: Int, fret: Int)? = nil
    @State private var vibratingStrings: Set<Int> = []
    @State private var showNoteNames: Bool = true
    @State private var selectedCAGED: CAGEDForm = .all
    
    public init(
        highlights: [FretHighlightModel] = [],
        title: String = "Guitar Fretboard",
        subtitle: String = "",
        onPlayFret: ((String, Int) -> Void)? = nil
    ) {
        self.highlights = highlights
        self.title = title
        self.subtitle = subtitle
        self.onPlayFret = onPlayFret
    }
    
    private var highlightLookup: [String: FretHighlightModel] {
        var map = [String: FretHighlightModel]()
        for h in highlights {
            map["\(h.stringNum)-\(h.fret)"] = h
        }
        return map
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            fretboardNeck
            footerBar
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
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(Color.gray)
                }
            }
            
            Spacer()
            
            // CAGED Selector & Note Display Toggle
            HStack(spacing: 8) {
                // CAGED Shape Picker Dropdown (Smooth Glassmorphism Popover)
                LuxuryDropdown(
                    selection: $selectedCAGED,
                    options: CAGEDForm.allCases.map { form in
                        let fretDesc = form.fretRange.map { "Frets \($0.lowerBound)–\($0.upperBound)" } ?? "Full Neck"
                        return LuxuryDropdownOption(
                            value: form,
                            title: form.rawValue,
                            badge: fretDesc
                        )
                    },
                    popoverWidth: 215,
                    maxPopoverHeight: 250,
                    shape: .rounded(7)
                ) { isOpen, isHovered in
                    HStack(spacing: 5) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 9))
                        Text(selectedCAGED.rawValue)
                            .font(.system(size: 10.5, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isOpen)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .foregroundColor(selectedCAGED != .all ? selectedCAGED.tintColor : Color.musicianIvory)
                    .background(isOpen ? Color.white.opacity(0.10) : (isHovered ? Color.white.opacity(0.07) : Color.musicianCharcoal))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                isOpen
                                    ? Color.musicianGold.opacity(0.65)
                                    : (selectedCAGED != .all ? selectedCAGED.tintColor.opacity(0.6) : (isHovered ? Color.white.opacity(0.22) : Color.gray.opacity(0.3))),
                                lineWidth: 1
                            )
                    )
                }
                
                // Note Names Toggle
                Button(action: { showNoteNames.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showNoteNames ? "eye.fill" : "eye.slash")
                            .font(.system(size: 9))
                        Text(showNoteNames ? "Notes: ON" : "Notes: OFF")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .foregroundColor(showNoteNames ? Color.musicianGold : Color.gray)
                    .background(showNoteNames ? Color.musicianGold.opacity(0.18) : Color.musicianCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                showNoteNames ? Color.musicianGold.opacity(0.4) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianSurface.opacity(0.95))
    }
    
    // MARK: - Fretboard Neck Geometry with Logarithmic Fret Wire Spacing
    
    private var fretboardNeck: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let totalHeight = proxy.size.height
            let tuningColWidth: CGFloat = 46
            let nutWidth: CGFloat = 36
            let fretsWidth = max(totalWidth - tuningColWidth - nutWidth - 12, 100)
            
            HStack(spacing: 0) {
                // 1. Tuning Pegs Column (Open String Name Badges)
                tuningPegsColumn(height: totalHeight)
                    .frame(width: tuningColWidth)
                
                // 2. Bone Nut Area (Fret 0)
                nutFretArea(width: nutWidth, height: totalHeight)
                
                // 3. Fretted Neck (Frets 1..15 with Logarithmic Spacing)
                frettedNeckCanvas(width: fretsWidth, height: totalHeight)
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 230)
        .background(LinearGradient.fretboardRosewood)
        .overlay(
            // Subtle Wood Grain Texture Lines
            VStack(spacing: 8) {
                ForEach(0..<18, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)
                }
            }
            .allowsHitTesting(false)
        )
    }
    
    // MARK: - Tuning Pegs Column
    
    private func tuningPegsColumn(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Header spacer for fret numbers alignment
            Spacer().frame(height: 22)
            
            VStack(spacing: 0) {
                ForEach(1...6, id: \.self) { stringNum in
                    let stringIdx = stringNum - 1
                    let name = GuitarTuning.stringNames[stringIdx]
                    
                    ZStack {
                        Circle()
                            .fill(Color.musicianSurface)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().strokeBorder(Color.musicianGold.opacity(0.4), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                        
                        Text(name)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            
            // Footer spacer for fret inlays alignment
            Spacer().frame(height: 18)
        }
        .background(Color.musicianEbony.opacity(0.8))
    }
    
    // MARK: - Nut Area (Fret 0 Open Strings)
    
    private func nutFretArea(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Fret 0 Label Header
            Text("0 (Nut)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color.musicianGold)
                .frame(height: 22)
            
            // Open string buttons
            VStack(spacing: 0) {
                ForEach(1...6, id: \.self) { stringNum in
                    let highlight = highlightLookup["\(stringNum)-0"]
                    let isActive = activeFret?.stringNum == stringNum && activeFret?.fret == 0
                    let pitch = GuitarTuning.pitchClass(forString: stringNum, fret: 0)
                    
                    Button(action: { playFret(stringNum: stringNum, fret: 0) }) {
                        ZStack {
                            Circle()
                                .fill(
                                    isActive
                                        ? Color.musicianGoldLight
                                        : (highlight != nil
                                           ? (highlight!.isRoot ? Color.musicianGold : Color(hex: 0xFDFBF7))
                                           : Color.musicianSurface.opacity(0.85))
                                )
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            highlight != nil ? (highlight!.isRoot ? Color.musicianGoldLight : Color.white.opacity(0.4)) : Color.gray.opacity(0.2),
                                            lineWidth: highlight != nil ? 1.0 : 0.6
                                        )
                                )
                                .shadow(
                                    color: highlight != nil ? (highlight!.isRoot ? Color.musicianGold.opacity(0.3) : Color.black.opacity(0.2)) : Color.clear,
                                    radius: 3
                                )
                            
                            Text(highlight?.label ?? (showNoteNames ? pitch : "0"))
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(
                                    isActive
                                        ? Color.musicianEbony
                                        : (highlight != nil ? (highlight!.isRoot ? Color.musicianEbony : Color(hex: 0x1E293B)) : Color.gray)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxHeight: .infinity)
                }
            }
            
            Spacer().frame(height: 18)
        }
        .frame(width: width)
        .background(
            // Bone / Ivory Nut Bar on Right Boundary
            HStack {
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFDFBF7), Color(hex: 0xDDD5C7)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 4)
                    .shadow(color: Color.black.opacity(0.6), radius: 2, x: 1, y: 0)
            }
        )
    }
    
    // MARK: - Fretted Neck Canvas with Logarithmic Spacing
    
    private func frettedNeckCanvas(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // A. Fret Wire Lines and Fret Numbers Header
            fretWiresAndNumbers(width: width)
            
            // B. Mother-of-Pearl Inlay Markers (Frets 3, 5, 7, 9, 12, 15)
            motherOfPearlInlays(width: width, height: height)
            
            // C. CAGED Box Overlay
            if let range = selectedCAGED.fretRange {
                renderCAGEDBox(range: range, width: width, height: height)
            }
            
            // D. Metallic Strings with Gauges & Pluck Oscillation Animation
            stringsLayer(width: width, height: height)
            
            // E. Interactive Fret Buttons Layer
            fretButtonsGrid(width: width, height: height)
        }
        .frame(width: width, height: height)
    }
    
    // MARK: - Fret Wires & Logarithmic Positions
    
    /// Normalizes distance to fret wire n using: $d_n = 1 - 2^{-n/12}$
    private func fretWireX(fret: Int, totalWidth: CGFloat) -> CGFloat {
        guard fret > 0 else { return 0 }
        let num = 1.0 - pow(2.0, -Double(fret) / 12.0)
        let den = 1.0 - pow(2.0, -15.0 / 12.0)
        return totalWidth * CGFloat(num / den)
    }
    
    /// Center of fret slot n (between wire n-1 and wire n)
    private func fretSlotCenterX(fret: Int, totalWidth: CGFloat) -> CGFloat {
        let xPrev = fretWireX(fret: fret - 1, totalWidth: totalWidth)
        let xCurr = fretWireX(fret: fret, totalWidth: totalWidth)
        return (xPrev + xCurr) / 2.0
    }
    
    private func fretWiresAndNumbers(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Header Numbers
            ForEach(1...15, id: \.self) { fret in
                let centerX = fretSlotCenterX(fret: fret, totalWidth: width)
                Text("\(fret)")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(fretMarkerIndices.contains(fret) ? Color.musicianGold : Color.gray)
                    .position(x: centerX, y: 11)
            }
            
            // Vertical Nickel/Brass Fret Wires
            ForEach(1...15, id: \.self) { fret in
                let wireX = fretWireX(fret: fret, totalWidth: width)
                Rectangle()
                    .fill(LinearGradient.metallicFret)
                    .frame(width: 1.8)
                    .shadow(color: Color.black.opacity(0.8), radius: 1, x: -0.5, y: 0)
                    .position(x: wireX, y: 115)
            }
        }
    }
    
    // MARK: - Mother of Pearl Inlays
    
    private let fretMarkerIndices = [3, 5, 7, 9, 12, 15]
    
    private func motherOfPearlInlays(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(fretMarkerIndices, id: \.self) { fret in
                let centerX = fretSlotCenterX(fret: fret, totalWidth: width)
                if fret == 12 {
                    // Double dot at 12th octave fret
                    VStack(spacing: 38) {
                        pearloidDot
                        pearloidDot
                    }
                    .position(x: centerX, y: height / 2.0 + 2)
                } else {
                    pearloidDot
                        .position(x: centerX, y: height / 2.0 + 2)
                }
            }
        }
    }
    
    private var pearloidDot: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0xFFFFFF), Color(hex: 0xF3EEE5), Color(hex: 0xCBD5E1)],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: 5
                )
            )
            .frame(width: 8.5, height: 8.5)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.3), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0.5)
    }
    
    // MARK: - CAGED Box Overlay
    
    private func renderCAGEDBox(range: ClosedRange<Int>, width: CGFloat, height: CGFloat) -> some View {
        let minX = fretWireX(fret: max(range.lowerBound - 1, 0), totalWidth: width)
        let maxX = fretWireX(fret: range.upperBound, totalWidth: width)
        let boxWidth = maxX - minX
        
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(selectedCAGED.tintColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(selectedCAGED.tintColor.opacity(0.75), lineWidth: 1.5)
                )
                .frame(width: boxWidth, height: height - 42)
                .offset(x: minX, y: 22)
            
            // Shape Badge Tag
            Text(selectedCAGED.rawValue)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.musicianEbony)
                .padding(.horizontal, 4.5)
                .padding(.vertical, 1.5)
                .background(selectedCAGED.tintColor)
                .clipShape(Capsule())
                .offset(x: minX + 4, y: 24)
        }
        .animation(StudioMotion.cardGlide, value: selectedCAGED)
        .transition(.opacity)
    }
    
    // MARK: - Metallic Guitar Strings with Pluck Oscillation
    
    private func stringsLayer(width: CGFloat, height: CGFloat) -> some View {
        let playableHeight = height - 40
        let spacing = playableHeight / 6.0
        
        return ZStack {
            ForEach(1...6, id: \.self) { stringNum in
                let stringIdx = stringNum - 1
                let gauge = GuitarTuning.stringGauges[stringIdx]
                let yPos = 22 + spacing * (CGFloat(stringNum) - 0.5)
                let isVibrating = vibratingStrings.contains(stringNum)
                
                // Continuous Metallic String Horizontal Wire
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: stringNum >= 4
                                ? [Color(hex: 0xEAB308), Color(hex: 0xFACC15), Color(hex: 0xCA8A04)] // Bronze wound
                                : [Color(hex: 0xE2E8F0), Color(hex: 0xF8FAFC), Color(hex: 0x94A3B8)], // Plain steel
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: gauge)
                    .shadow(color: Color.black.opacity(0.7), radius: 1, x: 0, y: 1)
                    // Pluck Vibration Oscillation
                    .offset(y: isVibrating ? 1.5 : 0)
                    .animation(
                        isVibrating
                            ? .interpolatingSpring(stiffness: 400, damping: 5).repeatCount(4, autoreverses: true)
                            : .default,
                        value: isVibrating
                    )
                    .position(x: width / 2.0, y: yPos)
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Interactive Fret Buttons Grid
    
    private func fretButtonsGrid(width: CGFloat, height: CGFloat) -> some View {
        let playableHeight = height - 40
        let spacing = playableHeight / 6.0
        
        return ZStack {
            ForEach(1...6, id: \.self) { stringNum in
                let yPos = 22 + spacing * (CGFloat(stringNum) - 0.5)
                
                ForEach(1...15, id: \.self) { fret in
                    let xPos = fretSlotCenterX(fret: fret, totalWidth: width)
                    let highlight = highlightLookup["\(stringNum)-\(fret)"]
                    let isActive = activeFret?.stringNum == stringNum && activeFret?.fret == fret
                    let pitch = GuitarTuning.pitchClass(forString: stringNum, fret: fret)
                    
                    Button(action: { playFret(stringNum: stringNum, fret: fret) }) {
                        ZStack {
                            if isActive {
                                Circle()
                                    .fill(Color.musicianGoldLight)
                                    .frame(width: 22, height: 22)
                                    .scaleEffect(1.2)
                                    .shadow(color: Color.musicianGoldLight, radius: 6)
                            } else if let h = highlight {
                                Circle()
                                    .fill(h.isRoot ? Color.musicianGold : Color(hex: 0xFDFBF7))
                                    .frame(width: 19, height: 19)
                                    .overlay(Circle().strokeBorder(h.isRoot ? Color.musicianGoldLight : Color.white.opacity(0.8), lineWidth: 0.8))
                                    .shadow(color: (h.isRoot ? Color.musicianGold.opacity(0.35) : Color.black.opacity(0.2)), radius: 3)
                            } else if showNoteNames {
                                Circle()
                                    .fill(Color.musicianEbony.opacity(0.8))
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.6))
                            } else {
                                // Transparent hover & hit target
                                Circle()
                                    .fill(Color.white.opacity(0.001))
                                    .frame(width: 22, height: 22)
                            }
                            
                            // Text Label
                            if isActive {
                                Text(pitch)
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(Color.musicianEbony)
                            } else if let h = highlight {
                                Text(h.label ?? pitch)
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(h.isRoot ? Color.musicianEbony : Color(hex: 0x1E293B))
                            } else if showNoteNames {
                                Text(pitch)
                                    .font(.system(size: 7.5, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .position(x: xPos, y: yPos)
                }
            }
        }
    }
    
    // MARK: - Footer Bar & Legend
    
    private var footerBar: some View {
        HStack {
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.musicianGold)
                        .frame(width: 8, height: 8)
                    Text("Root Note")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.musicianGoldLight)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.subdominantEmerald)
                        .frame(width: 8, height: 8)
                    Text("Scale / Chord Tone")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.gray)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.musicianSurface.opacity(0.85))
    }
    
    // MARK: - Audio & Animation Interaction
    
    private func playFret(stringNum: Int, fret: Int) {
        let noteName = GuitarTuning.noteName(forString: stringNum, fret: fret)
        let midi = GuitarTuning.baseMidi[stringNum - 1] + fret
        onPlayFret?(noteName, midi)
        
        activeFret = (stringNum, fret)
        vibratingStrings.insert(stringNum)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if activeFret?.stringNum == stringNum && activeFret?.fret == fret {
                activeFret = nil
            }
            vibratingStrings.remove(stringNum)
        }
    }
}

#Preview {
    NativeFretboardView(
        highlights: [
            FretHighlightModel(stringNum: 6, fret: 3, label: "G", isRoot: true),
            FretHighlightModel(stringNum: 5, fret: 2, label: "B", isRoot: false),
            FretHighlightModel(stringNum: 4, fret: 0, label: "D", isRoot: false),
            FretHighlightModel(stringNum: 3, fret: 0, label: "G", isRoot: true),
            FretHighlightModel(stringNum: 2, fret: 3, label: "D", isRoot: false),
            FretHighlightModel(stringNum: 1, fret: 3, label: "G", isRoot: true)
        ],
        title: "G Major Open Chord Voicing"
    )
    .frame(width: 880)
    .padding()
}
