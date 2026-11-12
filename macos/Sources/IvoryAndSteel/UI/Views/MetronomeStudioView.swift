import SwiftUI

/// Dedicated Practice Metronome Studio View:
/// Analog pendulum and circular dial, Italian tempo markings (Largo to Presto),
/// speed trainer (gradual tempo acceleration), time signatures, and polyrhythms.
public struct MetronomeStudioView: View {
    @Environment(AppState.self) private var appState
    
    public enum TimeSignaturePreset: String, CaseIterable, Identifiable, Sendable {
        case fourFour = "4/4 (Common)"
        case threeFour = "3/4 (Waltz)"
        case twoFour = "2/4 (March)"
        case sixEight = "6/8 (Compound)"
        case fiveFour = "5/4 (Odd Meter)"
        case sevenEight = "7/8 (Balkan)"
        
        public var id: String { rawValue }
        
        public var signature: (beats: Int, value: Int) {
            switch self {
            case .fourFour: return (4, 4)
            case .threeFour: return (3, 4)
            case .twoFour: return (2, 4)
            case .sixEight: return (6, 8)
            case .fiveFour: return (5, 4)
            case .sevenEight: return (7, 8)
            }
        }
    }
    
    public enum SubdivisionType: String, CaseIterable, Identifiable, Sendable {
        case quarter = "Quarter Notes (1:1)"
        case eighth = "Eighth Notes (2:1)"
        case triplet = "Eighth Triplets (3:1)"
        case sixteenth = "Sixteenth Notes (4:1)"
        case poly32 = "Polyrhythm 3:2 (Hemiola)"
        case poly43 = "Polyrhythm 4:3 (Cross-Rhythm)"
        
        public var id: String { rawValue }
    }
    
    @State private var selectedSignature: TimeSignaturePreset = .fourFour
    @State private var selectedSubdivision: SubdivisionType = .quarter
    
    // Speed Trainer Settings
    @State private var isSpeedTrainerActive: Bool = false
    @State private var speedTrainerStartBPM: Double = 80.0
    @State private var speedTrainerTargetBPM: Double = 140.0
    @State private var speedTrainerIncrement: Double = 4.0
    @State private var speedTrainerBarsInterval: Int = 4
    @State private var currentBarsElapsed: Int = 0
    
    // Tap Tempo Calculation
    @State private var tapTimes: [Date] = []
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Header Spec & Tap Tempo Strip
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sample-Accurate Mechanical & DSP Metronome")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text("Zero-jitter audio scheduling with discrete woodblock downbeat impulses")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                    // Tap Tempo Button
                    Button(action: handleTapTempo) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 12))
                            Text("Tap Tempo")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundColor(Color.musicianEbony)
                        .background(Color.musicianGold)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // Central Dial & Pendulum Display
                MetronomeDialView(
                    bpm: Binding(
                        get: { appState.metronomeBPM },
                        set: { appState.setBPM($0) }
                    ),
                    isRunning: Binding(
                        get: { appState.isMetronomePlaying },
                        set: { newValue in
                            if appState.isMetronomePlaying != newValue {
                                appState.toggleMetronome()
                            }
                        }
                    ),
                    onBpmChanged: { newBpm in
                        appState.setBPM(newBpm)
                    },
                    onToggleRunning: {
                        appState.toggleMetronome()
                    }
                )
                
                // Italian Tempo Markings Quick Selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Italian Classical Tempo Markings")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)
                    
                    HStack(spacing: 10) {
                        ForEach(MetronomePresets.standard) { preset in
                            Button(action: {
                                appState.setBPM(preset.bpm)
                            }) {
                                VStack(spacing: 4) {
                                    Text(preset.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(
                                            abs(appState.metronomeBPM - preset.bpm) < 3
                                                ? Color.musicianEbony
                                                : Color.musicianIvory
                                        )
                                    
                                    Text("\(Int(preset.bpm))")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(
                                            abs(appState.metronomeBPM - preset.bpm) < 3
                                                ? Color.musicianEbony.opacity(0.8)
                                                : Color.musicianGold
                                        )
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    abs(appState.metronomeBPM - preset.bpm) < 3
                                        ? Color.musicianGold
                                        : Color.musicianSurface
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.musicianGold.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Meter & Subdivisions
                HStack(alignment: .top, spacing: 20) {
                    // Time Signature Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Signature (Meter)")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)
                        
                        Picker("Signature", selection: $selectedSignature) {
                            ForEach(TimeSignaturePreset.allCases) { sig in
                                Text(sig.rawValue).tag(sig)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSignature) { _, newSig in
                            appState.metronomeTimeSignature = newSig.signature
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Subdivision Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rhythmic Subdivision")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)
                        
                        Picker("Subdivision", selection: $selectedSubdivision) {
                            ForEach(SubdivisionType.allCases) { sub in
                                Text(sub.rawValue).tag(sub)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Speed Trainer (Gradual Tempo Acceleration)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle(isOn: $isSpeedTrainerActive) {
                            Label("Speed Trainer (Automated Tempo Acceleration)", systemImage: "speedometer")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color.musicianIvory)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.musicianGold)
                        
                        Spacer()
                        
                        if isSpeedTrainerActive {
                            Text("Accelerating: +\(Int(speedTrainerIncrement)) BPM every \(speedTrainerBarsInterval) bars")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.musicianGold)
                        }
                    }
                    
                    if isSpeedTrainerActive {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start BPM: \(Int(speedTrainerStartBPM))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.gray)
                                Slider(value: $speedTrainerStartBPM, in: 40...160, step: 5)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target BPM: \(Int(speedTrainerTargetBPM))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.gray)
                                Slider(value: $speedTrainerTargetBPM, in: 80...240, step: 5)
                            }
                            
                            Button("Set Start BPM") {
                                appState.setBPM(speedTrainerStartBPM)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
    }
    
    private func handleTapTempo() {
        let now = Date()
        tapTimes.append(now)
        
        // Keep only taps within last 3 seconds
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        
        guard tapTimes.count >= 2 else { return }
        
        var intervals: [Double] = []
        for i in 1..<tapTimes.count {
            intervals.append(tapTimes[i].timeIntervalSince(tapTimes[i-1]))
        }
        
        let avgInterval = intervals.reduce(0.0, +) / Double(intervals.count)
        guard avgInterval > 0.15 else { return } // sanity floor 400 bpm
        
        let calculatedBpm = 60.0 / avgInterval
        appState.setBPM(round(calculatedBpm))
    }
}

