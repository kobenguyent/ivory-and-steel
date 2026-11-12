import SwiftUI

/// Virtual Piano Studio View: Full-width 2-octave piano console,
/// octave shift, arpeggio/strum controls, and CoreMIDI device connection status.
public struct VirtualPianoStudioView: View {
    @Environment(AppState.self) private var appState
    
    @State private var guideRoot: String = "C"
    @State private var guideScale: String = "major"
    @State private var isGuideEnabled: Bool = false
    @State private var sustainPedalDown: Bool = false
    
    private let theory = MusicTheoryEngine.shared
    
    public init() {}
    
    private var highlightedNotes: [String] {
        guard isGuideEnabled else {
            return appState.activeVoicingNotes
        }
        let scaleNotes = theory.notes(forScale: guideScale, rootKey: guideRoot)
        let octave = 4 + appState.octaveShift
        return scaleNotes.map { "\($0)\(octave)" }
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Master Console Bar
                HStack(spacing: 16) {
                    // MIDI Device Status Badge
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appState.connectedMIDIDevices.isEmpty ? Color.white.opacity(0.3) : Color.musicianGold)
                            .frame(width: 7, height: 7)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(appState.connectedMIDIDevices.isEmpty ? "MIDI: Virtual Keyboard" : "CoreMIDI: Connected")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.musicianIvory)
                            
                            Text(appState.connectedMIDIDevices.isEmpty ? "USB/Bluetooth ready" : appState.connectedMIDIDevices.joined(separator: ", "))
                                .font(.system(size: 9.5))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    // Octave Shift Control (-2 to +2)
                    HStack(spacing: 6) {
                        Text("Octave:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.gray)
                        
                        Button("-1") {
                            if appState.octaveShift > -2 { appState.octaveShift -= 1 }
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.octaveShift <= -2)
                        
                        Text(appState.octaveShift > 0 ? "+\(appState.octaveShift)" : "\(appState.octaveShift)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.musicianGold)
                            .frame(minWidth: 28)
                        
                        Button("+1") {
                            if appState.octaveShift < 2 { appState.octaveShift += 1 }
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.octaveShift >= 2)
                    }
                    
                    // Sustain Pedal Toggle
                    Button(action: {
                        sustainPedalDown.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: sustainPedalDown ? "circle.fill" : "circle")
                                .font(.system(size: 9))
                            Text("Sustain Pedal")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundColor(sustainPedalDown ? Color.musicianEbony : Color.musicianIvory)
                        .background(sustainPedalDown ? Color.musicianGold : Color.musicianSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // 12-Key Practice Guide Bar
                HStack(spacing: 12) {
                    Toggle(isOn: $isGuideEnabled) {
                        Label("12-Key Practice Guide", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.musicianGold)
                    
                    if isGuideEnabled {
                        Picker("Key", selection: $guideRoot) {
                            ForEach(KeyDefinitions.chromaticRoots, id: \.self) { root in
                                Text("Key of \(root)").tag(root)
                            }
                        }
                        .frame(width: 140)
                        
                        Picker("Scale", selection: $guideScale) {
                            ForEach(ScaleDefinitions.allScales) { scale in
                                Text(scale.name).tag(scale.id)
                            }
                        }
                        .frame(width: 180)
                    }
                    
                    Spacer()
                    
                    if !appState.activeMidiNotes.isEmpty {
                        Text("Active MIDI: \(appState.activeMidiNotes.map { String($0) }.joined(separator: ", "))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.musicianGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.musicianGold.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Full Concert Grand Piano Console (2 Octaves)
                NativePianoView(
                    highlightedNotes: highlightedNotes,
                    rootNote: isGuideEnabled ? guideRoot : appState.rootKey,
                    preferFlat: appState.preferFlat,
                    title: "Concert Grand Piano Console (C\(4 + appState.octaveShift)–C\(6 + appState.octaveShift))",
                    subtitle: isGuideEnabled
                        ? "Illuminating \(guideRoot) \(guideScale) · 12-TET Physical String Resonance Modeling"
                        : "Play using Mac Keyboard (A–K) or connected CoreMIDI Keyboard · Real-time DSP",
                    onPlayNote: { noteName, midi in
                        let shiftedMidi = midi + (appState.octaveShift * 12)
                        let duration = sustainPedalDown ? 3.5 : 1.6
                        appState.playPiano(midi: shiftedMidi, velocity: 0.85, duration: duration)
                    }
                )
                
                // Keyboard Shortcut & Performance Legend
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mac Keyboard Direct Mapping")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)
                        
                        Text("• White Keys: A (C4), S (D4), D (E4), F (F4), G (G4), H (A4), J (B4), K (C5), L (D5), ; (E5)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                        
                        Text("• Black Keys: W (C#4), E (D#4), T (F#4), Y (G#4), U (A#4), O (C#5), P (D#5)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Acoustic Touch & Expression")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)
                        
                        Text("• Steinway D harmonic overtone series modeled via discrete-time biquad filtering.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                        
                        Text("• Polyphonic 16-voice circular pool with micro-fadeout preventing click pops.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
    }
}

