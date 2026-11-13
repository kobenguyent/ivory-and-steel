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

/// Categorized Musician Tips Library Studio View:
/// Multi-instrument filtering, level categorization, deep search,
/// and bookmark persistence via StorageManager.
public struct MasterclassHubView: View {
    @Environment(AppState.self) private var appState
    
    @State private var allTips: [MasterclassTipModel] = []
    @State private var searchQuery: String = ""
    @State private var selectedInstrument: String = "all"
    @State private var selectedLevel: String = "all"
    @State private var showBookmarksOnly: Bool = false
    @State private var expandedTipIds: Set<String> = []
    
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
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Search & Filter Bar
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.musicianGold)
                        
                        TextField("Search masterclass tips, biomechanics, exercises...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    
                    // Filter Chips Strip
                    HStack(spacing: 12) {
                        // Instrument Filter
                        Picker("Instrument", selection: $selectedInstrument) {
                            Text("All Instruments").tag("all")
                            Text("Piano Masterclass").tag("piano")
                            Text("Guitar Masterclass").tag("guitar")
                        }
                        .frame(width: 170)
                        
                        // Level Filter
                        Picker("Level", selection: $selectedLevel) {
                            Text("All Skill Levels").tag("all")
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .frame(width: 150)
                        
                        Spacer()
                        
                        // Bookmarks Toggle
                        Button(action: {
                            showBookmarksOnly.toggle()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: showBookmarksOnly ? "bookmark.fill" : "bookmark")
                                Text(showBookmarksOnly ? "Bookmarked Only" : "All Tips")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundColor(showBookmarksOnly ? Color.musicianEbony : Color.musicianGold)
                            .background(showBookmarksOnly ? Color.musicianGold : Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // Tips Cards List
                if filteredTips.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 36))
                            .foregroundColor(Color.gray)
                        Text("No masterclass tips found matching your search filter.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray)
                    }
                    .padding(40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTips) { tip in
                            TipCardView(
                                tip: tip,
                                isExpanded: expandedTipIds.contains(tip.id),
                                onToggleExpand: {
                                    if expandedTipIds.contains(tip.id) {
                                        expandedTipIds.remove(tip.id)
                                    } else {
                                        expandedTipIds.insert(tip.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .onAppear {
            loadTips()
        }
    }
    
    private func loadTips() {
        if let decoded = ResourceLoader.decodeJSON([MasterclassTipModel].self, resource: "TipsData") {
            self.allTips = decoded
        }
    }
}

// MARK: - Individual Tip Card

private struct TipCardView: View {
    let tip: MasterclassTipModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    @State private var isBookmarked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tip.instrument.uppercased())
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.musicianGold.opacity(0.15))
                            .foregroundColor(Color.musicianGold)
                            .clipShape(Capsule())
                        
                        Text(tip.level.capitalized)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.gray)
                        
                        Text(tip.category.capitalized)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color.gray.opacity(0.8))
                    }
                    
                    Text(tip.title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(Color.musicianIvory)
                }
                
                Spacer()
                
                // Bookmark Button
                Button(action: {
                    StorageManager.shared.toggleBookmark(tipId: tip.id)
                    isBookmarked = StorageManager.shared.isBookmarked(tipId: tip.id)
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundColor(isBookmarked ? Color.musicianGold : Color.gray)
                }
                .buttonStyle(.plain)
            }
            
            // Summary Text
            Text(tip.summary)
                .font(.system(size: 12))
                .foregroundColor(Color.musicianIvory.opacity(0.85))
                .lineSpacing(2)
            
            // Pro Secret Golden Banner
            if let proSecret = tip.proSecret {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(Color.musicianGold)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PRO SECRET")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.musicianGold)
                        Text(proSecret)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.musicianIvory)
                    }
                }
                .padding(10)
                .background(Color.musicianGold.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.musicianGold.opacity(0.25), lineWidth: 0.8)
                )
            }
            
            // Expanded Detailed Explanation & Practical Exercise
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.musicianGold.opacity(0.2))
                    
                    Text(tip.detailedExplanation)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.musicianIvory.opacity(0.8))
                        .lineSpacing(3)
                    
                    if let exercise = tip.practicalExercise {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(Color.subdominantEmerald)
                                Text("PRACTICAL EXERCISE: \(exercise.title.uppercased())")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.subdominantEmerald)
                            }
                            
                            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(idx + 1).")
                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.subdominantEmerald)
                                    Text(step)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.musicianIvory.opacity(0.85))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.musicianSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if let mistake = tip.commonMistake {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.steinwayCrimson)
                                .font(.system(size: 11))
                                .padding(.top, 2)
                            
                            Text("Common Trap: \(mistake)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.gray)
                        }
                    }
                }
                .transition(.opacity)
            }
            
            // Expand / Collapse Footer Button
            Button(action: onToggleExpand) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Read Full Masterclass Breakdown")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.musicianGold)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.musicianGold.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            isBookmarked = StorageManager.shared.isBookmarked(tipId: tip.id)
        }
    }
}

