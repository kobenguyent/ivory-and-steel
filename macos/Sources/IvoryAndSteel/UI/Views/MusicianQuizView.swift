import SwiftUI

/// Conservatory Music Theory & Aural Diagnostic Studio:
/// 4 study modes, live acoustic Steinway/Luthier audio audition deck with Harmonic/Arpeggio toggle,
/// post-answer A/B audio comparison & interactive keybed reveal, Masterclass lesson sheet,
/// keyboard shortcuts (A-D / 1-4, R replay, Return next), and 6-pillar Competency Scorecard.
public struct MusicianQuizView: View {
    @Environment(AppState.self) private var appState

    // Curated JSON banks
    @State private var curatedQuestions: [QuizQuestionModel] = []
    @State private var masterclassTipsById: [String: MasterclassTipModel] = [:]

    // Session & Mode Configuration
    @State private var studyMode: QuizStudyMode = .placementExam
    @State private var filterInstrument: String = "all"
    @State private var filterDifficulty: QuizDifficulty = .all
    @State private var activeFocusDomain: QuizDomain? = nil
    @State private var isReviewingMissed: Bool = false

    // Active Session State
    @State private var sessionQuestions: [QuizQuestionModel] = []
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isAnswerSubmitted: Bool = false
    @State private var answerRecords: [Int: Bool] = [:]
    @State private var missedQuestionIds: [String] = []
    @State private var score: Int = 0
    @State private var earnedWeightedPoints: Double = 0.0
    @State private var totalWeightedPoints: Double = 0.0
    @State private var isQuizFinished: Bool = false

    // Audio & Lesson UI State
    @State private var preferArpeggioPlayback: Bool = false
    @State private var audioPulseToken: Int = 0
    @State private var activeLessonTip: MasterclassTipModel? = nil
    @State private var pastResults: [QuizResultRecord] = []
    @State private var showPastResultsSheet: Bool = false

    public init() {}

    private var currentQuestion: QuizQuestionModel? {
        guard !sessionQuestions.isEmpty, currentIndex < sessionQuestions.count else { return nil }
        return sessionQuestions[currentIndex]
    }

    private var weightedPercentage: Double {
        guard totalWeightedPoints > 0 else {
            guard !sessionQuestions.isEmpty else { return 0 }
            return (Double(score) / Double(sessionQuestions.count)) * 100.0
        }
        return min(100.0, (earnedWeightedPoints / totalWeightedPoints) * 100.0)
    }

    private var gradeTier: ConservatoryGradeTier {
        ConservatoryGradeTier.evaluate(weightedPercentage: weightedPercentage)
    }

    private var sessionDomainScores: [DomainPerformanceRecord] {
        var tally: [QuizDomain: (correct: Int, total: Int)] = [:]
        for (idx, question) in sessionQuestions.enumerated() {
            let domain = question.resolvedDomain
            var entry = tally[domain] ?? (0, 0)
            entry.total += 1
            if answerRecords[idx] == true {
                entry.correct += 1
            }
            tally[domain] = entry
        }
        return QuizDomain.allCases.compactMap { domain in
            guard let stats = tally[domain], stats.total > 0 else { return nil }
            return DomainPerformanceRecord(domain: domain, correct: stats.correct, total: stats.total)
        }
    }

    private var weakestDomainScore: DomainPerformanceRecord? {
        sessionDomainScores
            .filter { $0.correct < $0.total }
            .min { lhs, rhs in
                if lhs.accuracy == rhs.accuracy {
                    return lhs.domain.domainWeight > rhs.domain.domainWeight
                }
                return lhs.accuracy < rhs.accuracy
            }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                quizHeaderBar

                if !sessionQuestions.isEmpty && !isQuizFinished {
                    segmentedProgressRail
                }

                Group {
                    if isQuizFinished {
                        quizFinishedScorecard
                            .transition(.studioPage)
                    } else if let q = currentQuestion {
                        activeQuestionCard(q)
                            .id(q.id)
                            .transition(.studioPage)
                    } else {
                        emptyBankPlaceholder
                    }
                }
                .animation(StudioMotion.sheetReveal, value: isQuizFinished)
                .animation(StudioMotion.sheetReveal, value: currentIndex)
            }
            .padding(20)
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .background(Color.musicianEbony)
        .focusable(true)
        .focusEffectDisabled()
        .onKeyPress(phases: .down) { press in
            handleKeyShortcut(press)
        }
        .onAppear {
            loadResourcesIfNeeded()
            pastResults = StorageManager.shared.quizResults
            if sessionQuestions.isEmpty {
                rebuildSession()
            }
        }
        .onDisappear {
            appState.stopQuizPlayback()
        }
        .sheet(item: $activeLessonTip) { tip in
            MasterclassLessonModal(
                tip: tip,
                onOpenInLibrary: {
                    let id = tip.id
                    activeLessonTip = nil
                    appState.openMasterclassTopic(id: id)
                },
                onDismiss: {
                    activeLessonTip = nil
                }
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPastResultsSheet) {
            pastResultsSheetContent
        }
    }

    // MARK: - Conservatory Control Header & Mode Ribbon

    private var quizHeaderBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    headerTitleBlock
                    Spacer(minLength: 12)
                    headerFilterControls
                }

                VStack(alignment: .leading, spacing: 12) {
                    headerTitleBlock
                    headerFilterControls
                }
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // 4 Conservatory Study Mode Pills + Optional Focus Tag (adapts cleanly on narrow frames)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuizStudyMode.allCases) { mode in
                        let isSelected = studyMode == mode && activeFocusDomain == nil && !isReviewingMissed
                        Button(action: {
                            guard studyMode != mode || activeFocusDomain != nil || isReviewingMissed else { return }
                            activeFocusDomain = nil
                            isReviewingMissed = false
                            studyMode = mode
                            rebuildSession()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: mode.sfSymbol)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(mode.rawValue)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundColor(isSelected ? Color.musicianEbony : Color.musicianIvory.opacity(0.85))
                            .background(isSelected ? Color.musicianGold : Color.musicianSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(isSelected ? Color.musicianGoldLight : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .contentShape(Capsule())
                        }
                        .studioPressable()
                    }

                    if let focus = activeFocusDomain {
                        focusModeTag(label: "Drill: \(focus.shortTag)") {
                            activeFocusDomain = nil
                            rebuildSession()
                        }
                    } else if isReviewingMissed {
                        focusModeTag(label: "Missed Review (\(sessionQuestions.count))") {
                            isReviewingMissed = false
                            rebuildSession()
                        }
                    }
                }
            }

            Text(activeFocusDomain.map { "Targeted Mastery Drill · Focus on \($0.displayName)" }
                 ?? (isReviewingMissed ? "Remediation Pass · Re-testing missed questions with live visual & audio feedback" : studyMode.subtitle))
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
        }
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.musicianGold.opacity(0.18), lineWidth: 1)
        )
    }

    private var headerTitleBlock: some View {
        Text("Theory & Ear Quiz")
            .font(.system(size: 16, weight: .bold, design: .serif))
            .foregroundColor(Color.musicianIvory)
    }

    private var headerFilterControls: some View {
        HStack(spacing: 10) {
            if !pastResults.isEmpty {
                Button(action: { showPastResultsSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                        Text("History (\(pastResults.count))")
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
                selection: $filterInstrument,
                options: [
                    LuxuryDropdownOption(value: "all", title: "All Instruments"),
                    LuxuryDropdownOption(value: "piano", title: "Piano"),
                    LuxuryDropdownOption(value: "guitar", title: "Guitar")
                ],
                minWidth: 150,
                popoverWidth: 195
            )
            .onChange(of: filterInstrument) { _, _ in
                activeFocusDomain = nil
                isReviewingMissed = false
                rebuildSession()
            }

            LuxuryDropdown(
                selection: $filterDifficulty,
                options: QuizDifficulty.allCases.map {
                    LuxuryDropdownOption(value: $0, title: $0.displayName)
                },
                minWidth: 136,
                popoverWidth: 180
            )
            .onChange(of: filterDifficulty) { _, _ in
                activeFocusDomain = nil
                isReviewingMissed = false
                rebuildSession()
            }

            Button(action: {
                activeFocusDomain = nil
                isReviewingMissed = false
                rebuildSession()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("New Set")
                        .font(.system(size: 11.5, weight: .bold))
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .foregroundColor(Color.musicianGold)
                .background(Color.musicianGold.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.musicianGold.opacity(0.32), lineWidth: 0.9)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .studioPressable()
            .help("Generate a new question set")
        }
    }

    private func focusModeTag(label: String, onExit: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color.subdominantEmerald)
            Button(action: onExit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.subdominantEmerald.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Exit Remediation Drill")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.subdominantEmerald.opacity(0.14))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.subdominantEmerald.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Segmented Progress Rail

    private var segmentedProgressRail: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("Question \(currentIndex + 1) of \(sessionQuestions.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.musicianGold)
                    .contentTransition(.numericText())

                if let q = currentQuestion {
                    HStack(spacing: 5) {
                        Image(systemName: q.resolvedDomain.sfSymbol)
                            .font(.system(size: 10))
                        Text(q.resolvedDomain.displayName)
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundColor(Color.musicianIvory.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 14) {
                    Text("Score: \(score)/\(currentIndex + (isAnswerSubmitted ? 1 : 0))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.musicianIvory.opacity(0.85))
                        .contentTransition(.numericText())

                    Text("Shortcuts: A–D · R Play · ⏎ Next")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.gray.opacity(0.8))
                }
            }

            HStack(spacing: 5) {
                ForEach(0..<sessionQuestions.count, id: \.self) { idx in
                    let color: Color = {
                        if let isRight = answerRecords[idx] {
                            return isRight ? Color.subdominantEmerald : Color.steinwayCrimson
                        }
                        if idx == currentIndex {
                            return Color.musicianGold
                        }
                        return Color.white.opacity(0.10)
                    }()

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(height: idx == currentIndex ? 6 : 4)
                        .animation(StudioMotion.snappyControl, value: currentIndex)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Active Question Stage

    private func activeQuestionCard(_ q: QuizQuestionModel) -> some View {
        let isCorrectSelection = (selectedOptionIndex == q.correctIndex)
        let visualNotes = q.resolvedVisualNotes
        let shouldShowVisualizerNow = (!visualNotes.isEmpty) && (q.revealVisualBeforeAnswer == true || isAnswerSubmitted)

        return VStack(alignment: .leading, spacing: 18) {
            // Card Metadata Line
            HStack(spacing: 8) {
                Text("\(q.instrument.capitalized) · \(q.level.capitalized) · \(q.resolvedDomain.shortTag)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.gray)

                Spacer()

                if isAnswerSubmitted, let badge = q.formulaBadge {
                    Text(badge)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.musicianGoldLight)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Question Prompt
            Text(q.question)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(Color.musicianIvory)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Live Audio Audition Deck
            if let cue = q.audioCue {
                audioAuditionDeck(for: cue)
            }

            // Compact Interactive Keybed Reveal (Pre-answer for Visual Chord ID, or Post-answer Reveal)
            if shouldShowVisualizerNow {
                QuizKeyboardVisualizerView(
                    highlightedNotes: visualNotes,
                    activeMidiNotes: appState.activeMidiNotes,
                    rootNote: q.visualRoot,
                    preferFlat: q.visualPreferFlat ?? false,
                    showNoteLabels: isAnswerSubmitted,
                    allowKeyClicks: isAnswerSubmitted,
                    subtitle: isAnswerSubmitted
                        ? "Harmonic Blueprint — click any key to audition pitch"
                        : "Visual Reading Mode — inspect intervals on the C4–C6 grand keybed",
                    onPlayMidi: { midi in
                        appState.playPiano(midi: midi, velocity: 0.82, duration: 1.3)
                    }
                )
                .transition(.studioSection)
            }

            // Answer Choices A–D
            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                    let comparisonCue: QuizAudioCue? = {
                        guard isAnswerSubmitted,
                              let cues = q.optionComparisonCues,
                              idx < cues.count else { return nil }
                        return cues[idx]
                    }()

                    OptionButton(
                        label: "\(Character(UnicodeScalar(65 + (idx % 26)) ?? "A"))",
                        text: option,
                        isSelected: selectedOptionIndex == idx,
                        isSubmitted: isAnswerSubmitted,
                        isCorrect: idx == q.correctIndex,
                        canAuditionOption: comparisonCue != nil,
                        onAuditionOption: {
                            if let comparisonCue {
                                triggerAudioPlayback(cue: comparisonCue)
                            }
                        },
                        onSelect: {
                            guard !isAnswerSubmitted else { return }
                            selectedOptionIndex = idx
                            submitAnswer(for: q, choice: idx)
                        }
                    )
                }
            }

            // Post-Answer Pedagogical Breakdown + A/B Compare + Masterclass Lesson
            if isAnswerSubmitted {
                postAnswerFeedbackDrawer(for: q, isCorrectSelection: isCorrectSelection)
            }
        }
        .padding(22)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.musicianGold.opacity(0.22), lineWidth: 1)
        )
        .animation(StudioMotion.cardGlide, value: isAnswerSubmitted)
    }

    private func audioAuditionDeck(for cue: QuizAudioCue) -> some View {
        let supportsArticulationToggle = !cue.notes.isEmpty && cue.style != .chordProgression && cue.style != .scale
        let effectiveStyle: AudioPlaybackStyle = supportsArticulationToggle
            ? (preferArpeggioPlayback ? .arpeggiated : (cue.style == .melodic ? .melodic : .harmonic))
            : cue.style

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                playCueButton(cue: cue, style: effectiveStyle)

                if supportsArticulationToggle {
                    articulationTogglePill(isMelodic: cue.style == .melodic)
                }

                if let refRoot = cue.referenceRootNote {
                    referenceRootButton(rootNote: refRoot, isGuitar: cue.isGuitar)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Image(systemName: appState.isMuted ? "speaker.slash.fill" : "waveform")
                        .font(.system(size: 11))
                        .foregroundColor(appState.isMuted ? Color.steinwayCrimson : Color.musicianGold)
                        .symbolEffect(.pulse, value: audioPulseToken)
                    Text(appState.isMuted ? "Audio Muted (Toolbar)" : (cue.isGuitar ? "Boutique Luthier" : "Concert Grand"))
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(appState.isMuted ? Color.steinwayCrimson : Color.gray)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    playCueButton(cue: cue, style: effectiveStyle)
                    if let refRoot = cue.referenceRootNote {
                        referenceRootButton(rootNote: refRoot, isGuitar: cue.isGuitar)
                    }
                }
                if supportsArticulationToggle {
                    articulationTogglePill(isMelodic: cue.style == .melodic)
                }
            }
        }
        .padding(12)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.musicianGold.opacity(0.28), lineWidth: 1)
        )
    }

    private func playCueButton(cue: QuizAudioCue, style: AudioPlaybackStyle) -> some View {
        Button(action: {
            triggerAudioPlayback(cue: cue, overrideStyle: style)
        }) {
            HStack(spacing: 7) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10.5, weight: .bold))
                Text(style == .chordProgression ? "Play Progression (R)" : (style == .scale ? "Play Scale (R)" : "Play Audio Cue (R)"))
                    .font(.system(size: 11.5, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundColor(Color.musicianEbony)
            .background(Color.musicianGold)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .studioPressable()
        .disabled(appState.isMuted)
    }

    private func articulationTogglePill(isMelodic: Bool) -> some View {
        HStack(spacing: 2) {
            articulationOption(title: isMelodic ? "Melodic" : "Harmonic", selected: !preferArpeggioPlayback) {
                preferArpeggioPlayback = false
            }
            articulationOption(title: "Arpeggio", selected: preferArpeggioPlayback) {
                preferArpeggioPlayback = true
            }
        }
        .padding(3)
        .background(Color.musicianEbony)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.8))
    }

    private func articulationOption(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(selected ? Color.musicianGold : Color.gray)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(selected ? Color.musicianGold.opacity(0.16) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func referenceRootButton(rootNote: String, isGuitar: Bool) -> some View {
        Button(action: {
            let midi = MusicTheoryEngine.shared.midiNote(for: rootNote)
            if isGuitar {
                appState.playGuitar(midi: midi, velocity: 0.82, duration: 1.5)
            } else {
                appState.playPiano(midi: midi, velocity: 0.82, duration: 1.4)
            }
            audioPulseToken &+= 1
        }) {
            HStack(spacing: 5) {
                Image(systemName: "tuningfork")
                    .font(.system(size: 10.5))
                Text("Ref Root (\(MusicTheoryEngine.formatNotationGlyphs(rootNote)))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .foregroundColor(Color.musicianIvory)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .studioPressable()
        .disabled(appState.isMuted)
    }

    private func postAnswerFeedbackDrawer(for q: QuizQuestionModel, isCorrectSelection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isCorrectSelection ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrectSelection ? Color.subdominantEmerald : Color.steinwayCrimson)
                    .font(.system(size: 16))
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isCorrectSelection ? "Correct" : "Incorrect")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(isCorrectSelection ? Color.subdominantEmerald : Color.steinwayCrimson)

                    Text(q.explanation)
                        .font(.system(size: 12))
                        .foregroundColor(Color.musicianIvory.opacity(0.92))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // A/B Audio Compare Strip (Hear Correct vs Hear Your Choice)
            if let cues = q.optionComparisonCues, q.correctIndex < cues.count {
                HStack(spacing: 8) {
                    Button(action: {
                        triggerAudioPlayback(cue: cues[q.correctIndex])
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "ear.badge.checkmark")
                                .font(.system(size: 11))
                            Text("Hear Correct Answer")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .foregroundColor(Color.subdominantEmerald)
                        .background(Color.subdominantEmerald.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.subdominantEmerald.opacity(0.35), lineWidth: 0.8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .studioPressable()

                    if !isCorrectSelection, let selected = selectedOptionIndex, selected < cues.count {
                        Button(action: {
                            triggerAudioPlayback(cue: cues[selected])
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "waveform.badge.exclamationmark")
                                    .font(.system(size: 11))
                                Text("Hear Your Choice")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .foregroundColor(Color.steinwayCrimson)
                            .background(Color.steinwayCrimson.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.steinwayCrimson.opacity(0.35), lineWidth: 0.8))
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .studioPressable()
                    }
                }
            }

            // Footer Actions: Linked Masterclass Lesson + Next Question
            HStack(spacing: 12) {
                if let tipId = q.relatedTipId, let tip = masterclassTipsById[tipId] {
                    Button(action: {
                        activeLessonTip = tip
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 11))
                            Text("Masterclass Lesson: \(tip.title)")
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundColor(Color.musicianGold)
                        .background(Color.musicianGold.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.musicianGold.opacity(0.3), lineWidth: 0.8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .studioPressable()
                }

                Spacer()

                Button(action: nextQuestion) {
                    HStack(spacing: 6) {
                        Text(currentIndex + 1 < sessionQuestions.count ? "Next Question" : "View Conservatory Scorecard")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .foregroundColor(Color.musicianEbony)
                    .background(Color.musicianGold)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .studioPressable()
            }
        }
        .padding(14)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isCorrectSelection ? Color.subdominantEmerald.opacity(0.28) : Color.steinwayCrimson.opacity(0.28), lineWidth: 0.9)
        )
        .transition(.studioSection)
    }

    // MARK: - 6-Pillar Conservatory Competency Scorecard

    private var quizFinishedScorecard: some View {
        let rawPct = Int((Double(score) / Double(max(1, sessionQuestions.count))) * 100.0)
        let weightedPctRounded = Int(weightedPercentage.rounded())
        let tier = gradeTier
        let missedItems = sessionQuestions.filter { missedQuestionIds.contains($0.id) }

        return VStack(spacing: 22) {
            VStack(spacing: 10) {
                Image(systemName: "rosette")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(Color.musicianGold)
                    .shadow(color: Color.musicianGold.opacity(0.45), radius: 12)

                Text(tier.standing.uppercased())
                    .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.musicianGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.musicianGold.opacity(0.14))
                    .clipShape(Capsule())

                Text(tier.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Text(tier.summary)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
            }

            // Telemetry Summary Cards
            HStack(spacing: 14) {
                scoreMetricTile(
                    label: "WEIGHTED MASTERY",
                    value: "\(weightedPctRounded)%",
                    accent: Color.musicianGold
                )
                scoreMetricTile(
                    label: "RAW ACCURACY",
                    value: "\(score) / \(sessionQuestions.count) (\(rawPct)%)",
                    accent: Color.subdominantEmerald
                )
                scoreMetricTile(
                    label: "STUDY MODE",
                    value: studyMode.rawValue,
                    accent: Color.musicianGoldLight
                )
            }

            // Competency Breakdown Bars
            if !sessionDomainScores.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Competency Breakdown")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(Color.musicianGold)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 12)], spacing: 12) {
                        ForEach(sessionDomainScores) { domainPerf in
                            domainCompetencyCard(domainPerf)
                        }
                    }
                }
                .padding(16)
                .background(Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            }

            // Remediation & Continuation Action Suite
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    scorecardActions(missedItems: missedItems)
                }
                VStack(spacing: 10) {
                    scorecardActions(missedItems: missedItems)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.musicianGold.opacity(0.32), lineWidth: 1)
        )
    }
    @ViewBuilder
    private func scorecardActions(missedItems: [QuizQuestionModel]) -> some View {
        if let weak = weakestDomainScore {
            Button(action: {
                isReviewingMissed = false
                activeFocusDomain = weak.domain
                rebuildSession()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                    Text("Drill Weakest Pillar: \(weak.domain.shortTag)")
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(Color.musicianEbony)
                .background(Color.musicianGold)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .contentShape(RoundedRectangle(cornerRadius: 9))
            }
            .studioPressable()
        }

        if !missedItems.isEmpty {
            Button(action: {
                startMissedReviewSession(missedItems)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("Review Missed (\(missedItems.count))")
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(Color.musicianIvory)
                .background(Color.steinwayCrimson.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.steinwayCrimson.opacity(0.5), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 9))
            }
            .studioPressable()
        }

        Button(action: {
            activeFocusDomain = nil
            isReviewingMissed = false
            rebuildSession()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                Text("Generate Fresh Set")
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundColor(Color.musicianGold)
            .background(Color.musicianGold.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.musicianGold.opacity(0.35), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .studioPressable()
    }

    private func scoreMetricTile(label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                .foregroundColor(Color.gray)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent.opacity(0.22), lineWidth: 0.8))
    }

    private func domainCompetencyCard(_ record: DomainPerformanceRecord) -> some View {
        let pct = record.accuracy
        let barColor: Color = pct >= 80 ? Color.subdominantEmerald : (pct >= 50 ? Color.musicianGold : Color.steinwayCrimson)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: record.domain.sfSymbol)
                        .font(.system(size: 11))
                        .foregroundColor(barColor)
                    Text(record.domain.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.musicianIvory)
                }
                Spacer()
                Text("\(record.correct)/\(record.total) (\(Int(pct))%)")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(6, geo.size.width * CGFloat(pct / 100.0)))
                }
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.white.opacity(0.05), lineWidth: 0.8))
    }

    // MARK: - Past Results & Empty State

    private var emptyBankPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 28))
                .foregroundColor(Color.musicianGold)
            Text("No questions match the current filter combination.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.musicianIvory)
            Button("Reset to Balanced Placement Exam") {
                filterInstrument = "all"
                filterDifficulty = .all
                activeFocusDomain = nil
                studyMode = .placementExam
                rebuildSession()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.musicianGold)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var pastResultsSheetContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quiz History")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                Spacer()
                Button(action: { showPastResultsSheet = false }) {
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
                pastAssessmentList
            }
            .frame(maxHeight: 360)
        }
        .padding(22)
        .frame(width: 560)
        .background(Color.musicianEbony)
        .preferredColorScheme(.dark)
    }

    private var pastAssessmentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Past Assessment Results")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)
                Spacer()
                Button("Clear History") {
                    StorageManager.shared.clearQuizResults()
                    pastResults = []
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(Color.gray)
            }

            ForEach(pastResults.prefix(5)) { res in
                HStack(spacing: 10) {
                    Image(systemName: "rosette")
                        .foregroundColor(Color.musicianGold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(res.levelName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.musicianIvory)
                        if let mode = res.mode {
                            Text(mode)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.gray)
                        }
                    }

                    Spacer()

                    if let wp = res.weightedPercentage {
                        Text("\(Int(wp.rounded()))% wt")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.subdominantEmerald)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.subdominantEmerald.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text("\(res.score)/\(res.totalQuestions)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.musicianGold)

                    Text(res.date.formatted(date: .abbreviated, time: .shortened))
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Actions, Shortcuts & Resource Loading

    private func triggerAudioPlayback(cue: QuizAudioCue, overrideStyle: AudioPlaybackStyle? = nil) {
        audioPulseToken &+= 1
        appState.playQuizCue(cue, overrideStyle: overrideStyle)
    }

    private func submitAnswer(for question: QuizQuestionModel, choice: Int) {
        let isCorrect = (choice == question.correctIndex)
        withAnimation(StudioMotion.cardGlide) {
            isAnswerSubmitted = true
            answerRecords[currentIndex] = isCorrect
            totalWeightedPoints += question.difficultyWeight
            if isCorrect {
                score += 1
                earnedWeightedPoints += question.difficultyWeight
            } else if !missedQuestionIds.contains(question.id) {
                missedQuestionIds.append(question.id)
            }
        }

        // Only play celebratory chime for non-aural questions so it never muddies aural pitch comparison
        if isCorrect && !question.resolvedDomain.isAuralDomain {
            appState.playPiano(midi: 72, velocity: 0.65, duration: 0.9)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.appState.playPiano(midi: 76, velocity: 0.72, duration: 1.1)
            }
        }
    }

    private func nextQuestion() {
        appState.stopQuizPlayback()
        withAnimation(StudioMotion.sheetReveal) {
            if currentIndex + 1 < sessionQuestions.count {
                currentIndex += 1
                selectedOptionIndex = nil
                isAnswerSubmitted = false
                if studyMode == .earTrainingLab, let cue = currentQuestion?.audioCue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.triggerAudioPlayback(cue: cue)
                    }
                }
            } else {
                isQuizFinished = true
                let result = QuizResultRecord(
                    score: score,
                    totalQuestions: sessionQuestions.count,
                    levelName: gradeTier.title,
                    category: filterInstrument,
                    mode: isReviewingMissed ? "Missed Review" : (activeFocusDomain.map { "Drill: \($0.displayName)" } ?? studyMode.rawValue),
                    weightedPercentage: weightedPercentage,
                    domainScores: sessionDomainScores
                )
                StorageManager.shared.addQuizResult(result)
                pastResults = StorageManager.shared.quizResults
            }
        }
    }

    private func rebuildSession() {
        appState.stopQuizPlayback()
        let count = (studyMode == .placementExam) ? 12 : 10
        let built = QuizQuestionGenerator.shared.buildSession(
            mode: studyMode,
            instrument: filterInstrument,
            difficulty: filterDifficulty,
            curatedQuestions: curatedQuestions,
            targetCount: count,
            focusDomain: activeFocusDomain
        )
        resetSessionProgress(with: built)
    }

    private func startMissedReviewSession(_ missed: [QuizQuestionModel]) {
        appState.stopQuizPlayback()
        isReviewingMissed = true
        activeFocusDomain = nil
        resetSessionProgress(with: missed)
    }

    private func resetSessionProgress(with questions: [QuizQuestionModel]) {
        withAnimation(StudioMotion.sheetReveal) {
            sessionQuestions = questions
            currentIndex = 0
            selectedOptionIndex = nil
            isAnswerSubmitted = false
            answerRecords = [:]
            missedQuestionIds = []
            score = 0
            earnedWeightedPoints = 0.0
            totalWeightedPoints = 0.0
            isQuizFinished = false
        }
    }
    private func handleKeyShortcut(_ press: KeyPress) -> KeyPress.Result {
        guard !isQuizFinished, activeLessonTip == nil, let q = currentQuestion else {
            return .ignored
        }

        if press.key == .return && isAnswerSubmitted {
            nextQuestion()
            return .handled
        }

        let charLower = press.characters.lowercased()
        if (charLower == "r" || press.key == .space), let cue = q.audioCue {
            triggerAudioPlayback(cue: cue)
            return .handled
        }

        if !isAnswerSubmitted {
            let optionIndex: Int?
            switch charLower {
            case "1", "a": optionIndex = 0
            case "2", "b": optionIndex = 1
            case "3", "c": optionIndex = 2
            case "4", "d": optionIndex = 3
            default: optionIndex = nil
            }

            if let idx = optionIndex, idx < q.options.count {
                selectedOptionIndex = idx
                submitAnswer(for: q, choice: idx)
                return .handled
            }
        }
        return .ignored
    }

    private func loadResourcesIfNeeded() {
        if curatedQuestions.isEmpty,
           let decoded = ResourceLoader.decodeJSON([QuizQuestionModel].self, resource: "QuizData") {
            self.curatedQuestions = decoded
        }

        if masterclassTipsById.isEmpty,
           let decoded = ResourceLoader.decodeJSON([MasterclassTipModel].self, resource: "TipsData") {
            self.masterclassTipsById = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        }
    }

    private func badgePill(text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }

    private func difficultyAccent(for rawLevel: String) -> Color {
        switch rawLevel.lowercased() {
        case "beginner": return Color.subdominantEmerald
        case "intermediate": return Color.musicianGoldLight
        default: return Color.steinwayCrimson
        }
    }
}

// MARK: - Option Button with Optional A/B Audition Button

private struct OptionButton: View {
    let label: String
    let text: String
    let isSelected: Bool
    let isSubmitted: Bool
    let isCorrect: Bool
    let canAuditionOption: Bool
    let onAuditionOption: () -> Void
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(alignment: .center, spacing: 12) {
                    Text(label)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected || (isSubmitted && isCorrect) ? Color.musicianEbony : Color.musicianGold)
                        .frame(width: 24, height: 24)
                        .background(isSelected || (isSubmitted && isCorrect) ? Color.musicianGold : Color.musicianGold.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(text)
                        .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(Color.musicianIvory)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    if isSubmitted {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.subdominantEmerald)
                                .transition(.scale.combined(with: .opacity))
                        } else if isSelected {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.steinwayCrimson)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .studioPressable()
            .disabled(isSubmitted)

            // Non-overlapping sibling button so hit targets stay crisp post-submission
            if canAuditionOption {
                Button(action: onAuditionOption) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isCorrect ? Color.subdominantEmerald : Color.musicianGold)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .studioPressable()
                .help("Hear \(text)")
                .padding(.trailing, 8)
            }
        }
        .background(
            isSubmitted
                ? (isCorrect ? Color.subdominantEmerald.opacity(0.15) : (isSelected ? Color.steinwayCrimson.opacity(0.15) : Color.musicianSurface))
                : (isSelected ? Color.musicianGold.opacity(0.15) : (isHovered ? Color.white.opacity(0.05) : Color.musicianSurface))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSubmitted
                        ? (isCorrect ? Color.subdominantEmerald : (isSelected ? Color.steinwayCrimson : Color.white.opacity(0.05)))
                        : (isSelected ? Color.musicianGold : (isHovered ? Color.musicianGold.opacity(0.45) : Color.white.opacity(0.08))),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Compact Interactive 2-Octave Keybed Visualizer (C4–C6)

private struct QuizKeyboardVisualizerView: View {
    let highlightedNotes: [String]
    let activeMidiNotes: Set<Int>
    let rootNote: String?
    let preferFlat: Bool
    let showNoteLabels: Bool
    let allowKeyClicks: Bool
    let subtitle: String
    let onPlayMidi: (Int) -> Void

    private var normalizedHighlights: Set<String> {
        Set(highlightedNotes.map { MusicTheoryEngine.shared.normalizeToPianoKey($0) })
    }

    private var normalizedRootPitch: String? {
        guard let rootNote else { return nil }
        return MusicTheoryEngine.shared.enharmonicEquivalent(of: rootNote).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reference Keyboard")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.musicianGold)

                Spacer()

                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color.gray)
            }

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let whiteKeys = PianoGeometry.whiteKeys
                let whiteWidth = totalWidth / CGFloat(max(1, whiteKeys.count))
                let blackWidth = totalWidth * CGFloat(PianoGeometry.blackKeyWidthPercent / 100.0)
                let blackHeight = geo.size.height * PianoGeometry.blackKeyHeightRatio

                ZStack(alignment: .topLeading) {
                    // White Keys
                    HStack(spacing: 1) {
                        ForEach(whiteKeys) { key in
                            let isLit = normalizedHighlights.contains(key.note) || activeMidiNotes.contains(key.midiNote)
                            let keyBare = String(key.note.prefix { !$0.isNumber }).uppercased()
                            let isRoot = isLit && (normalizedRootPitch == keyBare)

                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        isRoot
                                            ? Color.musicianGold
                                            : (isLit ? Color.musicianGoldLight.opacity(0.85) : Color.musicianIvory)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(isLit ? Color.musicianGold : Color.black.opacity(0.35), lineWidth: isLit ? 1.4 : 0.6)
                                    )

                                if showNoteLabels && (isLit || key.note == "C4" || key.note == "C5" || key.note == "C6") {
                                    Text(key.label)
                                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(isLit ? Color.musicianEbony : Color.black.opacity(0.55))
                                        .padding(.bottom, 5)
                                }
                            }
                            .frame(width: max(8, whiteWidth - 1))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard allowKeyClicks else { return }
                                onPlayMidi(key.midiNote)
                            }
                        }
                    }

                    // Black Keys
                    ForEach(PianoGeometry.blackKeys) { key in
                        let isLit = normalizedHighlights.contains(key.note) || activeMidiNotes.contains(key.midiNote)
                        let keyBare = String(key.note.prefix { !$0.isNumber }).uppercased()
                        let isRoot = isLit && (normalizedRootPitch == keyBare)
                        let xOffset = totalWidth * CGFloat((key.offsetPercent ?? 0) / 100.0)
                        let keyText = preferFlat ? (key.flatLabel ?? key.label) : key.label

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isRoot ? Color.musicianGold : (isLit ? Color.subdominantEmerald : Color.black))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(isLit ? Color.musicianGoldLight : Color.white.opacity(0.18), lineWidth: 0.9)
                                )

                            if showNoteLabels && isLit {
                                Text(MusicTheoryEngine.formatNotationGlyphs(String(keyText.prefix { !$0.isNumber })))
                                    .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.musicianEbony)
                                    .padding(.bottom, 4)
                            }
                        }
                        .frame(width: max(8, blackWidth), height: blackHeight)
                        .offset(x: xOffset)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard allowKeyClicks else { return }
                            onPlayMidi(key.midiNote)
                        }
                    }
                }
            }
            .frame(height: 90)
        }
        .padding(12)
        .background(Color.musicianSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Linked Masterclass Lesson Sheet

private struct MasterclassLessonModal: View {
    let tip: MasterclassTipModel
    let onOpenInLibrary: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(tip.instrument.capitalized) · \(tip.level.capitalized) · \(tip.category.capitalized)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.musicianGold)

                        Text(tip.title)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: onOpenInLibrary) {
                            Text("Open in Library →")
                                .font(.system(size: 11.5, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundColor(Color.musicianIvory)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .studioPressable()

                        Button(action: onDismiss) {
                            Text("Done")
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .foregroundColor(Color.musicianEbony)
                                .background(Color.musicianGold)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .studioPressable()
                        .keyboardShortcut(.cancelAction)
                    }
                }

                Text(tip.summary)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.musicianIvory.opacity(0.92))
                    .lineSpacing(3)

                if let insight = tip.proSecret {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Insight")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)
                        Text(insight)
                            .font(.system(size: 12))
                            .foregroundColor(Color.musicianIvory)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.musicianGold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.musicianGold.opacity(0.24), lineWidth: 0.8))
                }

                Text(tip.detailedExplanation)
                    .font(.system(size: 12.5))
                    .foregroundColor(Color.musicianIvory.opacity(0.85))
                    .lineSpacing(4)

                if let exercise = tip.practicalExercise {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise · \(exercise.title)")
                            .font(.system(size: 12.5, weight: .bold, design: .serif))
                            .foregroundColor(Color.subdominantEmerald)

                        ForEach(Array(exercise.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1).")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.subdominantEmerald)
                                Text(step)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.musicianIvory.opacity(0.9))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let mistake = tip.commonMistake {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Common Pitfall")
                            .font(.system(size: 11.5, weight: .bold, design: .serif))
                            .foregroundColor(Color.gray)
                        Text(mistake)
                            .font(.system(size: 11.5))
                            .foregroundColor(Color.gray)
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 560, minHeight: 420)
        .background(Color.musicianEbony)
    }
}
