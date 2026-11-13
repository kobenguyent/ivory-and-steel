import SwiftUI

/// Guided Practice Routine Studio View:
/// Configurable deliberate practice timer, interactive musical practice todolist
/// with inline creation, focus mode, BPM sync, and persistent storage via StorageManager.
public struct PracticeRoutineView: View {
    @Environment(AppState.self) private var appState
    @Namespace private var routineNS
    @FocusState private var isAddTitleFocused: Bool
    
    public enum RoutinePreset: String, CaseIterable, Identifiable {
        case quick15 = "Quick Warm-up (15 min)"
        case standard30 = "Daily Practice (30 min)"
        case intense45 = "Extended Session (45 min)"
        case custom = "Custom Session"

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
    
    public enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "To Do"
        case completed = "Done"
        
        public var id: String { rawValue }
    }
    
    @State private var selectedPreset: RoutinePreset = .standard30
    @State private var timeRemainingSeconds: Int = 30 * 60
    @State private var totalSessionSeconds: Int = 30 * 60
    @State private var isTimerRunning: Bool = false
    @State private var sessionTimer: Timer? = nil
    
    @State private var tasks: [PracticeChecklistTask] = []
    @State private var taskFilter: TaskFilter = .all
    @State private var focusedTaskId: String? = nil
    
    // Quick Inline Task Composer State
    @State private var isComposerOpen: Bool = false
    @State private var newTaskTitle: String = ""
    @State private var newTaskDetails: String = ""
    @State private var newTaskMinutes: Int? = 5
    @State private var attachCurrentBPM: Bool = false
    
    @State private var recentSessions: [PracticeSessionRecord] = []
    @State private var showSavedToast: Bool = false
    @State private var isDurationResetHovered: Bool = false
    @State private var showHistorySheet: Bool = false
    
    public init() {}
    
    // MARK: - Derived State
    
    private var formattedTime: String {
        let minutes = timeRemainingSeconds / 60
        let seconds = timeRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressRatio: Double {
        guard totalSessionSeconds > 0 else { return 0 }
        return 1.0 - (Double(timeRemainingSeconds) / Double(totalSessionSeconds))
    }
    
    private var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var checklistProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }
    
    private var remainingPlannedMinutes: Int {
        tasks.filter { !$0.isCompleted }.compactMap { $0.estimatedMinutes }.reduce(0, +)
    }
    
    private var filteredTasks: [PracticeChecklistTask] {
        switch taskFilter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }
    
    private var focusedTask: PracticeChecklistTask? {
        guard let focusedTaskId else { return nil }
        return tasks.first { $0.id == focusedTaskId }
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerStrip
                sessionTimerConsole
                practiceProtocolCard
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .sheet(isPresented: $showHistorySheet) {
            practiceHistorySheetContent
        }
        .onAppear {
            loadInitialState()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - 1. Top Header Strip

    private var headerStrip: some View {
        HStack(spacing: 12) {
            Text("Practice Routine")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)

            Spacer()

            if !recentSessions.isEmpty {
                Button(action: { showHistorySheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                        Text("History (\(recentSessions.count))")
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .padding(.horizontal, 11)
                    .frame(height: 30)
                    .foregroundColor(Color.musicianIvory.opacity(0.85))
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.glassBorder, lineWidth: 0.8))
                }
                .studioPressable()
            }

            LuxuryDropdown(
                selection: $selectedPreset,
                options: RoutinePreset.allCases.map {
                    LuxuryDropdownOption(
                        value: $0,
                        title: $0.rawValue,
                        badge: "\($0.durationMinutes)m"
                    )
                },
                minWidth: 215,
                popoverWidth: 268
            )
            .onChange(of: selectedPreset) { _, newPreset in
                resetTimer(to: newPreset.durationMinutes * 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.goldHairline, lineWidth: 1)
        )
    }
    
    // MARK: - 2. Timer & Session Management Console
    
    private var sessionTimerConsole: some View {
        HStack(spacing: 28) {
            // Circular Progress & Countdown Dial
            ZStack {
                Circle()
                    .stroke(Color.musicianSurface, lineWidth: 10)
                    .frame(width: 164, height: 164)
                
                Circle()
                    .trim(from: 0.0, to: progressRatio)
                    .stroke(
                        LinearGradient.goldGlow,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 164, height: 164)
                    .shadow(color: isTimerRunning ? Color.musicianGold.opacity(0.32) : .clear, radius: 6)
                    .animation(.linear(duration: 1.0), value: progressRatio)
                
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 33, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.musicianIvory)
                        .contentTransition(.numericText())
                        .animation(StudioMotion.snappyControl, value: formattedTime)
                    
                    Text(timeRemainingSeconds == 0 ? "COMPLETE" : (isTimerRunning ? "PRACTICING" : "PAUSED"))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(isTimerRunning ? Color.musicianGoldLight : Color.white.opacity(0.42))
                        .animation(StudioMotion.snappyControl, value: isTimerRunning)
                }
            }
            
            // Session Controls & Active Focus Banner
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text("Session Management")
                        .font(.system(size: 13.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)
                    
                    if showSavedToast {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Session Logged")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(Color.subdominantEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.subdominantEmerald.opacity(0.14))
                        .clipShape(Capsule())
                        .transition(.studioPill)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Unified Studio Duration Console (-5m | Target | +5m)
                    if !isTimerRunning {
                        sessionDurationStepper
                            .transition(.studioPill)
                    } else {
                        activeSessionTargetBadge
                            .transition(.studioPill)
                    }
                }
                
                if let focus = focusedTask {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Color.musicianGold)
                            .frame(width: 6, height: 6)
                        Text("Active Focus:")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color.musicianGoldLight)
                        Text(focus.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.musicianIvory)
                            .lineLimit(1)
                        
                        Button(action: {
                            withAnimation(StudioMotion.snappyControl) {
                                focusedTaskId = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.45))
                                .padding(3)
                        }
                        .buttonStyle(.plain)
                        .help("Clear active focus")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.musicianGold.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(Color.goldHairline, lineWidth: 0.7)
                    )
                    .transition(.studioPill)
                }
                
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(StudioMotion.snappyControl) {
                            toggleTimer()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                            Text(isTimerRunning ? "Pause" : "Start Session")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .foregroundColor(Color.musicianEbony)
                        .background(LinearGradient.goldGlow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: Color.musicianGold.opacity(isTimerRunning ? 0.3 : 0.16), radius: 6, y: 1)
                    }
                    .studioPressable()
                    
                    Button(action: {
                        withAnimation(StudioMotion.snappyControl) {
                            resetTimer(to: selectedPreset.durationMinutes * 60)
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .foregroundColor(Color.musicianIvory)
                        .background(Color.glassSurfaceHover)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.glassBorder, lineWidth: 0.8)
                        )
                    }
                    .studioPressable()
                    
                    Button(action: {
                        withAnimation(StudioMotion.cardGlide) {
                            logSessionNow()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Session")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .foregroundColor(Color.musicianIvory)
                        .background(Color.white.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                    }
                    .studioPressable()
                }
                
                Button(action: {
                    withAnimation(StudioMotion.snappyControl) {
                        appState.toggleMetronome()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 10.5))
                        Text(appState.isMetronomePlaying
                             ? "Stop Metronome (\(Int(appState.metronomeBPM)) BPM)"
                             : "Start Metronome (\(Int(appState.metronomeBPM)) BPM)")
                            .font(.system(size: 11, weight: .semibold))
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(appState.isMetronomePlaying ? Color.musicianEbony : Color.musicianGoldLight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appState.isMetronomePlaying ? Color.musicianGold : Color.musicianGold.opacity(0.11))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.musicianGold.opacity(0.28), lineWidth: 0.7)
                    )
                }
                .studioPressable()
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        )
        .animation(StudioMotion.snappyControl, value: focusedTaskId)
        .animation(StudioMotion.snappyControl, value: showSavedToast)
    }
    
    // MARK: - Unified Session Duration Console Stepper (-5m | Target | +5m)
    
    private var targetMinutes: Int {
        totalSessionSeconds / 60
    }
    
    private var isCustomDuration: Bool {
        targetMinutes != selectedPreset.durationMinutes
    }
    
    private var sessionDurationStepper: some View {
        HStack(spacing: 8) {
            Text("DURATION")
                .font(.system(size: 8.5, weight: .bold))
                .tracking(0.9)
                .foregroundColor(Color.white.opacity(0.42))
            
            HStack(spacing: 0) {
                DurationStepSegment(
                    label: "-5m",
                    accessibilityText: "Decrease session duration by 5 minutes",
                    isDisabled: totalSessionSeconds <= 5 * 60
                ) {
                    adjustSessionMinutes(by: -5)
                }
                
                Rectangle()
                    .fill(Color.hairlineDivider)
                    .frame(width: 0.7, height: 16)
                
                Button(action: {
                    guard isCustomDuration else { return }
                    withAnimation(StudioMotion.snappyControl) {
                        resetTimer(to: selectedPreset.durationMinutes * 60)
                    }
                }) {
                    HStack(spacing: 4) {
                        if isCustomDuration {
                            Circle()
                                .fill(Color.musicianGold)
                                .frame(width: 4.5, height: 4.5)
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.48))
                        }
                        
                        Text("\(targetMinutes)m")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isCustomDuration ? Color.musicianGoldLight : Color.musicianIvory)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 9)
                    .frame(height: 30)
                    .background(isDurationResetHovered && isCustomDuration ? Color.glassSurfaceHover : Color.clear)
                    .contentShape(Rectangle())
                }
                .studioPressable(scale: 0.96)
                .onHover { hovering in
                    withAnimation(StudioMotion.softHover) {
                        isDurationResetHovered = hovering
                    }
                }
                .help(isCustomDuration
                      ? "Click to reset to preset duration (\(selectedPreset.durationMinutes)m)"
                      : "Session duration: \(targetMinutes) minutes")
                .accessibilityLabel("Session target \(targetMinutes) minutes")
                
                Rectangle()
                    .fill(Color.hairlineDivider)
                    .frame(width: 0.7, height: 16)
                
                DurationStepSegment(
                    label: "+5m",
                    accessibilityText: "Increase session duration by 5 minutes",
                    isDisabled: totalSessionSeconds >= 120 * 60
                ) {
                    adjustSessionMinutes(by: 5)
                }
            }
            .frame(height: 30)
            .background(Color.musicianSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isCustomDuration ? Color.goldHairline : Color.glassBorder, lineWidth: 0.85)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 3, y: 1)
        }
    }
    
    private var activeSessionTargetBadge: some View {
        Text("Goal: \(targetMinutes)m")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(Color.gray)
    }

    private var protocolHeaderTitleCluster: some View {
        HStack(spacing: 8) {
            Text("Practice Checklist")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)

            Text(
                remainingPlannedMinutes > 0
                    ? "\(completedCount) of \(tasks.count) · \(remainingPlannedMinutes)m remaining"
                    : "\(completedCount) of \(tasks.count) done"
            )
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(completedCount == tasks.count && !tasks.isEmpty ? Color.subdominantEmerald : Color.gray)
            .contentTransition(.numericText())
        }
    }
    
    private var protocolHeaderControlsCluster: some View {
        HStack(spacing: 8) {
            // Sliding Filter Pill (All / To Do / Done)
            HStack(spacing: 2) {
                ForEach(TaskFilter.allCases) { filter in
                    let isSelected = (taskFilter == filter)
                    Button(action: {
                        withAnimation(StudioMotion.snappyControl) {
                            taskFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? Color.musicianIvory : Color.white.opacity(0.5))
                            .padding(.horizontal, 9)
                            .frame(height: 24)
                            .contentShape(Rectangle())
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.11))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6)
                                        )
                                        .matchedGeometryEffect(id: "routine_filter_pill", in: routineNS)
                                }
                            }
                    }
                    .studioPressable()
                }
            }
            .padding(2)
            .background(Color.musicianSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.glassBorder, lineWidth: 0.8)
            )
            
            if completedCount > 0 {
                Button(action: {
                    withAnimation(StudioMotion.snappyControl) {
                        uncheckAllTasks()
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .background(Color.musicianSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(Color.glassBorder, lineWidth: 0.8)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                }
                .studioPressable()
                .help("Uncheck all tasks for a fresh session")
                .accessibilityLabel("Uncheck all tasks")
                .transition(.studioPill)
            }
            
            if tasks != PracticeChecklistTask.defaultProtocol {
                Button(action: {
                    withAnimation(StudioMotion.cardGlide) {
                        restoreDefaultProtocol()
                    }
                }) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .background(Color.musicianSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(Color.glassBorder, lineWidth: 0.8)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                }
                .studioPressable()
                .help("Restore curated 5-step deliberate practice protocol")
                .accessibilityLabel("Restore default practice protocol")
                .transition(.studioPill)
            }
            
            Button(action: {
                withAnimation(StudioMotion.cardGlide) {
                    isComposerOpen.toggle()
                    if isComposerOpen {
                        isAddTitleFocused = true
                    }
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: isComposerOpen ? "xmark" : "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text(isComposerOpen ? "Close" : "Add Task")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(isComposerOpen ? Color.musicianIvory : Color.musicianEbony)
                .padding(.horizontal, 11)
                .frame(height: 28)
                .background(isComposerOpen ? Color.white.opacity(0.1) : Color.musicianGold)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .contentShape(RoundedRectangle(cornerRadius: 7))
            }
            .studioPressable()
        }
    }
    
    // MARK: - 3. Enhanced Deliberate Practice Todolist
    
    private var practiceProtocolCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Protocol Header Row (Responsive across narrow split-views and wide displays)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    protocolHeaderTitleCluster
                    Spacer(minLength: 12)
                    protocolHeaderControlsCluster
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    protocolHeaderTitleCluster
                    HStack {
                        protocolHeaderControlsCluster
                        Spacer(minLength: 0)
                    }
                }
            }
            
            // Sleek Checklist Completion Progress Rail
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.musicianSurface)
                    
                    Capsule()
                        .fill(
                            completedCount == tasks.count && !tasks.isEmpty
                                ? LinearGradient(colors: [Color.subdominantEmerald, Color.musicianGoldLight], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient.goldGlow
                        )
                        .frame(width: max(0, geo.size.width * checklistProgress))
                        .animation(StudioMotion.cardGlide, value: checklistProgress)
                }
            }
            .frame(height: 3.5)
            
            // Inline Quick Task Composer
            if isComposerOpen {
                inlineTaskComposer
                    .transition(.studioSection)
            }
            
            // Filtered Task Rows or Calm Empty State
            if filteredTasks.isEmpty {
                emptyTasksBanner
                    .transition(.studioSection)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTasks) { task in
                        let fullIndex = tasks.firstIndex(where: { $0.id == task.id })
                        PracticeTaskRow(
                            task: task,
                            isFocused: focusedTaskId == task.id,
                            isBPMMatched: task.targetBPM.map { Int($0) == Int(appState.metronomeBPM) && appState.isMetronomePlaying } ?? false,
                            canMoveUp: taskFilter == .all && (fullIndex ?? 0) > 0,
                            canMoveDown: taskFilter == .all && (fullIndex ?? tasks.count) < tasks.count - 1,
                            onToggleComplete: {
                                withAnimation(StudioMotion.snappyControl) {
                                    toggleTaskCompletion(id: task.id)
                                }
                            },
                            onToggleFocus: {
                                withAnimation(StudioMotion.snappyControl) {
                                    focusedTaskId = (focusedTaskId == task.id) ? nil : task.id
                                }
                            },
                            onSyncBPM: { bpm in
                                withAnimation(StudioMotion.snappyControl) {
                                    appState.setBPM(bpm)
                                    if !appState.isMetronomePlaying {
                                        appState.toggleMetronome()
                                    }
                                    focusedTaskId = task.id
                                }
                            },
                            onMoveUp: {
                                withAnimation(StudioMotion.cardGlide) {
                                    moveTask(id: task.id, offset: -1)
                                }
                            },
                            onMoveDown: {
                                withAnimation(StudioMotion.cardGlide) {
                                    moveTask(id: task.id, offset: 1)
                                }
                            },
                            onDelete: {
                                withAnimation(StudioMotion.cardGlide) {
                                    deleteTask(id: task.id)
                                }
                            }
                        )
                        .transition(.studioSection)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        )
        .animation(StudioMotion.cardGlide, value: isComposerOpen)
        .animation(StudioMotion.cardGlide, value: taskFilter)
    }
    
    // MARK: - Inline Composer
    
    private var inlineTaskComposer: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("New practice task (e.g. Bach Prelude mm. 1–16 RH legato)...", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(Color.musicianIvory)
                .focused($isAddTitleFocused)
                .onSubmit {
                    addNewTask()
                }
            
            TextField("Optional focus cue or articulation note...", text: $newTaskDetails)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.65))
                .onSubmit {
                    addNewTask()
                }
            
            HStack(spacing: 8) {
                // Simple Minute Chips (5m, 10m, 15m, Off)
                HStack(spacing: 4) {
                    Text("Est:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.45))
                    
                    ForEach([5, 10, 15], id: \.self) { mins in
                        let selected = newTaskMinutes == mins
                        Button("\(mins)m") {
                            withAnimation(StudioMotion.snappyControl) {
                                newTaskMinutes = selected ? nil : mins
                            }
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(selected ? Color.musicianEbony : Color.white.opacity(0.65))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(selected ? Color.musicianGold : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                
                // Optional Metronome BPM Tag
                Button(action: {
                    withAnimation(StudioMotion.snappyControl) {
                        attachCurrentBPM.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 9))
                        Text("@ \(Int(appState.metronomeBPM)) BPM")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(attachCurrentBPM ? Color.musicianEbony : Color.musicianGoldLight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(attachCurrentBPM ? Color.musicianGold : Color.musicianGold.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Add Step") {
                    addNewTask()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.musicianEbony)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.musicianGold.opacity(0.35) : Color.musicianGold)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .studioPressable()
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.goldHairline, lineWidth: 1)
        )
    }
    
    // MARK: - Empty State Banner
    
    private var emptyTasksBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: taskFilter == .active && !tasks.isEmpty ? "checkmark.seal.fill" : "music.note.list")
                .font(.system(size: 18))
                .foregroundColor(Color.musicianGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    tasks.isEmpty
                        ? "Your practice todolist is empty"
                        : (taskFilter == .active ? "All practice steps completed!" : "No completed steps yet")
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.musicianIvory)
                
                Text(
                    tasks.isEmpty
                        ? "Click + Add Task above or restore the 5-step deliberate practice protocol."
                        : (taskFilter == .active ? "Log this session or reset checks when ready for your next round." : "Check off any step as you rehearse to track progress here.")
                )
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            if taskFilter == .active && !tasks.isEmpty {
                Button("Log Session") {
                    withAnimation(StudioMotion.cardGlide) {
                        logSessionNow()
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.musicianEbony)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.musicianGold)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .studioPressable()
            }
        }
        .padding(14)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.glassBorder, lineWidth: 0.8)
        )
    }
    
    private var practiceHistorySheetContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Practice History")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                Spacer()
                Button(action: { showHistorySheet = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.musicianIvory.opacity(0.75))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }

            Divider().background(Color.hairlineDivider)

            ScrollView {
                recentHistoryCard
            }
            .frame(maxHeight: 360)
        }
        .padding(22)
        .frame(width: 560)
        .background(Color.musicianEbony)
        .preferredColorScheme(.dark)
    }

    // MARK: - 4. Recent Sessions History

    private var recentHistoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Practice History")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                
                Spacer()
                
                Text("\(recentSessions.count) Logged")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            
            ForEach(recentSessions.prefix(5)) { session in
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(Color.subdominantEmerald)
                    
                    Text(session.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.musicianIvory)
                    
                    if !session.completedChecklistItems.isEmpty {
                        Text("\(session.completedChecklistItems.count) steps")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if let bpm = session.bpm {
                        Text("\(Int(bpm)) BPM")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
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
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.glassBorderSubtle, lineWidth: 0.7)
                )
            }
        }
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Actions & Persistence
    
    private func loadInitialState() {
        tasks = StorageManager.shared.practiceTasks
        recentSessions = StorageManager.shared.practiceSessions
        if focusedTaskId == nil {
            focusedTaskId = tasks.first(where: { !$0.isCompleted })?.id
        }
    }
    
    private func persistTasks() {
        StorageManager.shared.savePracticeTasks(tasks)
    }
    
    private func toggleTaskCompletion(id: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].isCompleted.toggle()
        
        // Auto-advance active focus to next incomplete task when checking off the focused item
        if tasks[idx].isCompleted && focusedTaskId == id {
            focusedTaskId = tasks.first(where: { !$0.isCompleted })?.id
        }
        persistTasks()
    }
    
    private func addNewTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let trimmedDetails = newTaskDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTask = PracticeChecklistTask(
            title: trimmedTitle,
            details: trimmedDetails,
            estimatedMinutes: newTaskMinutes,
            targetBPM: attachCurrentBPM ? appState.metronomeBPM : nil,
            isCompleted: false
        )
        
        withAnimation(StudioMotion.cardGlide) {
            tasks.append(newTask)
            focusedTaskId = newTask.id
            if taskFilter == .completed {
                taskFilter = .all
            }
            newTaskTitle = ""
            newTaskDetails = ""
            attachCurrentBPM = false
            isComposerOpen = false
        }
        persistTasks()
    }
    
    private func moveTask(id: String, offset: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let target = idx + offset
        guard target >= 0 && target < tasks.count else { return }
        let item = tasks.remove(at: idx)
        tasks.insert(item, at: target)
        persistTasks()
    }
    
    private func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
        if focusedTaskId == id {
            focusedTaskId = tasks.first(where: { !$0.isCompleted })?.id
        }
        persistTasks()
    }
    
    private func uncheckAllTasks() {
        for idx in tasks.indices {
            tasks[idx].isCompleted = false
        }
        focusedTaskId = tasks.first?.id
        persistTasks()
    }
    
    private func restoreDefaultProtocol() {
        tasks = StorageManager.shared.resetPracticeTasksToDefault()
        focusedTaskId = tasks.first?.id
    }
    
    // MARK: - Timer Logic
    
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
    
    private func adjustSessionMinutes(by deltaMinutes: Int) {
        let newSeconds = max(5 * 60, min(120 * 60, totalSessionSeconds + deltaMinutes * 60))
        withAnimation(StudioMotion.snappyControl) {
            totalSessionSeconds = newSeconds
            timeRemainingSeconds = newSeconds
        }
    }
    
    private func logSessionNow() {
        let elapsed = totalSessionSeconds - timeRemainingSeconds
        let record = PracticeSessionRecord(
            durationSeconds: max(60, elapsed),
            title: selectedPreset.rawValue,
            completedChecklistItems: tasks.filter { $0.isCompleted }.map { $0.title },
            bpm: appState.metronomeBPM
        )
        StorageManager.shared.addPracticeSession(record)
        recentSessions = StorageManager.shared.practiceSessions
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(StudioMotion.snappyControl) {
                showSavedToast = false
            }
        }
    }
}

// MARK: - Task Row Subview

private struct PracticeTaskRow: View {
    let task: PracticeChecklistTask
    let isFocused: Bool
    let isBPMMatched: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggleComplete: () -> Void
    let onToggleFocus: () -> Void
    let onSyncBPM: (Double) -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Focus Indicator Bar (Left edge)
            RoundedRectangle(cornerRadius: 2)
                .fill(isFocused && !task.isCompleted ? Color.musicianGold : Color.clear)
                .frame(width: 3, height: 26)
            
            // Primary Row Toggle Hit Area (Checkbox + Copy fill row cleanly without nested buttons)
            Button(action: onToggleComplete) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(task.isCompleted ? Color.musicianGold : Color.white.opacity(0.001))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        task.isCompleted ? Color.musicianGold : Color.white.opacity(isHovered ? 0.55 : 0.28),
                                        lineWidth: 1.4
                                    )
                            )
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.musicianEbony)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(task.title)
                                .font(.system(size: 12.5, weight: .semibold))
                                .strikethrough(task.isCompleted, color: Color.white.opacity(0.4))
                                .foregroundColor(task.isCompleted ? Color.white.opacity(0.45) : Color.musicianIvory)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if let minutes = task.estimatedMinutes {
                                Text("· \(minutes)m")
                                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.gray)
                            }
                        }

                        if !task.details.isEmpty {
                            Text(task.details)
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(task.isCompleted ? 0.3 : 0.5))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .studioPressable(scale: 0.992)
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) incomplete" : "Complete \(task.title)")

            // Sibling BPM Sync Control
            if let bpm = task.targetBPM {
                Button(action: { onSyncBPM(bpm) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size: 9))
                        Text("\(Int(bpm))")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(isBPMMatched ? Color.musicianGold : Color.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isBPMMatched ? Color.musicianGold.opacity(0.14) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .studioPressable(scale: 0.94)
                .help("Set metronome to \(Int(bpm)) BPM & focus this step")
            }
            
            // Quick Actions (Subtle rest presence + full brightness on hover/focus)
            HStack(spacing: 4) {
                if !task.isCompleted {
                    RowActionIconButton(
                        systemImage: isFocused ? "scope" : "dot.scope",
                        tint: isFocused ? Color.musicianGold : Color.white.opacity(0.6),
                        helpText: isFocused ? "Currently focused" : "Set as active practice focus",
                        action: onToggleFocus
                    )
                }
                
                if canMoveUp {
                    RowActionIconButton(
                        systemImage: "chevron.up",
                        tint: Color.white.opacity(0.6),
                        helpText: "Move step earlier",
                        action: onMoveUp
                    )
                }
                
                if canMoveDown {
                    RowActionIconButton(
                        systemImage: "chevron.down",
                        tint: Color.white.opacity(0.6),
                        helpText: "Move step later",
                        action: onMoveDown
                    )
                }
                
                RowActionIconButton(
                    systemImage: "trash",
                    tint: Color.white.opacity(0.5),
                    helpText: "Remove task",
                    action: onDelete
                )
            }
            .opacity(isHovered || isFocused ? 1.0 : 0.35)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isFocused && !task.isCompleted
                        ? Color.musicianGold.opacity(0.06)
                        : (isHovered ? Color.glassSurfaceHover : Color.musicianSurface)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isFocused && !task.isCompleted
                        ? Color.goldHairline
                        : (isHovered ? Color.white.opacity(0.12) : Color.glassBorderSubtle),
                    lineWidth: 0.8
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
    }
}

private struct RowActionIconButton: View {
    let systemImage: String
    let tint: Color
    let helpText: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(isHovered ? Color.musicianGoldLight : tint)
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.001))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .studioPressable(scale: 0.92)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
        .help(helpText)
        .accessibilityLabel(helpText)
    }
}

private struct DurationStepSegment: View {
    let label: String
    let accessibilityText: String
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundColor(
                    isDisabled
                        ? Color.white.opacity(0.2)
                        : (isHovered ? Color.musicianGoldLight : Color.white.opacity(0.78))
                )
                .frame(width: 36, height: 30)
                .background(isHovered && !isDisabled ? Color.glassSurfaceHover : Color.white.opacity(0.001))
                .contentShape(Rectangle())
        }
        .studioPressable(scale: 0.92)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
        .help(accessibilityText)
        .accessibilityLabel(accessibilityText)
    }
}
