import SwiftUI

/// Status Bar Quick Menu for Ivory & Steel Native macOS.
/// Provides instant access to metronome controls, tempo slider, active key reference,
/// chord tone audition, and window activation.
public struct MenuBarExtraView: View {
    @Bindable var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack(spacing: 8) {
                Image(systemName: "pianokeys")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.musicianGold)
                
                Text("Ivory & Steel")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                
                Spacer()
                
                Text("\(appState.rootKey) Major")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .padding(.bottom, 2)
            
            Divider()
                .background(Color.musicianGold.opacity(0.2))
            
            // Metronome Quick Control
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Metronome", systemImage: "metronome.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.musicianIvory)
                    
                    Spacer()
                    
                    Text("\(Int(appState.metronomeBPM)) BPM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.musicianGold)
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        appState.toggleMetronome()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: appState.isMetronomePlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(appState.isMetronomePlaying ? "Stop" : "Start")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(minWidth: 64)
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appState.isMetronomePlaying ? Color.steinwayCrimson : Color.musicianGold)
                    
                    Slider(
                        value: Binding(
                            get: { appState.metronomeBPM },
                            set: { appState.setBPM($0) }
                        ),
                        in: 40...220,
                        step: 1
                    )
                }
            }
            
            Divider()
                .background(Color.musicianGold.opacity(0.2))
            
            // Active Chord Reference & Quick Audition
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Chord Reference:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    let chords = MusicTheoryEngine.shared.diatonicChords(for: appState.rootKey)
                    let tonic = chords.first?.fullName ?? "\(appState.rootKey) Major"
                    Text(tonic)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.musicianIvory)
                }
                
                let chords = MusicTheoryEngine.shared.diatonicChords(for: appState.rootKey)
                if let tonic = chords.first {
                    HStack {
                        Text("Tones: \(tonic.notes.joined(separator: " - "))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.musicianGold)
                        
                        Spacer()
                        
                        Button(action: {
                            appState.playChordVoicing(notes: tonic.notes)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 9))
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(Color.musicianGold)
                    }
                }
            }
            
            Divider()
                .background(Color.musicianGold.opacity(0.2))
            
            // Actions & Navigation
            VStack(spacing: 6) {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }) {
                    HStack {
                        Image(systemName: "macwindow")
                        Text("Open Studio Window")
                        Spacer()
                        Text("⌘O").font(.system(size: 9)).foregroundColor(.gray)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.musicianIvory)
                
                Button(action: {
                    appState.toggleMute()
                }) {
                    HStack {
                        Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        Text(appState.isMuted ? "Unmute Master Audio" : "Mute Master Audio")
                        Spacer()
                        Text("⌥⌘M").font(.system(size: 9)).foregroundColor(.gray)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(appState.isMuted ? Color.steinwayCrimson : Color.musicianIvory)
                
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    appState.checkForUpdates(userInitiated: true)
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        if let release = appState.updateStatus.availableRelease {
                            Text("Update Available (\(release.tagName))")
                        } else {
                            Text("Check for Updates…")
                        }
                        Spacer()
                        Text("v\(appState.currentAppVersion)").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(appState.updateStatus.availableRelease != nil ? Color.musicianGold : Color.musicianIvory)
                
                Divider()
                    .background(Color.musicianGold.opacity(0.2))
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Ivory & Steel")
                        Spacer()
                        Text("⌘Q").font(.system(size: 9)).foregroundColor(.gray)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.gray)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(Color.musicianEbony)
    }
}

