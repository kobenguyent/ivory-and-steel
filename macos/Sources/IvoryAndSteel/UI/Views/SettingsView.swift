import SwiftUI

/// Settings Studio View:
/// Audio buffer size, CoreMIDI device selector, synthesis models,
/// and luxury theme preferences.
public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    @State private var bufferSize: Int = 256
    @State private var selectedSynthModel: String = "Steinway Concert Grand (Acoustic DSP)"
    @State private var selectedGuitarModel: String = "Boutique Luthier Steel String"
    @State private var selectedTheme: String = "Concert Grand Ebony"
    @State private var accidentalPreference: String = "auto"
    
    @State private var showResetAlert: Bool = false
    @State private var resetMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Bar
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Studio Engine & Hardware Preferences")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text("Configure sample-accurate AVFoundation parameters, CoreMIDI routing, and acoustic modeling")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.musicianGold.opacity(0.2), lineWidth: 1)
                )
                
                // Section 1: Audio Engine & DSP Buffer
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .foregroundColor(Color.musicianGold)
                        Text("AVFoundation Low-Latency Audio Engine")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Audio Buffer Size:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Picker("Buffer Size", selection: $bufferSize) {
                                Text("64 samples (~1.4ms ultra-fast)").tag(64)
                                Text("128 samples (~2.9ms studio)").tag(128)
                                Text("256 samples (~5.8ms standard)").tag(256)
                                Text("512 samples (~11.6ms high stability)").tag(512)
                            }
                            .frame(width: 260)
                        }
                        
                        HStack {
                            Text("Standard Sample Rate:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Text("44,100 Hz (32-bit Float Non-Interleaved)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.musicianIvory)
                        }
                        
                        HStack {
                            Text("Acoustic Reference Chime:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Button("Audition A4 (440.0 Hz)") {
                                appState.playPiano(midi: 69, velocity: 0.8, duration: 1.8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Section 2: CoreMIDI Hardware Routing
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "pianokeys.fill")
                            .foregroundColor(Color.musicianGold)
                        Text("CoreMIDI Hardware & Keyboards")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Connected CoreMIDI Sources:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Text(appState.connectedMIDIDevices.isEmpty ? "No external MIDI controller detected" : appState.connectedMIDIDevices.joined(separator: ", "))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(appState.connectedMIDIDevices.isEmpty ? Color.gray : Color.subdominantEmerald)
                        }
                        
                        HStack {
                            Text("Direct Mac Keyboard Emulation:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Text("Active (A–K white keys, W–P black keys)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.musicianGold)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Section 3: Physical Synthesis & Sound Models
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "tuningfork")
                            .foregroundColor(Color.musicianGold)
                        Text("Acoustic Modeling & Overtone Synthesis")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Piano Acoustic Model:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Picker("Piano Model", selection: $selectedSynthModel) {
                                Text("Steinway Concert Grand (Acoustic DSP)").tag("Steinway Concert Grand (Acoustic DSP)")
                                Text("Pure 12-TET Harmonic Sine").tag("Pure 12-TET Harmonic Sine")
                                Text("Bright Upright Felt").tag("Bright Upright Felt")
                            }
                            .frame(width: 280)
                        }
                        
                        HStack {
                            Text("Guitar Body Model:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Spacer()
                            
                            Picker("Guitar Model", selection: $selectedGuitarModel) {
                                Text("Boutique Luthier Steel String").tag("Boutique Luthier Steel String")
                                Text("Nylon String Classical").tag("Nylon String Classical")
                                Text("Archtop Semi-Hollow").tag("Archtop Semi-Hollow")
                            }
                            .frame(width: 280)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Section 4: Data Management & Reset
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(Color.musicianGold)
                        Text("Storage & Application Data")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Storage path: ~/Library/Application Support/IvoryAndSteel/storage.json")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 12) {
                            Button("Clear Practice Routine Logs") {
                                StorageManager.shared.clearPracticeSessions()
                                resetMessage = "Practice routine logs have been cleared."
                                showResetAlert = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Clear Quiz History") {
                                StorageManager.shared.clearQuizResults()
                                resetMessage = "Quiz assessment history has been cleared."
                                showResetAlert = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .alert(resetMessage, isPresented: $showResetAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

