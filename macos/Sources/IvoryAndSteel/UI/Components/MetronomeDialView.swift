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
    public let onBpmChanged: ((Double) -> Void)?
    public let onToggleRunning: (() -> Void)?
    public let onTickSound: ((Bool) -> Void)?
    
    @State private var timeSignatureBeats: Int = 4
    @State private var currentBeat: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var pendulumAngle: Double = 0.0
    @State private var tapTimes: [Date] = []
    
    public init(
        bpm: Binding<Double>,
        isRunning: Binding<Bool>,
        onBpmChanged: ((Double) -> Void)? = nil,
        onToggleRunning: (() -> Void)? = nil,
        onTickSound: ((Bool) -> Void)? = nil
    ) {
        self._bpm = bpm
        self._isRunning = isRunning
        self.onBpmChanged = onBpmChanged
        self.onToggleRunning = onToggleRunning
        self.onTickSound = onTickSound
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            HStack(alignment: .center, spacing: 24) {
                // Left: Analog Swinging Pendulum with Adjustable Bob
                analogPendulumCard
                    .frame(width: 220, height: 290)
                
                // Center: Digital Circular Arc Tempo Dial & Big Controls
                circularDialCard
                    .frame(maxWidth: .infinity)
                
                // Right: Time Signatures & Tempo Markings Presets
                presetsAndSignaturesCard
                    .frame(width: 240)
            }
            .padding(18)
        }
        .background(Color.musicianEbony)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.musicianGold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 10)
        // Metronome Beat Timer Loop
        .task(id: isRunning) {
            guard isRunning else {
                currentBeat = 0
                pendulumAngle = 0
                return
            }
            await runMetronomeLoop()
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "metronome.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.musicianGold)
                    .padding(6)
                    .background(Color.musicianGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Precision Studio Metronome")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text(isRunning ? "ACTIVE" : "STANDBY")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(isRunning ? Color.musicianEbony : Color.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isRunning ? Color.musicianGold : Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Text("Acoustic woodblock click · Low-jitter timer · Analog pendulum physics.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.gray)
                }
            }
            
            Spacer()
            
            // Tap Tempo Button
            Button(action: handleTapTempo) {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 10))
                    Text("TAP TEMPO")
                        .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(Color.musicianGoldLight)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.musicianGold.opacity(0.4), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianSurface.opacity(0.95))
    }
    
    // MARK: - Analog Swinging Pendulum Card
    
    private var analogPendulumCard: some View {
        VStack(spacing: 6) {
            Text("ANALOG PENDULUM")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.gray)
                .tracking(0.8)
            
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
                        currentBeat == 0 ? Color.musicianGold : Color.white.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: 170, height: 170)
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
                        // Background Arc Track
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
                        
                        // Active Progress Arc
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
                .frame(width: 170, height: 170)
                
                // Center BPM Digital Readout
                VStack(spacing: 0) {
                    Text("\(Int(bpm))")
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundColor(Color.musicianGoldLight)
                        .tracking(-1.5)
                        .shadow(color: Color.musicianGold.opacity(0.3), radius: 6)
                    
                    Text("BEATS / MINUTE")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.gray)
                        .tracking(1.0)
                }
            }
            .frame(height: 170)
            
            // Stepper Buttons (-5, -1, +1, +5)
            HStack(spacing: 8) {
                stepperButton("-5") { changeBPM(by: -5) }
                stepperButton("-1") { changeBPM(by: -1) }
                stepperButton("+1") { changeBPM(by: +1) }
                stepperButton("+5") { changeBPM(by: +5) }
            }
            
            // Big Start / Stop Toggle Button
            Button(action: togglePlay) {
                HStack(spacing: 8) {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(isRunning ? "STOP METRONOME" : "START METRONOME")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundColor(isRunning ? Color.white : Color.musicianEbony)
                .background(isRunning ? Color(hex: 0xDC2626) : Color.musicianGold)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(
                    color: isRunning ? Color.red.opacity(0.4) : Color.musicianGold.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 3
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.25), lineWidth: 0.8))
    }
    
    private func stepperButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color.musicianIvory)
                .frame(width: 44, height: 30)
                .background(Color.musicianCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Presets & Time Signatures Card
    
    private var presetsAndSignaturesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Time Signature Switcher
            VStack(alignment: .leading, spacing: 6) {
                Text("TIME SIGNATURE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.gray)
                    .tracking(0.8)
                
                HStack(spacing: 5) {
                    ForEach([2, 3, 4, 6], id: \.self) { ts in
                        Button(action: {
                            timeSignatureBeats = ts
                            currentBeat = 0
                        }) {
                            Text("\(ts)/4")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(timeSignatureBeats == ts ? Color.musicianEbony : Color.musicianIvory)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(timeSignatureBeats == ts ? Color.musicianGold : Color.musicianCharcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(timeSignatureBeats == ts ? Color.white.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.8)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Visual Beat Pulse Indicators
            VStack(alignment: .leading, spacing: 6) {
                Text("BEAT SUBDIVISIONS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.gray)
                    .tracking(0.8)
                
                HStack(spacing: 5) {
                    ForEach(0..<timeSignatureBeats, id: \.self) { idx in
                        let isActive = isRunning && currentBeat == idx
                        let isAccent = idx == 0
                        beatIndicator(index: idx, isActive: isActive, isAccent: isAccent)
                    }
                }
            }
            
            // Classical Tempo Markings Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("TEMPO MARKINGS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.gray)
                    .tracking(0.8)
                
                VStack(spacing: 4) {
                    ForEach(MetronomePresets.standard) { preset in
                        Button(action: { setBPM(preset.bpm) }) {
                            HStack {
                                Text(preset.name)
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundColor(Int(bpm) == Int(preset.bpm) ? Color.musicianGold : Color.musicianIvory)
                                
                                Spacer()
                                
                                Text("\(Int(preset.bpm)) BPM")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Int(bpm) == Int(preset.bpm) ? Color.musicianGold.opacity(0.15) : Color.musicianCharcoal.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Int(bpm) == Int(preset.bpm) ? Color.musicianGold.opacity(0.4) : Color.clear, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.8))
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
        // Play first click immediately
        fireBeatTick()
        
        while isRunning {
            let intervalSec = 60.0 / bpm
            let halfInterval = intervalSec / 2.0
            
            // Swing pendulum to one side
            withAnimation(.easeInOut(duration: halfInterval)) {
                pendulumAngle = (currentBeat % 2 == 0) ? -18.0 : 18.0
            }
            
            try? await Task.sleep(nanoseconds: UInt64(halfInterval * 1_000_000_000))
            guard isRunning else { break }
            
            withAnimation(.easeInOut(duration: halfInterval)) {
                pendulumAngle = (currentBeat % 2 == 0) ? 18.0 : -18.0
            }
            
            try? await Task.sleep(nanoseconds: UInt64(halfInterval * 1_000_000_000))
            guard isRunning else { break }
            
            currentBeat = (currentBeat + 1) % timeSignatureBeats
            fireBeatTick()
        }
    }
    
    private func fireBeatTick() {
        let isAccent = (currentBeat == 0)
        onTickSound?(isAccent)
        
        // Trigger luminous pulse ring animation
        pulseScale = 1.0
        pulseOpacity = 0.8
        withAnimation(.easeOut(duration: 0.35)) {
            pulseScale = 1.45
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
