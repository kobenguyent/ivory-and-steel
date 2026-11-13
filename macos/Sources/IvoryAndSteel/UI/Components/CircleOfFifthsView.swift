import SwiftUI

// MARK: - Circle of Fifths Key Data Model

public struct CircleKeyModel: Identifiable, Sendable, Equatable {
    public var id: String { root }
    public let root: String
    public let name: String
    public let index: Int // 0..11 clockwise from 12 o'clock
    public let sharpsCount: Int
    public let flatsCount: Int
    public let accidentalType: String // "natural", "sharp", "flat"
    public let keySignatureDesc: String
    public let relativeMinor: String
    public let relativeMinorRoot: String
    public let diatonicNotes: [String]
    
    public var displayRoot: String {
        root.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯")
    }
    
    public var displayMinor: String {
        relativeMinorRoot.replacingOccurrences(of: "b", with: "♭").replacingOccurrences(of: "#", with: "♯") + "m"
    }
    
    public var accidentalBadge: String {
        if sharpsCount > 0 { return "\(sharpsCount)♯" }
        if flatsCount > 0 { return "\(flatsCount)♭" }
        return "♮"
    }
}

public enum CircleOfFifthsData {
    public static let keys: [CircleKeyModel] = [
        CircleKeyModel(root: "C", name: "C Major", index: 0, sharpsCount: 0, flatsCount: 0, accidentalType: "natural", keySignatureDesc: "Natural (No sharps or flats)", relativeMinor: "A Minor", relativeMinorRoot: "A", diatonicNotes: ["C", "D", "E", "F", "G", "A", "B"]),
        CircleKeyModel(root: "G", name: "G Major", index: 1, sharpsCount: 1, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "1 Sharp (F♯)", relativeMinor: "E Minor", relativeMinorRoot: "E", diatonicNotes: ["G", "A", "B", "C", "D", "E", "F#"]),
        CircleKeyModel(root: "D", name: "D Major", index: 2, sharpsCount: 2, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "2 Sharps (F♯, C♯)", relativeMinor: "B Minor", relativeMinorRoot: "B", diatonicNotes: ["D", "E", "F#", "G", "A", "B", "C#"]),
        CircleKeyModel(root: "A", name: "A Major", index: 3, sharpsCount: 3, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "3 Sharps (F♯, C♯, G♯)", relativeMinor: "F♯ Minor", relativeMinorRoot: "F#", diatonicNotes: ["A", "B", "C#", "D", "E", "F#", "G#"]),
        CircleKeyModel(root: "E", name: "E Major", index: 4, sharpsCount: 4, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "4 Sharps (F♯, C♯, G♯, D♯)", relativeMinor: "C♯ Minor", relativeMinorRoot: "C#", diatonicNotes: ["E", "F#", "G#", "A", "B", "C#", "D#"]),
        CircleKeyModel(root: "B", name: "B Major", index: 5, sharpsCount: 5, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "5 Sharps (F♯, C♯, G♯, D♯, A♯)", relativeMinor: "G♯ Minor", relativeMinorRoot: "G#", diatonicNotes: ["B", "C#", "D#", "E", "F#", "G#", "A#"]),
        CircleKeyModel(root: "F#", name: "F♯ Major", index: 6, sharpsCount: 6, flatsCount: 0, accidentalType: "sharp", keySignatureDesc: "6 Sharps (F♯, C♯, G♯, D♯, A♯, E♯)", relativeMinor: "D♯ Minor", relativeMinorRoot: "D#", diatonicNotes: ["F#", "G#", "A#", "B", "C#", "D#", "E#"]),
        CircleKeyModel(root: "Db", name: "D♭ Major", index: 7, sharpsCount: 0, flatsCount: 5, accidentalType: "flat", keySignatureDesc: "5 Flats (B♭, E♭, A♭, D♭, G♭)", relativeMinor: "B♭ Minor", relativeMinorRoot: "Bb", diatonicNotes: ["Db", "Eb", "F", "Gb", "Ab", "Bb", "C"]),
        CircleKeyModel(root: "Ab", name: "A♭ Major", index: 8, sharpsCount: 0, flatsCount: 4, accidentalType: "flat", keySignatureDesc: "4 Flats (B♭, E♭, A♭, D♭)", relativeMinor: "F Minor", relativeMinorRoot: "F", diatonicNotes: ["Ab", "Bb", "C", "Db", "Eb", "F", "G"]),
        CircleKeyModel(root: "Eb", name: "E♭ Major", index: 9, sharpsCount: 0, flatsCount: 3, accidentalType: "flat", keySignatureDesc: "3 Flats (B♭, E♭, A♭)", relativeMinor: "C Minor", relativeMinorRoot: "C", diatonicNotes: ["Eb", "F", "G", "Ab", "Bb", "C", "D"]),
        CircleKeyModel(root: "Bb", name: "B♭ Major", index: 10, sharpsCount: 0, flatsCount: 2, accidentalType: "flat", keySignatureDesc: "2 Flats (B♭, E♭)", relativeMinor: "G Minor", relativeMinorRoot: "G", diatonicNotes: ["Bb", "C", "D", "Eb", "F", "G", "A"]),
        CircleKeyModel(root: "F", name: "F Major", index: 11, sharpsCount: 0, flatsCount: 1, accidentalType: "flat", keySignatureDesc: "1 Flat (B♭)", relativeMinor: "D Minor", relativeMinorRoot: "D", diatonicNotes: ["F", "G", "A", "Bb", "C", "D", "E"])
    ]
    
    public static func keyInfo(for root: String) -> CircleKeyModel {
        let clean = root.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "♭", with: "b").replacingOccurrences(of: "♯", with: "#")
        return keys.first { $0.root.caseInsensitiveCompare(clean) == .orderedSame } ?? keys[0]
    }
}

// MARK: - Circle of Fifths Precision Swiss Chronograph Dial View

public struct CircleOfFifthsView: View {
    public let selectedRoot: String
    public let onSelectKey: ((String) -> Void)?
    public let onAuditionTone: ((String) -> Void)?
    
    public init(
        selectedRoot: String = "C",
        onSelectKey: ((String) -> Void)? = nil,
        onAuditionTone: ((String) -> Void)? = nil
    ) {
        self.selectedRoot = selectedRoot
        self.onSelectKey = onSelectKey
        self.onAuditionTone = onAuditionTone
    }
    
    private var currentKey: CircleKeyModel {
        CircleOfFifthsData.keyInfo(for: selectedRoot)
    }
    
    private var dominantKey: CircleKeyModel {
        let nextIdx = (currentKey.index + 1) % 12
        return CircleOfFifthsData.keys[nextIdx]
    }
    
    private var subdominantKey: CircleKeyModel {
        let prevIdx = (currentKey.index + 11) % 12
        return CircleOfFifthsData.keys[prevIdx]
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 28) {
            // Precision Chronograph Dial
            astrolabeDial
                .frame(width: 300, height: 300)
                .padding(.vertical, 4)
            
            // Integrated Harmonic Cadence Deck (Zero border-on-border nesting, zero text truncation)
            harmonicTelemetryDeck
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Astrolabe Vector Canvas Dial
    
    private var astrolabeDial: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: size / 2.0, y: size / 2.0)
            let outerRadius = size * 0.44
            let innerRadius = size * 0.29
            let centerMedallionRadius = size * 0.16
            
            ZStack {
                // Background Concentric Rings & Radial Spokes with SwiftUI Canvas
                Canvas { context, canvasSize in
                    let c = CGPoint(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)
                    
                    // Outer Bezel Ring
                    var outerCircle = Path()
                    outerCircle.addArc(center: c, radius: outerRadius + 14, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    context.stroke(outerCircle, with: .color(Color.white.opacity(0.08)), lineWidth: 0.8)
                    
                    // Middle Ring
                    var midCircle = Path()
                    midCircle.addArc(center: c, radius: innerRadius + 16, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    context.stroke(midCircle, with: .color(Color.white.opacity(0.04)), lineWidth: 0.6)
                    
                    // Spokes & Tick Marks (36 ticks every 10 degrees)
                    for i in 0..<36 {
                        let angle = Angle.degrees(Double(i) * 10.0 - 90.0)
                        let isMajor = (i % 3 == 0)
                        let r1 = outerRadius + 8
                        let r2 = isMajor ? outerRadius + 13 : outerRadius + 10
                        
                        let p1 = pointOnCircle(center: c, radius: r1, angle: angle)
                        let p2 = pointOnCircle(center: c, radius: r2, angle: angle)
                        
                        var tick = Path()
                        tick.move(to: p1)
                        tick.addLine(to: p2)
                        context.stroke(tick, with: .color(isMajor ? Color.musicianGold.opacity(0.3) : Color.white.opacity(0.08)), lineWidth: isMajor ? 0.8 : 0.5)
                    }
                    
                    // Spokes between sectors
                    for i in 0..<12 {
                        let angle = Angle.degrees(Double(i) * 30.0 - 90.0 - 15.0)
                        let p1 = pointOnCircle(center: c, radius: centerMedallionRadius + 4, angle: angle)
                        let p2 = pointOnCircle(center: c, radius: outerRadius + 8, angle: angle)
                        
                        var spoke = Path()
                        spoke.move(to: p1)
                        spoke.addLine(to: p2)
                        context.stroke(spoke, with: .color(Color.white.opacity(0.04)), style: StrokeStyle(lineWidth: 0.6, dash: [2, 4]))
                    }
                }
                
                // Harmonic Cadence Arcs (Subtle hairline connections, zero halogen bleeding)
                harmonicFlowArcs(center: center, outerRadius: outerRadius, innerRadius: innerRadius)
                    .animation(StudioMotion.cardGlide, value: currentKey.root)
                
                // Outer Ring Major Key Buttons
                ForEach(CircleOfFifthsData.keys) { key in
                    let angle = Angle.degrees(Double(key.index) * 30.0 - 90.0)
                    let pt = pointOnCircle(center: center, radius: outerRadius - 4, angle: angle)
                    let isTonic = (key.root.caseInsensitiveCompare(currentKey.root) == .orderedSame)
                    let isSub = (key.root.caseInsensitiveCompare(subdominantKey.root) == .orderedSame)
                    let isDom = (key.root.caseInsensitiveCompare(dominantKey.root) == .orderedSame)
                    
                    majorKeySectorButton(key: key, isTonic: isTonic, isSub: isSub, isDom: isDom)
                        .position(pt)
                        .animation(StudioMotion.snappyControl, value: currentKey.root)
                }
                
                // Inner Ring Relative Minor Key Labels
                ForEach(CircleOfFifthsData.keys) { key in
                    let angle = Angle.degrees(Double(key.index) * 30.0 - 90.0)
                    let pt = pointOnCircle(center: center, radius: innerRadius + 2, angle: angle)
                    let isTonicMinor = (key.root.caseInsensitiveCompare(currentKey.root) == .orderedSame)
                    
                    Text(key.displayMinor)
                        .font(.system(size: isTonicMinor ? 10 : 8.5, weight: isTonicMinor ? .bold : .medium, design: .serif))
                        .foregroundColor(isTonicMinor ? Color.musicianGoldLight : Color.white.opacity(0.45))
                        .position(pt)
                        .animation(StudioMotion.snappyControl, value: currentKey.root)
                }
                
                // Center Medallion (Quiet Precision Core)
                centerMedallion(center: center, radius: centerMedallionRadius)
                    .animation(StudioMotion.cardGlide, value: currentKey.root)
            }
        }
    }
    
    // MARK: - Harmonic Flow Arcs (Subtle Restrained Hairlines)
    
    @ViewBuilder
    private func harmonicFlowArcs(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) -> some View {
        let subAngle = Angle.degrees(Double(subdominantKey.index) * 30.0 - 90.0)
        let tonicAngle = Angle.degrees(Double(currentKey.index) * 30.0 - 90.0)
        let domAngle = Angle.degrees(Double(dominantKey.index) * 30.0 - 90.0)
        
        let pSub = pointOnCircle(center: center, radius: outerRadius - 4, angle: subAngle)
        let pTonic = pointOnCircle(center: center, radius: outerRadius - 4, angle: tonicAngle)
        let pDom = pointOnCircle(center: center, radius: outerRadius - 4, angle: domAngle)
        let pFocus = pointOnCircle(center: center, radius: innerRadius - 2, angle: tonicAngle)
        
        // Subdominant -> Tonic Arc
        Path { path in
            path.move(to: pSub)
            path.addQuadCurve(to: pTonic, control: pFocus)
        }
        .stroke(
            Color.musicianGold.opacity(0.3),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 3])
        )
        
        // Dominant -> Tonic Arc
        Path { path in
            path.move(to: pDom)
            path.addQuadCurve(to: pTonic, control: pFocus)
        }
        .stroke(
            Color.musicianGold.opacity(0.3),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 3])
        )
    }
    
    // MARK: - Major Key Sector Button
    
    private func majorKeySectorButton(key: CircleKeyModel, isTonic: Bool, isSub: Bool, isDom: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selectKey(key.root)
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        isTonic ? Color.musicianGold :
                        (isSub || isDom) ? Color.white.opacity(0.08) :
                        Color.white.opacity(0.035)
                    )
                    .frame(width: isTonic ? 34 : 26, height: isTonic ? 34 : 26)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isTonic ? Color.musicianGoldLight :
                                (isSub || isDom) ? Color.white.opacity(0.2) :
                                Color.white.opacity(0.08),
                                lineWidth: isTonic ? 1.2 : 0.6
                            )
                    )
                
                VStack(spacing: 0) {
                    Text(key.displayRoot)
                        .font(.system(size: isTonic ? 13 : 10.5, weight: isTonic ? .bold : .medium, design: .serif))
                        .foregroundColor(isTonic ? Color.musicianEbony : Color.musicianIvory)
                    
                    if !isTonic && key.accidentalBadge != "♮" {
                        Text(key.accidentalBadge)
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                }
            }
        }
        .studioPressable()
    }
    
    // MARK: - Center Medallion (Quiet Swiss Precision)
    
    private func centerMedallion(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.musicianCard)
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle()
                        .strokeBorder(Color.musicianGold.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 6, y: 2)
            
            VStack(spacing: 1) {
                Text(currentKey.displayRoot)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                    .contentTransition(.numericText())
                
                Text(currentKey.accidentalBadge)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.5))
                    .contentTransition(.numericText())
                
                Text(currentKey.displayMinor)
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundColor(Color.musicianGoldLight.opacity(0.75))
                    .contentTransition(.numericText())
            }
        }
    }
    
    // MARK: - Harmonic Telemetry Deck (Zero Truncation, Clean Glass Surfaces)
    
    private var harmonicTelemetryDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            telemetryHeader
            functionalCadenceTiles
            diatonicScaleHighway
        }
        .padding(12)
        .background(Color.white.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }
    
    private var telemetryHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(currentKey.name)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)
                .contentTransition(.numericText())

            Spacer()

            Text(currentKey.keySignatureDesc)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.gray)
                .contentTransition(.numericText())
        }
    }

    private var functionalCadenceTiles: some View {
        HStack(spacing: 8) {
            cadenceTile(roman: "IV", root: subdominantKey.displayRoot, function: "Subdominant", isCenter: false) {
                selectKey(subdominantKey.root)
            }

            cadenceTile(roman: "I", root: currentKey.displayRoot, function: "Tonic", isCenter: true, action: nil)

            cadenceTile(roman: "V", root: dominantKey.displayRoot, function: "Dominant", isCenter: false) {
                selectKey(dominantKey.root)
            }
        }
    }

    @ViewBuilder
    private func cadenceTile(
        roman: String,
        root: String,
        function: String,
        isCenter: Bool,
        action: (() -> Void)?
    ) -> some View {
        let content = VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(roman)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isCenter ? Color.musicianGoldLight : Color.white.opacity(0.6))
                Spacer()
                Text(root)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(isCenter ? Color.musicianGold : Color.musicianIvory)
            }

            Text(function)
                .font(.system(size: 10, weight: isCenter ? .semibold : .medium))
                .foregroundColor(isCenter ? Color.musicianIvory : Color.white.opacity(0.75))
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCenter ? Color.musicianGold.opacity(0.08) : Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isCenter ? Color.musicianGold.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 0.8)
        )

        if let action {
            Button(action: action) {
                content
                    .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var diatonicScaleHighway: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Scale Notes")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color.gray)

                Spacer()

                Text("Relative minor: \(currentKey.relativeMinor)")
                    .font(.system(size: 10.5, weight: .medium, design: .serif))
                    .foregroundColor(Color.white.opacity(0.65))
            }

            HStack(spacing: 5) {
                ForEach(Array(currentKey.diatonicNotes.enumerated()), id: \.offset) { idx, note in
                    Button(action: { onAuditionTone?(note) }) {
                        HStack(spacing: 2) {
                            Text("\(idx + 1)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                            Text(note)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundColor(Color.musicianIvory)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func selectKey(_ root: String) {
        onSelectKey?(root)
        onAuditionTone?(root)
    }
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let radians = CGFloat(angle.radians)
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
}

#Preview {
    CircleOfFifthsView(selectedRoot: "C")
        .frame(width: 820)
        .padding()
}
