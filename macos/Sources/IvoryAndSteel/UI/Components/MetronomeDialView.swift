import SwiftUI

// MARK: - Tempo Preset Model

public struct TempoPresetModel: Identifiable, Sendable, Equatable {
    public var id: String { name }
    public let name: String
    public let bpm: Double
    public let italianTerm: String
    
    public init(name: String, bpm: Double, italianTerm: String = "") {
        self.name = name
        self.bpm = bpm
        self.italianTerm = italianTerm.isEmpty ? name : italianTerm
    }
}

public enum MetronomePresets {
    public static let standard: [TempoPresetModel] = [
        TempoPresetModel(name: "Largo", bpm: 48, italianTerm: "Broad & dignified (40–60)"),
        TempoPresetModel(name: "Adagio", bpm: 66, italianTerm: "Slow & stately (66–76)"),
        TempoPresetModel(name: "Andante", bpm: 76, italianTerm: "At a walking pace (76–108)"),
        TempoPresetModel(name: "Moderato", bpm: 108, italianTerm: "Moderately (108–120)"),
        TempoPresetModel(name: "Allegro", bpm: 132, italianTerm: "Fast, quickly, & bright (120–156)"),
        TempoPresetModel(name: "Presto", bpm: 168, italianTerm: "Very, very fast (168–200)")
    ]
}

// MARK: - Native Metronome Dial View

public struct MetronomeDialView: View {
    @Binding public var bpm: Double
    @Binding public var isRunning: Bool
    public var beatsPerBar: Int
    public var beatTick: Int
    public let onBpmChanged: ((Double) -> Void)?
    public let onToggleRunning: (() -> Void)?
    public let onTickSound: ((Bool) -> Void)?

    @State private var currentBeat: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var pendulumAngle: Double = 0.0
    @State private var tapTimes: [Date] = []

    public init(
        bpm: Binding<Double>,
        isRunning: Binding<Bool>,
        beatsPerBar: Int = 4,
        beatTick: Int = 0,
        onBpmChanged: ((Double) -> Void)? = nil,
        onToggleRunning: (() -> Void)? = nil,
        onTickSound: ((Bool) -> Void)? = nil
    ) {
        self._bpm = bpm
        self._isRunning = isRunning
        self.beatsPerBar = max(1, beatsPerBar)
        self.beatTick = beatTick
        self.onBpmChanged = onBpmChanged
        self.onToggleRunning = onToggleRunning
        self.onTickSound = onTickSound
    }

    private var activeBeatIndex: Int {
        if beatTick > 0 {
            return (beatTick - 1) % max(1, beatsPerBar)
        }
        return currentBeat % max(1, beatsPerBar)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 24) {
            // Left: Swinging Pendulum
            analogPendulumCard
                .frame(width: 210, height: 290)

            // Right: Circular Arc Dial, Steppers, Beat Indicators & Start/Tap Controls
            circularDialCard
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(Color.musicianEbony)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 8)
        .onChange(of: beatTick) { _, newTick in
            guard isRunning, newTick > 0 else { return }
            triggerPulseRing()
        }
        .task(id: isRunning) {
            guard isRunning else {
                currentBeat = 0
                pendulumAngle = 0
                return
            }
            await runMetronomeLoop()
        }
    }

    // MARK: - Analog Swinging Pendulum Card

    private var analogPendulumCard: some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                let pivot = CGPoint(x: w / 2.0, y: h - 24)
                let rodLength = h - 54
                
                // Sliding weight (bob) height position scales with BPM:
                // Lower BPM (30) = weight higher up (near 0.35 of rod)
                // Higher BPM (260) = weight lower down (near 0.85 of rod)
                let bpmFraction = (bpm - 30.0) / (260.0 - 30.0)
                let bobOffsetFraction = 0.32 + bpmFraction * 0.50
                let bobDistance = rodLength * CGFloat(bobOffsetFraction)
                
                ZStack {
                    // Classic Wooden Pyramidal Enclosure Outline
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.28, y: 12))
                        path.addLine(to: CGPoint(x: w * 0.72, y: 12))
                        path.addLine(to: CGPoint(x: w * 0.90, y: h - 10))
                        path.addLine(to: CGPoint(x: w * 0.10, y: h - 10))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x1A1410), Color(hex: 0x120E0B)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: w * 0.28, y: 12))
                            path.addLine(to: CGPoint(x: w * 0.72, y: 12))
                            path.addLine(to: CGPoint(x: w * 0.90, y: h - 10))
                            path.addLine(to: CGPoint(x: w * 0.10, y: h - 10))
                            path.closeSubpath()
                        }
                        .stroke(Color.musicianGold.opacity(0.35), lineWidth: 1.2)
                    )
                    
                    // Pendulum Assembly (Rotates around bottom pivot)
                    ZStack {
                        // Brass Rod
                        Rectangle()
                            .fill(LinearGradient.goldGlow)
                            .frame(width: 3.5, height: rodLength)
                            .offset(y: -rodLength / 2.0)
                        
                        // Sliding Brass Bob / Weight
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFDE047), Color(hex: 0xD4AF37), Color(hex: 0x854D0E)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 26, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.8)
                                )
                                .shadow(color: Color.black.opacity(0.7), radius: 3, x: 0, y: 2)
                            
                            // Center alignment mark line
                            Rectangle()
                                .fill(Color.musicianEbony)
                                .frame(width: 14, height: 1.2)
                        }
                        .offset(y: -bobDistance)
                    }
                    .rotationEffect(.degrees(pendulumAngle), anchor: .bottom)
                    .position(pivot)
                    
                    // Pivot Brass Cap Jewel
                    Circle()
                        .fill(RadialGradient(colors: [Color.musicianGoldLight, Color.musicianGoldDark], center: .center, startRadius: 1, endRadius: 8))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(Color.musicianEbony, lineWidth: 1.5))
                        .shadow(color: Color.black.opacity(0.6), radius: 2)
                        .position(pivot)
                }
            }
        }
        .padding(12)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.25), lineWidth: 0.8))
    }
    
    // MARK: - Digital Circular Arc Tempo Dial & Big Controls
    
    private var circularDialCard: some View {
        VStack(spacing: 12) {
            ZStack {
                // Expanding Luminous Pulse Ring on Each Beat
                Circle()
                    .strokeBorder(
                        activeBeatIndex == 0 ? Color.musicianGold : Color.white.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: 162, height: 162)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)

                // Digital Arc Vector Track
                GeometryReader { proxy in
                    let size = min(proxy.size.width, proxy.size.height)
                    let center = CGPoint(x: proxy.size.width / 2.0, y: proxy.size.height / 2.0)
                    let radius = size * 0.40
                    let minAngle: Double = 135
                    let maxAngle: Double = 405
                    let fraction = (bpm - 30.0) / (260.0 - 30.0)
                    let currentAngle = minAngle + fraction * (maxAngle - minAngle)

                    ZStack {
                        Path { path in
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: .degrees(minAngle),
                                endAngle: .degrees(maxAngle),
                                clockwise: false
                            )
                        }
                        .stroke(Color.musicianCharcoal, style: StrokeStyle(lineWidth: 10, lineCap: .round))

                        Path { path in
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: .degrees(minAngle),
                                endAngle: .degrees(currentAngle),
                                clockwise: false
                            )
                        }
                        .stroke(
                            LinearGradient.goldGlow,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                    }
                }
                .frame(width: 162, height: 162)

                // Center BPM Digital Readout
                VStack(spacing: 0) {
                    Text("\(Int(bpm))")
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundColor(Color.musicianGoldLight)
                        .tracking(-1.5)
                        .contentTransition(.numericText())

                    Text("BPM")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.gray)
                        .tracking(1.0)
                }
            }
            .frame(height: 162)

            // Beat Position Row
            HStack(spacing: 6) {
                ForEach(0..<beatsPerBar, id: \.self) { idx in
                    let isActive = isRunning && activeBeatIndex == idx
                    beatIndicator(index: idx, isActive: isActive, isAccent: idx == 0)
                }
            }
            .frame(maxWidth: 260)

            // Stepper Buttons (-5, -1, +1, +5)
            HStack(spacing: 8) {
                stepperButton("-5") { changeBPM(by: -5) }
                stepperButton("-1") { changeBPM(by: -1) }
                stepperButton("+1") { changeBPM(by: +1) }
                stepperButton("+5") { changeBPM(by: +5) }
            }

            // Primary Start/Stop + Tap Tempo Row
            HStack(spacing: 10) {
                Button(action: togglePlay) {
                    HStack(spacing: 7) {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 12.5))
                        Text(isRunning ? "Stop" : "Start")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(isRunning ? Color.white : Color.musicianEbony)
                    .background(isRunning ? Color.steinwayCrimson : Color.musicianGold)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .studioPressable()

                Button(action: handleTapTempo) {
                    HStack(spacing: 5) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 11))
                        Text("Tap")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .foregroundColor(Color.musicianIvory)
                    .background(Color.musicianCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                }
                .studioPressable()
                .help("Tap rhythmically to set tempo")
            }
            .frame(maxWidth: 280)
        }
        .padding(14)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    private func stepperButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color.musicianIvory)
                .frame(width: 46, height: 28)
                .background(Color.musicianCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .studioPressable()
    }
    
    private func beatIndicator(index: Int, isActive: Bool, isAccent: Bool) -> some View {
        let fillColor: Color = isActive ? (isAccent ? Color.musicianGold : Color.musicianIvory) : Color.white.opacity(0.04)
        let strokeColor: Color = isActive ? (isAccent ? Color.musicianGoldLight : Color.white.opacity(0.6)) : Color.white.opacity(0.08)
        let strokeWidth: CGFloat = isActive ? 1.0 : 0.6
        let shadowColor: Color = isActive ? Color.musicianGold.opacity(0.3) : Color.clear
        let textColor: Color = isActive ? Color.musicianEbony : Color.white.opacity(0.4)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(fillColor)
                .frame(height: 28)
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(strokeColor, lineWidth: strokeWidth))
                .shadow(color: shadowColor, radius: 4)
            
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(textColor)
        }
    }
    
    // MARK: - Logic & Actions
    
    private func changeBPM(by delta: Double) {
        let clamped = max(30.0, min(260.0, bpm + delta))
        setBPM(clamped)
    }
    
    private func setBPM(_ newBpm: Double) {
        bpm = newBpm
        onBpmChanged?(newBpm)
    }
    
    private func togglePlay() {
        if let onToggle = onToggleRunning {
            onToggle()
        } else {
            isRunning.toggle()
        }
    }
    
    private func handleTapTempo() {
        let now = Date()
        if let last = tapTimes.last, now.timeIntervalSince(last) > 2.5 {
            tapTimes.removeAll()
        }
        tapTimes.append(now)
        if tapTimes.count > 4 {
            tapTimes.removeFirst()
        }
        
        if tapTimes.count >= 2 {
            var intervals: [Double] = []
            for i in 1..<tapTimes.count {
                intervals.append(tapTimes[i].timeIntervalSince(tapTimes[i - 1]))
            }
            let avg = intervals.reduce(0, +) / Double(intervals.count)
            if avg > 0 {
                let calculated = round(60.0 / avg)
                let clamped = max(30.0, min(260.0, calculated))
                setBPM(clamped)
            }
        }
    }
    
    @MainActor
    private func runMetronomeLoop() async {
        fireBeatTick()

        while isRunning {
            let intervalSec = 60.0 / bpm
            let halfInterval = intervalSec / 2.0

            withAnimation(.easeInOut(duration: halfInterval)) {
                pendulumAngle = (activeBeatIndex % 2 == 0) ? -18.0 : 18.0
            }

            try? await Task.sleep(nanoseconds: UInt64(halfInterval * 1_000_000_000))
            guard isRunning else { break }

            withAnimation(.easeInOut(duration: halfInterval)) {
                pendulumAngle = (activeBeatIndex % 2 == 0) ? 18.0 : -18.0
            }

            try? await Task.sleep(nanoseconds: UInt64(halfInterval * 1_000_000_000))
            guard isRunning else { break }

            currentBeat = (currentBeat + 1) % beatsPerBar
            fireBeatTick()
        }
    }

    private func fireBeatTick() {
        let isAccent = (activeBeatIndex == 0)
        onTickSound?(isAccent)
        triggerPulseRing()
    }

    private func triggerPulseRing() {
        pulseScale = 1.0
        pulseOpacity = 0.75
        withAnimation(.easeOut(duration: 0.35)) {
            pulseScale = 1.42
            pulseOpacity = 0.0
        }
    }
}

#Preview {
    MetronomeDialView(
        bpm: .constant(120),
        isRunning: .constant(true)
    )
    .frame(width: 820)
    .padding()
}
