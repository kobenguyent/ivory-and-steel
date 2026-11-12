import SwiftUI

@main
struct IvoryAndSteelApp: App {
    @State private var appState: AppState
    
    init() {
        let audio = AudioEngine.shared
        let metronome = MetronomeEngine.shared
        let state = AppState(audioEngine: audio, metronomeEngine: metronome)
        
        // Link CoreMIDI Manager callbacks
        MIDIManager.shared.onNoteOn = { [weak state] midi, velocity in
            state?.handleMIDINoteOn(midi: midi, velocity: velocity)
        }
        MIDIManager.shared.onNoteOff = { [weak state] midi in
            state?.handleMIDINoteOff(midi: midi)
        }
        MIDIManager.shared.onDevicesChanged = { [weak state] devices in
            DispatchQueue.main.async {
                state?.connectedMIDIDevices = devices
            }
        }
        state.connectedMIDIDevices = MIDIManager.shared.connectedDevices
        
        // Link Metronome tick callback
        metronome.onBeatTick = { [weak state] beatIndex, isDownbeat in
            DispatchQueue.main.async {
                state?.currentBeatTick = beatIndex
                state?.isDownbeatTick = isDownbeat
            }
        }
        
        _appState = State(initialValue: state)
    }
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appState)
                .frame(minWidth: 1080, minHeight: 720)
                .background(Color.musicianEbony)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // Studio Menu: Tab switching keyboard shortcuts ⌘1 - ⌘7
            CommandMenu("Studio") {
                Button("Theory Explorer") {
                    appState.selectTab(.theoryExplorer)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Virtual Piano") {
                    appState.selectTab(.virtualPiano)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Guitar Fretboard") {
                    appState.selectTab(.guitarFretboard)
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Metronome") {
                    appState.selectTab(.metronome)
                }
                .keyboardShortcut("4", modifiers: .command)
                
                Button("Practice Routine") {
                    appState.selectTab(.practiceRoutine)
                }
                .keyboardShortcut("5", modifiers: .command)
                
                Button("Masterclass Tips") {
                    appState.selectTab(.masterclassHub)
                }
                .keyboardShortcut("6", modifiers: .command)
                
                Button("Level Quiz") {
                    appState.selectTab(.musicianQuiz)
                }
                .keyboardShortcut("7", modifiers: .command)
            }
            
            // Audio Controls: ⌥⌘M for mute, Space for metronome
            CommandMenu("Audio") {
                Button(appState.isMuted ? "Unmute Master Audio" : "Mute Master Audio") {
                    appState.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [.option, .command])
                
                Button(appState.isMetronomePlaying ? "Stop Metronome" : "Start Metronome") {
                    appState.toggleMetronome()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Divider()
                
                Button("Increase BPM (+5)") {
                    appState.setBPM(appState.metronomeBPM + 5)
                }
                .keyboardShortcut("=", modifiers: .command)
                
                Button("Decrease BPM (-5)") {
                    appState.setBPM(appState.metronomeBPM - 5)
                }
                .keyboardShortcut("-", modifiers: .command)
            }
        }
        
        // MenuBarExtra with persistent status bar item
        MenuBarExtra("Ivory & Steel", systemImage: "pianokeys") {
            MenuBarExtraView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
