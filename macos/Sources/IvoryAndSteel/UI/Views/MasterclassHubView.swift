import SwiftUI

// MARK: - Masterclass Tip Decodable Model

public struct MasterclassTipModel: Codable, Identifiable, Sendable {
    public let id: String
    public let slug: String?
    public let title: String
    public let instrument: String
    public let level: String
    public let category: String
    public let summary: String
    public let detailedExplanation: String
    public let practicalExercise: PracticalExerciseModel?
    public let proSecret: String?
    public let commonMistake: String?
    public let tags: [String]?
    
    public struct PracticalExerciseModel: Codable, Sendable {
        public let title: String
        public let steps: [String]
        public let tempoBpm: Int?
        public let recommendedDurationMinutes: Int?
    }
}

/// Masterclass Library Studio View:
/// Clean Master-Detail editorial library with search, instrument/level filters,
/// bookmark persistence, Practice Routine handoff, and AppState cross-tab deep links.
public struct MasterclassHubView: View {
    @Environment(AppState.self) private var appState

    @State private var allTips: [MasterclassTipModel] = []
    @State private var searchQuery: String = ""
    @State private var selectedInstrument: String = "all"
    @State private var selectedLevel: String = "all"
    @State private var showBookmarksOnly: Bool = false
    @State private var selectedTipId: String? = nil
    @State private var addedToRoutineTipId: String? = nil

    public init() {}

    private var filteredTips: [MasterclassTipModel] {
        allTips.filter { tip in
            if showBookmarksOnly && !StorageManager.shared.isBookmarked(tipId: tip.id) {
                return false
            }
            if selectedInstrument != "all" && tip.instrument.lowercased() != selectedInstrument.lowercased() {
                return false
            }
            if selectedLevel != "all" && tip.level.lowercased() != selectedLevel.lowercased() {
                return false
            }
            if !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                let matchTitle = tip.title.lowercased().contains(query)
                let matchSummary = tip.summary.lowercased().contains(query)
                let matchExplanation = tip.detailedExplanation.lowercased().contains(query)
                let matchSecret = tip.proSecret?.lowercased().contains(query) ?? false
                return matchTitle || matchSummary || matchExplanation || matchSecret
            }
            return true
        }
    }

    private var selectedTip: MasterclassTipModel? {
        if let selectedTipId, let matched = filteredTips.first(where: { $0.id == selectedTipId }) {
            return matched
        }
        return filteredTips.first
    }

    public var body: some View {
        VStack(spacing: 14) {
            filterHeaderBar

            if filteredTips.isEmpty {
                emptyStateView
            } else {
                contentSplitView
            }
        }
        .padding(20)
        .background(Color.musicianEbony)
        .onAppear {
            loadTips()
            syncSelectedFromAppState()
        }
        .onChange(of: appState.masterclassSelectedTipId) { _, _ in
            syncSelectedFromAppState()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundColor(Color.gray)
            Text("No masterclass notes match your filter.")
                .font(.system(size: 13))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentSplitView: some View {
        HStack(alignment: .top, spacing: 16) {
            masterIndexPane

            if let tip = selectedTip {
                TipDetailReaderView(
                    tip: tip,
                    justAddedToRoutine: addedToRoutineTipId == tip.id,
                    onAddToRoutine: { addTipToRoutine(tip) },
                    onOpenInRoutine: { appState.selectTab(.practiceRoutine) },
                    onOpenMetronomeBPM: { bpm in appState.openMetronome(atBPM: bpm) }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var masterIndexPane: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredTips) { tip in
                    TipIndexRow(
                        tip: tip,
                        isSelected: selectedTip?.id == tip.id,
                        onSelect: { selectTip(tip.id) }
                    )
                }
            }
            .padding(8)
        }
        .frame(width: 310)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func selectTip(_ id: String) {
        withAnimation(StudioMotion.snappyControl) {
            selectedTipId = id
            appState.masterclassSelectedTipId = id
        }
    }

    private func addTipToRoutine(_ tip: MasterclassTipModel) {
        let minutes = tip.practicalExercise?.recommendedDurationMinutes ?? 5
        let bpm = tip.practicalExercise?.tempoBpm.map { Double($0) }
        let stepSummary = tip.practicalExercise?.steps.first ?? tip.summary
        appState.addTaskToPracticeRoutine(
            title: tip.title,
            details: stepSummary,
            estimatedMinutes: minutes,
            targetBPM: bpm,
            navigate: false
        )
        withAnimation(StudioMotion.snappyControl) {
            addedToRoutineTipId = tip.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if addedToRoutineTipId == tip.id {
                withAnimation(StudioMotion.softHover) {
                    addedToRoutineTipId = nil
                }
            }
        }
    }

    private var filterHeaderBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(Color.musicianGold)

                TextField("Search masterclass topics...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 32)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8))

            LuxuryDropdown(
                selection: $selectedInstrument,
                options: [
                    LuxuryDropdownOption(value: "all", title: "All Instruments"),
                    LuxuryDropdownOption(value: "piano", title: "Piano"),
                    LuxuryDropdownOption(value: "guitar", title: "Guitar")
                ],
                minWidth: 145,
                popoverWidth: 190
            )

            LuxuryDropdown(
                selection: $selectedLevel,
                options: [
                    LuxuryDropdownOption(value: "all", title: "All Levels"),
                    LuxuryDropdownOption(value: "beginner", title: "Beginner"),
                    LuxuryDropdownOption(value: "intermediate", title: "Intermediate"),
                    LuxuryDropdownOption(value: "advanced", title: "Advanced")
                ],
                minWidth: 130,
                popoverWidth: 175
            )

            Button(action: { showBookmarksOnly.toggle() }) {
                HStack(spacing: 5) {
                    Image(systemName: showBookmarksOnly ? "bookmark.fill" : "bookmark")
                    Text("Saved")
                }
                .font(.system(size: 11.5, weight: .semibold))
                .padding(.horizontal, 11)
                .frame(height: 32)
                .foregroundColor(showBookmarksOnly ? Color.musicianEbony : Color.musicianIvory)
                .background(showBookmarksOnly ? Color.musicianGold : Color.musicianSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8))
            }
            .studioPressable()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func syncSelectedFromAppState() {
        if let deepLinkId = appState.masterclassSelectedTipId,
           allTips.contains(where: { $0.id == deepLinkId }) {
            selectedInstrument = "all"
            selectedLevel = "all"
            searchQuery = ""
            showBookmarksOnly = false
            selectedTipId = deepLinkId
        } else if selectedTipId == nil {
            selectedTipId = allTips.first?.id
        }
    }

    private func loadTips() {
        if let decoded = ResourceLoader.decodeJSON([MasterclassTipModel].self, resource: "TipsData") {
            self.allTips = decoded
        }
    }
}

// MARK: - Master Index Row

private struct TipIndexRow: View {
    let tip: MasterclassTipModel
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .serif))
                    .foregroundColor(isSelected ? Color.musicianGold : Color.musicianIvory)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(tip.instrument.capitalized) · \(tip.level.capitalized)")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.musicianGold.opacity(0.11) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(isSelected ? Color.musicianGold.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(StudioMotion.softHover) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Editorial Detail Reader

private struct TipDetailReaderView: View {
    let tip: MasterclassTipModel
    let justAddedToRoutine: Bool
    let onAddToRoutine: () -> Void
    let onOpenInRoutine: () -> Void
    let onOpenMetronomeBPM: (Double) -> Void

    @State private var isBookmarked: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(tip.instrument.capitalized) · \(tip.level.capitalized) · \(tip.category.capitalized)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.musicianGold)

                        Text(tip.title)
                            .font(.system(size: 21, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(StudioMotion.snappyControl) {
                            StorageManager.shared.toggleBookmark(tipId: tip.id)
                            isBookmarked = StorageManager.shared.isBookmarked(tipId: tip.id)
                        }
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15))
                            .foregroundColor(isBookmarked ? Color.musicianGold : Color.gray)
                    }
                    .studioPressable()
                    .help(isBookmarked ? "Remove bookmark" : "Save topic")
                }

                // Summary Lead
                Text(tip.summary)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(Color.musicianIvory.opacity(0.9))
                    .lineSpacing(4)

                Divider().background(Color.hairlineDivider)

                // Overview
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)

                    Text(tip.detailedExplanation)
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.musicianIvory.opacity(0.82))
                        .lineSpacing(4)
                }

                // Key Insight
                if let insight = tip.proSecret, !insight.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Key Insight")
                            .font(.system(size: 12.5, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianGold)

                        Text(insight)
                            .font(.system(size: 12))
                            .foregroundColor(Color.musicianIvory.opacity(0.88))
                            .lineSpacing(3.5)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.musicianGold.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.musicianGold.opacity(0.2), lineWidth: 0.8))
                }

                // Guided Exercise
                if let exercise = tip.practicalExercise {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Exercise · \(exercise.title)")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color.subdominantEmerald)

                            Spacer()

                            if let bpm = exercise.tempoBpm {
                                Button(action: { onOpenMetronomeBPM(Double(bpm)) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "metronome.fill")
                                            .font(.system(size: 9.5))
                                        Text("\(bpm) BPM")
                                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                    }
                                    .foregroundColor(Color.musicianGold)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Color.musicianGold.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .studioPressable()
                            }
                        }

                        ForEach(Array(exercise.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1).")
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.subdominantEmerald)
                                Text(step)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.musicianIvory.opacity(0.85))
                                    .lineSpacing(3)
                            }
                        }

                        HStack(spacing: 10) {
                            Button(action: onAddToRoutine) {
                                HStack(spacing: 5) {
                                    Image(systemName: justAddedToRoutine ? "checkmark" : "plus")
                                        .font(.system(size: 10.5, weight: .bold))
                                    Text(justAddedToRoutine ? "Added to Routine" : "Add to Practice Routine")
                                        .font(.system(size: 11.5, weight: .semibold))
                                }
                                .foregroundColor(justAddedToRoutine ? Color.musicianEbony : Color.musicianIvory)
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background(justAddedToRoutine ? Color.subdominantEmerald : Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .studioPressable()

                            if justAddedToRoutine {
                                Button(action: onOpenInRoutine) {
                                    Text("View Routine →")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .foregroundColor(Color.musicianGold)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(14)
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Common Pitfall
                if let mistake = tip.commonMistake, !mistake.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Common Pitfall")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(Color.gray)

                        Text(mistake)
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                            .lineSpacing(3)
                    }
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .onAppear {
            isBookmarked = StorageManager.shared.isBookmarked(tipId: tip.id)
        }
        .onChange(of: tip.id) { _, newId in
            isBookmarked = StorageManager.shared.isBookmarked(tipId: newId)
        }
    }
}

