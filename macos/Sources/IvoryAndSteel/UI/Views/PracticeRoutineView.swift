import SwiftUI

/// Guided Practice Routine Studio View:
/// Configurable deliberate practice timer, structured methodology checklist,
/// and session persistence via StorageManager.
public struct PracticeRoutineView: View {
    @Environment(AppState.self) private var appState
    
    public struct ChecklistItem: Identifiable, Equatable {
        public let id: String
        public let title: String
        public let description: String
        public var isCompleted: Bool
    }
    
    public enum RoutinePreset: String, CaseIterable, Identifiable {
        case quick15 = "Quick Warm-up (15 min)"
        case standard30 = "Daily Deliberate Practice (30 min)"
        case intense45 = "Virtuoso Masterclass (45 min)"
        case custom = "Custom Routine"
        
        public var id: String { rawValue }
        
        public var durationMinutes: Int {
            switch self {
            case .quick15: return 15
            case .standard30: return 30
            case .intense45: return 45
            case .custom: return 20
            }
        }
    }
    
    @State private var selectedPreset: RoutinePreset = .standard30
    @State private var timeRemainingSeconds: Int = 30 * 60
    @State private var totalSessionSeconds: Int = 30 * 60
    @State private var isTimerRunning: Bool = false
    @State private var sessionTimer: Timer? = nil
    
    @State private var checklist: [ChecklistItem] = [
        ChecklistItem(
            id: "step-1",
            title: "1. Slow-Motion Calibration (50% Tempo)",
            description: "Play scales and chord transitions at half speed. Focus on zero muscular tension.",
            isCompleted: false
        ),
        ChecklistItem(
            id: "step-2",
            title: "2. Isolate Problem Transitions",
            description: "Identify the 2 bars where errors occur. Loop exclusively with a metronome for 5 minutes.",
            isCompleted: false
        ),
        ChecklistItem(
            id: "step-3",
            title: "3. Harmonic Voice Leading Audiation",
            description: "Sing or mentally audiate the top melodic voice while playing chord root anchors.",
            isCompleted: false
        ),
        ChecklistItem(
            id: "step-4",
            title: "4. Dynamic Balance & Projection",
            description: "Exaggerate dynamic contrast between Forte (melody) and Pianissimo (accompaniment).",
            isCompleted: false
        ),
        ChecklistItem(
            id: "step-5",
            title: "5. Real-Time Performance Simulation",
            description: "Perform the full piece or exercise at target tempo with no restarts, embracing flow.",
            isCompleted: false
        )
    ]
    
    @State private var recentSessions: [PracticeSessionRecord] = []
    @State private var showSavedAlert: Bool = false
    
    public init() {}
    
    private var formattedTime: String {
        let minutes = timeRemainingSeconds / 60
        let seconds = timeRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressRatio: Double {
        guard totalSessionSeconds > 0 else { return 0 }
        return 1.0 - (Double(timeRemainingSeconds) / Double(totalSessionSeconds))
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Header Strip
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deliberate Practice Routine Studio")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text("Structured pedagogical workflow to turn practice hours into permanent mastery")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                    Picker("Routine", selection: $selectedPreset) {
                        ForEach(RoutinePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPreset) { _, newPreset in
                        resetTimer(to: newPreset.durationMinutes * 60)
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.musicianGold.opacity(0.2), lineWidth: 1)
                )
                
                // Timer & Controls Console
                HStack(spacing: 32) {
                    // Circular Progress & Countdown
                    ZStack {
                        Circle()
                            .stroke(Color.musicianSurface, lineWidth: 10)
                            .frame(width: 170, height: 170)
                        
                        Circle()
                            .trim(from: 0.0, to: progressRatio)
                            .stroke(
                                LinearGradient.goldGlow,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 170, height: 170)
                            .animation(.linear(duration: 1.0), value: progressRatio)
                        
                        VStack(spacing: 4) {
                            Text(formattedTime)
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.musicianIvory)
                            
                            Text(isTimerRunning ? "PRACTICING" : "PAUSED")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(isTimerRunning ? Color.musicianGoldLight : Color.white.opacity(0.4))
                        }
                    }
                    
                    // Controls & Quick Actions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Session Management")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        HStack(spacing: 12) {
                            Button(action: toggleTimer) {
                                HStack(spacing: 6) {
                                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                    Text(isTimerRunning ? "Pause" : "Start Session")
                                }
                                .font(.system(size: 11.5, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .foregroundColor(Color.musicianEbony)
                                .background(Color.musicianGold)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                resetTimer(to: selectedPreset.durationMinutes * 60)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .foregroundColor(Color.musicianIvory)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: logSessionNow) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Log Session")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .foregroundColor(Color.musicianIvory)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                appState.toggleMetronome()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "metronome.fill")
                                    Text(appState.isMetronomePlaying ? "Stop Metronome" : "Start Metronome (120 BPM)")
                                }
                                .font(.system(size: 11))
                                .foregroundColor(Color.musicianGold)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // Deliberate Practice Checklist
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Deliberate Practice Protocol")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Spacer()
                        
                        let completedCount = checklist.filter { $0.isCompleted }.count
                        Text("\(completedCount) of \(checklist.count) Completed")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach($checklist) { $item in
                            HStack(alignment: .top, spacing: 12) {
                                Button(action: {
                                    item.isCompleted.toggle()
                                }) {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 15))
                                        .foregroundColor(item.isCompleted ? Color.musicianGold : Color.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(item.isCompleted ? Color.musicianIvory : Color.white.opacity(0.75))
                                    
                                    Text(item.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.45))
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Recent Sessions History
                if !recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Practice History")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        ForEach(recentSessions.prefix(5)) { session in
                            HStack {
                                Image(systemName: "clock.badge.checkmark.fill")
                                    .foregroundColor(Color.subdominantEmerald)
                                
                                Text(session.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.musicianIvory)
                                
                                Spacer()
                                
                                Text("\(session.durationSeconds / 60) min")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.musicianGold)
                                
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(10)
                            .background(Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(16)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .onAppear {
            recentSessions = StorageManager.shared.practiceSessions
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemainingSeconds > 0 {
                self.timeRemainingSeconds -= 1
            } else {
                self.stopTimer()
                self.logSessionNow()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func resetTimer(to seconds: Int) {
        stopTimer()
        totalSessionSeconds = seconds
        timeRemainingSeconds = seconds
    }
    
    private func logSessionNow() {
        let elapsed = totalSessionSeconds - timeRemainingSeconds
        let record = PracticeSessionRecord(
            durationSeconds: max(60, elapsed),
            title: selectedPreset.rawValue,
            completedChecklistItems: checklist.filter { $0.isCompleted }.map { $0.title },
            bpm: appState.metronomeBPM
        )
        StorageManager.shared.addPracticeSession(record)
        recentSessions = StorageManager.shared.practiceSessions
    }
}

