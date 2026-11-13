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

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header & Meter Bar
                HStack(spacing: 14) {
                    Text("Metronome")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)

                    Spacer()

                    LuxuryDropdown(
                        selection: $selectedSignature,
                        options: TimeSignaturePreset.allCases.map {
                            LuxuryDropdownOption(value: $0, title: $0.rawValue)
                        },
                        minWidth: 160,
                        popoverWidth: 210
                    )
                    .onChange(of: selectedSignature) { _, newSig in
                        appState.metronomeTimeSignature = newSig.signature
                        if appState.isMetronomePlaying {
                            appState.metronomeEngine?.start(bpm: appState.metronomeBPM, timeSignature: newSig.signature)
                        }
                    }

                    LuxuryDropdown(
                        selection: $selectedSubdivision,
                        options: SubdivisionType.allCases.map {
                            LuxuryDropdownOption(value: $0, title: $0.rawValue)
                        },
                        minWidth: 185,
                        popoverWidth: 230
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
                    beatsPerBar: selectedSignature.signature.beats,
                    beatTick: appState.currentBeatTick,
                    onBpmChanged: { newBpm in
                        appState.setBPM(newBpm)
                    },
                    onToggleRunning: {
                        appState.toggleMetronome()
                    }
                )

                // Tempo Markings Strip
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tempo Markings")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)

                    HStack(spacing: 10) {
                        ForEach(MetronomePresets.standard) { preset in
                            Button(action: {
                                withAnimation(StudioMotion.snappyControl) {
                                    appState.setBPM(preset.bpm)
                                }
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
                            .studioPressable()
                        }
                    }
                    .animation(StudioMotion.snappyControl, value: appState.metronomeBPM)
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Speed Trainer
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle(isOn: $isSpeedTrainerActive) {
                            Text("Speed Trainer")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color.musicianIvory)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.musicianGold)

                        Spacer()

                        if isSpeedTrainerActive {
                            Text("+\(Int(speedTrainerIncrement)) BPM every \(speedTrainerBarsInterval) bars")
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

                            Button(action: {
                                withAnimation(StudioMotion.snappyControl) {
                                    appState.setBPM(speedTrainerStartBPM)
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Set Start BPM")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(Color.musicianGoldLight)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Color.musicianGold.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.musicianGold.opacity(0.32), lineWidth: 0.8)
                                )
                            }
                            .studioPressable()
                            .transition(.studioSection)
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
                .animation(StudioMotion.cardGlide, value: isSpeedTrainerActive)
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
    }
}

