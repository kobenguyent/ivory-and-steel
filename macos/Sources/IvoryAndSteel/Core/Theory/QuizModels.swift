import Foundation

// MARK: - Conservatory Assessment Domains (6 Pillars)

/// Six harmonic & musicianship pillars tracked in Conservatory Competency Diagnostics.
public enum QuizDomain: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case auralIntervals = "aural_intervals"
    case auralChordsAndInversions = "aural_chords"
    case auralModesAndScales = "aural_modes"
    case auralCadences = "aural_cadences"
    case theoryAndSpelling = "theory_spelling"
    case instrumentCraft = "instrument_craft"

    public var id: String { rawValue }

    /// Human-facing conservatory pillar title.
    public var displayName: String {
        switch self {
        case .auralIntervals: return "Aural Intervals"
        case .auralChordsAndInversions: return "Chords & Inversions"
        case .auralModesAndScales: return "Scales & Modes"
        case .auralCadences: return "Harmonic Cadences"
        case .theoryAndSpelling: return "Theory & Spelling"
        case .instrumentCraft: return "Instrument Craft"
        }
    }

    /// Short pill label used in compact progress headers.
    public var shortTag: String {
        switch self {
        case .auralIntervals: return "Intervals"
        case .auralChordsAndInversions: return "Harmony"
        case .auralModesAndScales: return "Modes"
        case .auralCadences: return "Cadences"
        case .theoryAndSpelling: return "Spelling"
        case .instrumentCraft: return "Craft"
        }
    }

    /// SF Symbol representing this diagnostic pillar.
    public var sfSymbol: String {
        switch self {
        case .auralIntervals: return "ear"
        case .auralChordsAndInversions: return "music.note.list"
        case .auralModesAndScales: return "waveform.path"
        case .auralCadences: return "arrow.triangle.branch"
        case .theoryAndSpelling: return "textformat.abc"
        case .instrumentCraft: return "pianokeys"
        }
    }

    /// Difficulty weight multiplier contributed toward weighted conservatory scoring.
    public var domainWeight: Double {
        switch self {
        case .auralIntervals: return 1.00
        case .auralChordsAndInversions: return 1.15
        case .auralModesAndScales: return 1.10
        case .auralCadences: return 1.20
        case .theoryAndSpelling: return 1.05
        case .instrumentCraft: return 1.00
        }
    }

    /// Whether this domain primarily tests active aural listening.
    public var isAuralDomain: Bool {
        switch self {
        case .auralIntervals, .auralChordsAndInversions, .auralModesAndScales, .auralCadences:
            return true
        case .theoryAndSpelling, .instrumentCraft:
            return false
        }
    }
}

// MARK: - Conservatory Study Modes & Difficulty

/// Four structured assessment modes in the Conservatory Quiz Studio.
public enum QuizStudyMode: String, CaseIterable, Identifiable, Codable, Sendable, Hashable {
    case placementExam = "Placement Exam"
    case earTrainingLab = "Ear Training Lab"
    case theoryAndHarmony = "Theory & Harmony"
    case instrumentCraft = "Instrument Craft"

    public var id: String { rawValue }

    public var subtitle: String {
        switch self {
        case .placementExam:
            return "Balanced 12-question assessment across ear training, theory, and technique"
        case .earTrainingLab:
            return "Recognize intervals, chord qualities, scales, and cadences by ear"
        case .theoryAndHarmony:
            return "Key signatures, chord spelling, inversions, and harmonic progressions"
        case .instrumentCraft:
            return "Piano touch, guitar technique, and fretboard fundamentals"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .placementExam: return "music.quarternote.3"
        case .earTrainingLab: return "headphones"
        case .theoryAndHarmony: return "music.note.list"
        case .instrumentCraft: return "pianokeys"
        }
    }
}

/// Filterable conservatory difficulty tiers with weighted score multipliers.
public enum QuizDifficulty: String, CaseIterable, Identifiable, Codable, Sendable, Hashable {
    case all = "all"
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return "All Levels"
        case .beginner: return "Foundational"
        case .intermediate: return "Conservatory"
        case .advanced: return "Virtuoso"
        }
    }

    /// Point weight assigned to a question at this difficulty tier.
    public static func weight(for rawLevel: String) -> Double {
        switch rawLevel.lowercased() {
        case "advanced", "master", "mastery": return 1.50
        case "intermediate": return 1.25
        default: return 1.00
        }
    }
}

// MARK: - Audio Cue Models

/// Articulation style for live diagnostic audio playback.
public enum AudioPlaybackStyle: String, Codable, Sendable, Hashable {
    case melodic
    case harmonic
    case arpeggiated
    case chordProgression
    case scale
}

/// Encapsulates notes or chord progressions playable in the Quiz Audio Audition Deck & A/B compare strip.
public struct QuizAudioCue: Codable, Sendable, Equatable, Hashable {
    public let style: AudioPlaybackStyle
    public let notes: [String]
    public let progressions: [[String]]?
    public let referenceRootNote: String?
    public let stepDuration: Double
    public let isGuitar: Bool

    public init(
        style: AudioPlaybackStyle,
        notes: [String] = [],
        progressions: [[String]]? = nil,
        referenceRootNote: String? = nil,
        stepDuration: Double = 0.42,
        isGuitar: Bool = false
    ) {
        self.style = style
        self.notes = notes
        self.progressions = progressions
        self.referenceRootNote = referenceRootNote
        self.stepDuration = stepDuration
        self.isGuitar = isGuitar
    }
}

// MARK: - Enriched Quiz Question Model (100% Backward Compatible with QuizData.json)

/// Multi-modal conservatory assessment question supporting curated JSON items and procedurally generated questions.
public struct QuizQuestionModel: Codable, Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let instrument: String
    public let level: String
    public let question: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String
    public let relatedTipId: String?

    // Optional Conservatory Metadata & Multi-Modal Extensions
    public let domain: QuizDomain?
    public let audioCue: QuizAudioCue?
    public let visualNotes: [String]?
    public let visualRoot: String?
    public let visualIntervals: [String]?
    public let visualPreferFlat: Bool?
    public let revealVisualBeforeAnswer: Bool?
    public let optionComparisonCues: [QuizAudioCue]?
    public let formulaBadge: String?
    public let isGenerated: Bool?

    public init(
        id: String,
        instrument: String,
        level: String,
        question: String,
        options: [String],
        correctIndex: Int,
        explanation: String,
        relatedTipId: String? = nil,
        domain: QuizDomain? = nil,
        audioCue: QuizAudioCue? = nil,
        visualNotes: [String]? = nil,
        visualRoot: String? = nil,
        visualIntervals: [String]? = nil,
        visualPreferFlat: Bool? = nil,
        revealVisualBeforeAnswer: Bool? = nil,
        optionComparisonCues: [QuizAudioCue]? = nil,
        formulaBadge: String? = nil,
        isGenerated: Bool? = nil
    ) {
        self.id = id
        self.instrument = instrument
        self.level = level
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.relatedTipId = relatedTipId
        self.domain = domain
        self.audioCue = audioCue
        self.visualNotes = visualNotes
        self.visualRoot = visualRoot
        self.visualIntervals = visualIntervals
        self.visualPreferFlat = visualPreferFlat
        self.revealVisualBeforeAnswer = revealVisualBeforeAnswer
        self.optionComparisonCues = optionComparisonCues
        self.formulaBadge = formulaBadge
        self.isGenerated = isGenerated
    }

    /// Resolves explicit `domain` or infers a sensible pillar for legacy curated items.
    public var resolvedDomain: QuizDomain {
        if let domain { return domain }
        if audioCue != nil {
            let lower = question.lowercased()
            if lower.contains("cadence") || lower.contains("progression") { return .auralCadences }
            if lower.contains("mode") || lower.contains("scale") { return .auralModesAndScales }
            if lower.contains("interval") { return .auralIntervals }
            return .auralChordsAndInversions
        }
        let lower = question.lowercased()
        if lower.contains("tritone") || lower.contains("spell") || lower.contains("signature") ||
            lower.contains("voice leading") || lower.contains("ii-v-i") || lower.contains("inversion") ||
            lower.contains("diminished") || lower.contains("enharmonic") || lower.contains("leading tone") {
            return .theoryAndSpelling
        }
        return .instrumentCraft
    }

    /// Difficulty weight multiplier for weighted grading.
    public var difficultyWeight: Double {
        QuizDifficulty.weight(for: level)
    }

    /// Normalized notes suitable for post-answer visual keyboard reveal when available.
    public var resolvedVisualNotes: [String] {
        if let visualNotes, !visualNotes.isEmpty {
            return visualNotes
        }
        if let audioCue, !audioCue.notes.isEmpty {
            return audioCue.notes
        }
        if let finalChord = audioCue?.progressions?.last {
            return finalChord
        }
        return []
    }
}

// MARK: - Conservatory Grading & Domain Telemetry

/// Conservatory evaluation tier derived from weighted accuracy.
public struct ConservatoryGradeTier: Sendable, Equatable {
    public let title: String
    public let standing: String
    public let summary: String

    public static func evaluate(weightedPercentage: Double) -> ConservatoryGradeTier {
        if weightedPercentage >= 90.0 {
            return ConservatoryGradeTier(
                title: "Conservatory Laureate",
                standing: "Distinction",
                summary: "Commanding ear-to-theory fluency, enharmonic precision, and concert-grade harmonic awareness."
            )
        }
        if weightedPercentage >= 75.0 {
            return ConservatoryGradeTier(
                title: "Concert Harmonicist",
                standing: "Merit",
                summary: "Strong command of functional progressions, intervals, and diatonic spelling with minor advanced edge gaps."
            )
        }
        if weightedPercentage >= 55.0 {
            return ConservatoryGradeTier(
                title: "Lyric Practitioner",
                standing: "Pass",
                summary: "Solid foundational musicianship; targeted drills on weaker harmonic pillars will sharpen fluency."
            )
        }
        return ConservatoryGradeTier(
            title: "Apprentice Musician",
            standing: "Developing",
            summary: "Building core intervallic hearing and spelling reflexes. Focus on Ear Training Lab & Masterclass breakdowns."
        )
    }
}

/// Per-pillar accuracy breakdown saved alongside quiz history and rendered in the 6-pillar radar/bar scorecard.
public struct DomainPerformanceRecord: Codable, Identifiable, Sendable, Equatable, Hashable {
    public var id: String { domain.rawValue }
    public let domain: QuizDomain
    public let correct: Int
    public let total: Int

    public init(domain: QuizDomain, correct: Int, total: Int) {
        self.domain = domain
        self.correct = correct
        self.total = total
    }

    public var accuracy: Double {
        guard total > 0 else { return 0 }
        return (Double(correct) / Double(total)) * 100.0
    }
}
