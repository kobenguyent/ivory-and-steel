import Foundation

/// Procedural 12-key conservatory assessment generator powered by `MusicTheoryEngine`.
/// Synthesizes ear-training cues (intervals, chords, inversions, modes, cadences) and written/visual
/// theory challenges (strict 7-letter spelling, key signatures, Rule-of-9 inversions, visual keyboard ID).
public final class QuizQuestionGenerator: @unchecked Sendable {
    public static let shared = QuizQuestionGenerator()

    private let engine: MusicTheoryEngine

    public init(engine: MusicTheoryEngine = .shared) {
        self.engine = engine
    }

    // MARK: - Session Assembly

    /// Builds a structured assessment session tailored to the chosen study mode, instrument, and difficulty.
    public func buildSession(
        mode: QuizStudyMode,
        instrument: String = "all",
        difficulty: QuizDifficulty = .all,
        curatedQuestions: [QuizQuestionModel] = [],
        targetCount: Int = 10,
        focusDomain: QuizDomain? = nil
    ) -> [QuizQuestionModel] {
        // Targeted single-pillar remediation drill ("Drill Weakest Domain")
        if let focusDomain {
            return buildDomainDrill(
                domain: focusDomain,
                instrument: instrument,
                difficulty: difficulty,
                curatedQuestions: curatedQuestions,
                count: min(8, targetCount)
            )
        }

        let filteredCurated = filterCurated(curatedQuestions, instrument: instrument, difficulty: difficulty)

        switch mode {
        case .placementExam:
            return buildPlacementExam(
                curated: filteredCurated,
                instrument: instrument,
                difficulty: difficulty,
                count: max(12, targetCount)
            )
        case .earTrainingLab:
            return buildEarTrainingSession(
                instrument: instrument,
                difficulty: difficulty,
                count: targetCount
            )
        case .theoryAndHarmony:
            return buildTheoryAndHarmonySession(
                curated: filteredCurated,
                instrument: instrument,
                difficulty: difficulty,
                count: targetCount
            )
        case .instrumentCraft:
            let craftItems = filteredCurated.filter { $0.resolvedDomain == .instrumentCraft }
            if !craftItems.isEmpty {
                return Array(craftItems.prefix(targetCount))
            }
            return filteredCurated
        }
    }

    /// Builds a focused remediation drill for one specific harmonic pillar.
    public func buildDomainDrill(
        domain: QuizDomain,
        instrument: String = "all",
        difficulty: QuizDifficulty = .all,
        curatedQuestions: [QuizQuestionModel] = [],
        count: Int = 6
    ) -> [QuizQuestionModel] {
        let isGuitar = instrument.lowercased() == "guitar"
        var items: [QuizQuestionModel] = []
        let filteredCurated = filterCurated(curatedQuestions, instrument: instrument, difficulty: difficulty)
            .filter { $0.resolvedDomain == domain }

        items.append(contentsOf: filteredCurated)

        var idx = 0
        while items.count < count && idx < 24 {
            let level = resolveDifficultyForIndex(idx, requested: difficulty)
            let generated = generateQuestion(for: domain, difficulty: level, isGuitar: isGuitar, variantSeed: idx)
            if !items.contains(where: { $0.question == generated.question }) {
                items.append(generated)
            }
            idx += 1
        }
        return Array(items.prefix(count))
    }

    private func buildPlacementExam(
        curated: [QuizQuestionModel],
        instrument: String,
        difficulty: QuizDifficulty,
        count: Int
    ) -> [QuizQuestionModel] {
        let isGuitar = instrument.lowercased() == "guitar"
        var session: [QuizQuestionModel] = []

        // Guarantee balanced coverage across all 6 conservatory pillars (2 per pillar = 12)
        let domainOrder: [QuizDomain] = [
            .auralIntervals,
            .auralChordsAndInversions,
            .theoryAndSpelling,
            .auralModesAndScales,
            .auralCadences,
            .instrumentCraft
        ]

        var usedCuratedIds = Set<String>()
        for round in 0..<2 {
            for (dIdx, domain) in domainOrder.enumerated() {
                if session.count >= count { break }
                let seed = round * 7 + dIdx
                let level = resolveDifficultyForIndex(round + dIdx, requested: difficulty)

                if domain == .instrumentCraft || (domain == .theoryAndSpelling && round == 1) {
                    if let curatedMatch = curated.first(where: { $0.resolvedDomain == domain && !usedCuratedIds.contains($0.id) }) {
                        usedCuratedIds.insert(curatedMatch.id)
                        session.append(curatedMatch)
                        continue
                    }
                }
                session.append(generateQuestion(for: domain, difficulty: level, isGuitar: isGuitar, variantSeed: seed))
            }
        }
        return session
    }

    private func buildEarTrainingSession(
        instrument: String,
        difficulty: QuizDifficulty,
        count: Int
    ) -> [QuizQuestionModel] {
        let isGuitar = instrument.lowercased() == "guitar"
        let earDomains: [QuizDomain] = [
            .auralIntervals,
            .auralChordsAndInversions,
            .auralModesAndScales,
            .auralCadences,
            .auralChordsAndInversions
        ]

        return (0..<count).map { idx in
            let domain = earDomains[idx % earDomains.count]
            let level = resolveDifficultyForIndex(idx, requested: difficulty)
            return generateQuestion(for: domain, difficulty: level, isGuitar: isGuitar, variantSeed: idx)
        }
    }

    private func buildTheoryAndHarmonySession(
        curated: [QuizQuestionModel],
        instrument: String,
        difficulty: QuizDifficulty,
        count: Int
    ) -> [QuizQuestionModel] {
        let isGuitar = instrument.lowercased() == "guitar"
        let theoryCurated = curated.filter { $0.resolvedDomain == .theoryAndSpelling || $0.resolvedDomain == .auralCadences }.shuffled()
        var session: [QuizQuestionModel] = Array(theoryCurated.prefix(min(4, count)))

        var idx = 0
        while session.count < count {
            let level = resolveDifficultyForIndex(idx, requested: difficulty)
            let q = makeTheoryQuestion(difficulty: level, isGuitar: isGuitar, variantSeed: idx)
            if !session.contains(where: { $0.question == q.question }) {
                session.append(q)
            }
            idx += 1
            if idx > 24 { break }
        }
        return Array(session.prefix(count))
    }

    private func filterCurated(
        _ curated: [QuizQuestionModel],
        instrument: String,
        difficulty: QuizDifficulty
    ) -> [QuizQuestionModel] {
        curated.filter { q in
            let instrumentMatches = instrument.lowercased() == "all" ||
                q.instrument.lowercased() == instrument.lowercased() ||
                q.instrument.lowercased() == "both"
            let normalizedLevel = q.level.lowercased() == "mastery" || q.level.lowercased() == "master"
                ? "advanced"
                : q.level.lowercased()
            let difficultyMatches = difficulty == .all ||
                normalizedLevel == difficulty.rawValue.lowercased()
            return instrumentMatches && difficultyMatches
        }
    }

    private func resolveDifficultyForIndex(_ index: Int, requested: QuizDifficulty) -> QuizDifficulty {
        if requested != .all { return requested }
        switch index % 3 {
        case 0: return .beginner
        case 1: return .intermediate
        default: return .advanced
        }
    }

    /// Dispatches procedural synthesis for a given conservatory domain.
    public func generateQuestion(
        for domain: QuizDomain,
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false,
        variantSeed: Int = 0
    ) -> QuizQuestionModel {
        switch domain {
        case .auralIntervals:
            return makeAuralIntervalQuestion(difficulty: difficulty, isGuitar: isGuitar)
        case .auralChordsAndInversions:
            if difficulty != .beginner && variantSeed % 2 == 1 {
                return makeAuralChordInversionQuestion(difficulty: difficulty, isGuitar: isGuitar)
            }
            return makeAuralChordQualityQuestion(difficulty: difficulty, isGuitar: isGuitar)
        case .auralModesAndScales:
            return makeAuralScaleModeQuestion(difficulty: difficulty, isGuitar: isGuitar)
        case .auralCadences:
            return makeAuralCadenceQuestion(difficulty: difficulty, isGuitar: isGuitar)
        case .theoryAndSpelling:
            return makeTheoryQuestion(difficulty: difficulty, isGuitar: isGuitar, variantSeed: variantSeed)
        case .instrumentCraft:
            return makeVisualChordIdentificationQuestion(difficulty: difficulty)
        }
    }

    // MARK: - 1. Aural Interval Discrimination

    public func makeAuralIntervalQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false
    ) -> QuizQuestionModel {
        let rootPool = ["C", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb"]
        let root = rootPool.randomElement() ?? "C"

        let candidateIntervals: [IntervalModel]
        switch difficulty {
        case .beginner:
            candidateIntervals = MusicTheoryEngine.allIntervals.filter { [2, 3, 4, 5, 7, 12].contains($0.semitones) }
        case .intermediate, .all:
            candidateIntervals = MusicTheoryEngine.allIntervals.filter { [1, 2, 3, 4, 5, 6, 7, 8, 9].contains($0.semitones) }
        case .advanced:
            candidateIntervals = MusicTheoryEngine.allIntervals.filter { $0.semitones >= 1 && $0.semitones <= 11 }
        }

        let target = candidateIntervals.randomElement() ?? MusicTheoryEngine.allIntervals[7]
        let rootNote = "\(root)4"
        let rootMidi = engine.midiNote(for: rootNote)
        let targetMidi = rootMidi + target.semitones
        let resolvedRoot = resolveLetterAndPitch(for: root)
        let upperPitch = engine.spellPitch(
            rootLetterIndex: resolvedRoot.letterIndex,
            rootPitchClass: resolvedRoot.pitchClass,
            semitonesFromRoot: target.semitones,
            diatonicStepOffset: (target.diatonicSteps - 1) % 7
        )
        let upperOctave = (targetMidi / 12) - 1
        let upperNote = "\(upperPitch)\(upperOctave)"

        let distractors = candidateIntervals
            .filter { $0.shortName != target.shortName }
            .sorted { abs($0.semitones - target.semitones) < abs($1.semitones - target.semitones) }
            .prefix(5)
            .shuffled()
            .prefix(3)

        let combined = ([target] + distractors).shuffled()
        let correctIndex = combined.firstIndex(where: { $0.shortName == target.shortName }) ?? 0

        let comparisonCues: [QuizAudioCue] = combined.map { intervalOption in
            let optMidi = rootMidi + intervalOption.semitones
            let optPitch = engine.spellPitch(
                rootLetterIndex: resolvedRoot.letterIndex,
                rootPitchClass: resolvedRoot.pitchClass,
                semitonesFromRoot: intervalOption.semitones,
                diatonicStepOffset: (intervalOption.diatonicSteps - 1) % 7
            )
            let optNote = "\(optPitch)\((optMidi / 12) - 1)"
            return QuizAudioCue(
                style: .melodic,
                notes: [rootNote, optNote],
                referenceRootNote: rootNote,
                stepDuration: 0.48,
                isGuitar: isGuitar
            )
        }

        let cleanUpperDisplay = MusicTheoryEngine.formatNotationGlyphs(upperNote)
        let cleanRootDisplay = MusicTheoryEngine.formatNotationGlyphs(rootNote)

        return QuizQuestionModel(
            id: "gen-int-\(UUID().uuidString.prefix(8))",
            instrument: isGuitar ? "guitar" : "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Listen to the ascending interval starting on \(cleanRootDisplay). Which interval did you hear?",
            options: combined.map { "\($0.name) (\($0.shortName))" },
            correctIndex: correctIndex,
            explanation: "\(cleanRootDisplay) ascending \(target.semitones) semitone\(target.semitones == 1 ? "" : "s") to \(cleanUpperDisplay) forms a \(target.name) (\(target.shortName)), classified as \(target.consonantCharacter.lowercased()).",
            relatedTipId: "both-uni-01",
            domain: .auralIntervals,
            audioCue: QuizAudioCue(
                style: .melodic,
                notes: [rootNote, upperNote],
                referenceRootNote: rootNote,
                stepDuration: 0.55,
                isGuitar: isGuitar
            ),
            visualNotes: normalizeToVisualRange([rootNote, upperNote]),
            visualRoot: root,
            visualIntervals: ["1", target.shortName],
            visualPreferFlat: root.contains("b"),
            revealVisualBeforeAnswer: false,
            optionComparisonCues: comparisonCues,
            formulaBadge: "\(target.shortName)  ·  \(target.semitones) st  ·  \(target.consonantCharacter)",
            isGenerated: true
        )
    }

    // MARK: - 2. Aural Chord Quality Recognition

    public func makeAuralChordQualityQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false
    ) -> QuizQuestionModel {
        let root = ["C", "D", "Eb", "E", "F", "G", "Ab", "A", "Bb"].randomElement() ?? "C"
        let poolIds: [String]
        switch difficulty {
        case .beginner:
            poolIds = ["major", "minor", "dim", "aug"]
        case .intermediate, .all:
            poolIds = ["major", "minor", "dom7", "maj7", "min7", "sus4"]
        case .advanced:
            poolIds = ["maj7", "dom7", "min7", "m7b5", "dim7", "dom9"]
        }

        let qualities = poolIds.compactMap { ChordDefinitions.chord(for: $0) }
        let target = qualities.randomElement() ?? ChordDefinitions.allChords[0]
        let spelled = engine.spelledChord(root: root, qualityId: target.id, inversion: 0)

        let distractors = qualities.filter { $0.id != target.id }.shuffled().prefix(3)
        let combined = ([target] + distractors).shuffled()
        let correctIndex = combined.firstIndex(where: { $0.id == target.id }) ?? 0

        let comparisonCues: [QuizAudioCue] = combined.map { quality in
            let optSpelled = engine.spelledChord(root: root, qualityId: quality.id, inversion: 0)
            return QuizAudioCue(
                style: .harmonic,
                notes: optSpelled.notes,
                referenceRootNote: optSpelled.notes.first,
                stepDuration: 0.30,
                isGuitar: isGuitar
            )
        }

        return QuizQuestionModel(
            id: "gen-chd-\(UUID().uuidString.prefix(8))",
            instrument: isGuitar ? "guitar" : "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Audition this harmonic voicing built on \(MusicTheoryEngine.formatNotationGlyphs(root)). Which chord quality is sounding?",
            options: combined.map(\.name),
            correctIndex: correctIndex,
            explanation: "A \(target.name) (\(MusicTheoryEngine.formatNotationGlyphs(spelled.symbol))) built on \(MusicTheoryEngine.formatNotationGlyphs(root)) contains the strictly spelled tones \(spelled.notes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " – ")). \(target.description)",
            relatedTipId: "piano-beg-04",
            domain: .auralChordsAndInversions,
            audioCue: QuizAudioCue(
                style: .harmonic,
                notes: spelled.notes,
                referenceRootNote: spelled.notes.first,
                stepDuration: 0.30,
                isGuitar: isGuitar
            ),
            visualNotes: normalizeToVisualRange(spelled.notes),
            visualRoot: spelled.root,
            visualIntervals: spelled.intervalLabels,
            visualPreferFlat: root.contains("b"),
            revealVisualBeforeAnswer: false,
            optionComparisonCues: comparisonCues,
            formulaBadge: "\(MusicTheoryEngine.formatNotationGlyphs(spelled.symbol))  ·  \(spelled.notes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " "))",
            isGenerated: true
        )
    }

    // MARK: - 3. Aural Chord Inversion & Figured Bass

    public func makeAuralChordInversionQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false
    ) -> QuizQuestionModel {
        let root = ["C", "D", "Eb", "F", "G"].randomElement() ?? "C"
        let isSeventhChord = difficulty == .advanced
        let qualityId = isSeventhChord ? ["maj7", "dom7", "min7"].randomElement()! : ["major", "minor"].randomElement()!
        let maxInversion = isSeventhChord ? 3 : 2
        let targetInversion = Int.random(in: 0...maxInversion)

        let spelled = engine.spelledChord(root: root, qualityId: qualityId, inversion: targetInversion)
        let quality = ChordDefinitions.chord(for: qualityId) ?? ChordDefinitions.allChords[0]

        let allInversionOptions: [(inv: Int, text: String)] = isSeventhChord
            ? [
                (0, "Root Position (7) — Bass: \(root)"),
                (1, "1st Inversion (6/5) — Bass on 3rd"),
                (2, "2nd Inversion (4/3) — Bass on 5th"),
                (3, "3rd Inversion (4/2) — Bass on 7th")
            ]
            : [
                (0, "Root Position (5/3) — Bass on Root"),
                (1, "1st Inversion (6/3) — Bass on 3rd"),
                (2, "2nd Inversion (6/4) — Bass on 5th"),
                (0, "Suspended Open Position (sus4)") // Fourth option slot when testing triads
            ]

        // Preserve order or shuffle uniquely
        let optionEntries: [(inv: Int, text: String, isCorrect: Bool)] = allInversionOptions.enumerated().map { idx, entry in
            let correct = (idx < (isSeventhChord ? 4 : 3)) && (entry.inv == targetInversion)
            return (entry.inv, entry.text, correct)
        }.shuffled()

        let correctIndex = optionEntries.firstIndex(where: { $0.isCorrect }) ?? 0

        let comparisonCues: [QuizAudioCue] = optionEntries.map { opt in
            if opt.text.contains("sus4") {
                let sus = engine.spelledChord(root: root, qualityId: "sus4", inversion: 0)
                return QuizAudioCue(style: .arpeggiated, notes: sus.notes, referenceRootNote: "\(root)4", stepDuration: 0.34, isGuitar: isGuitar)
            }
            let alt = engine.spelledChord(root: root, qualityId: qualityId, inversion: opt.inv)
            return QuizAudioCue(style: .arpeggiated, notes: alt.notes, referenceRootNote: "\(root)4", stepDuration: 0.34, isGuitar: isGuitar)
        }

        return QuizQuestionModel(
            id: "gen-inv-\(UUID().uuidString.prefix(8))",
            instrument: isGuitar ? "guitar" : "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Listen closely to the lowest bass voice of this \(MusicTheoryEngine.formatNotationGlyphs(root)) \(quality.name). Which inversion is voiced?",
            options: optionEntries.map(\.text),
            correctIndex: correctIndex,
            explanation: "\(spelled.inversionLabel) (\(spelled.figuredBass)) places \(MusicTheoryEngine.formatNotationGlyphs(spelled.bassNote)) as the lowest bass note, giving a rising top voicing of \(spelled.notes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " – ")).",
            relatedTipId: "piano-int-02",
            domain: .auralChordsAndInversions,
            audioCue: QuizAudioCue(
                style: .arpeggiated,
                notes: spelled.notes,
                referenceRootNote: "\(root)4",
                stepDuration: 0.36,
                isGuitar: isGuitar
            ),
            visualNotes: normalizeToVisualRange(spelled.notes),
            visualRoot: spelled.root,
            visualIntervals: spelled.intervalLabels,
            visualPreferFlat: root.contains("b"),
            revealVisualBeforeAnswer: false,
            optionComparisonCues: comparisonCues,
            formulaBadge: "\(spelled.inversionLabel)  ·  Figured Bass \(spelled.figuredBass)  ·  Bass \(MusicTheoryEngine.formatNotationGlyphs(spelled.bassNote))",
            isGenerated: true
        )
    }

    // MARK: - 4. Aural Scale & Mode Classification

    public func makeAuralScaleModeQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false
    ) -> QuizQuestionModel {
        let root = ["C", "D", "E", "F", "G", "A", "Bb"].randomElement() ?? "D"
        let poolIds: [String]
        switch difficulty {
        case .beginner:
            poolIds = ["major", "natural_minor", "major_pentatonic", "minor_pentatonic"]
        case .intermediate, .all:
            poolIds = ["major", "natural_minor", "harmonic_minor", "dorian", "mixolydian", "blues"]
        case .advanced:
            poolIds = ["dorian", "mixolydian", "phrygian", "lydian", "harmonic_minor", "melodic_minor"]
        }

        let scales = poolIds.compactMap { ScaleDefinitions.scale(for: $0) }
        let target = scales.randomElement() ?? ScaleDefinitions.allScales[0]
        let notes = engine.notes(forScale: target.id, rootKey: root)

        let distractors = scales.filter { $0.id != target.id }.shuffled().prefix(3)
        let combined = ([target] + distractors).shuffled()
        let correctIndex = combined.firstIndex(where: { $0.id == target.id }) ?? 0

        let comparisonCues = combined.map { scale in
            let optNotes = engine.notes(forScale: scale.id, rootKey: root)
            return QuizAudioCue(
                style: .scale,
                notes: optNotes,
                referenceRootNote: optNotes.first,
                stepDuration: 0.24,
                isGuitar: isGuitar
            )
        }

        let displayRoot = MusicTheoryEngine.formatNotationGlyphs(root)
        let formula = target.intervalLabels.dropLast().joined(separator: " – ")

        return QuizQuestionModel(
            id: "gen-mod-\(UUID().uuidString.prefix(8))",
            instrument: isGuitar ? "guitar" : "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Listen to this ascending scale starting on \(displayRoot). Which scale or mode is played?",
            options: combined.map(\.name),
            correctIndex: correctIndex,
            explanation: "\(displayRoot) \(target.name) (\(formula)) spells \(notes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " – ")). \(target.description)",
            relatedTipId: "gtr-int-01",
            domain: .auralModesAndScales,
            audioCue: QuizAudioCue(
                style: .scale,
                notes: notes,
                referenceRootNote: notes.first,
                stepDuration: 0.25,
                isGuitar: isGuitar
            ),
            visualNotes: normalizeToVisualRange(notes),
            visualRoot: root,
            visualIntervals: target.intervalLabels,
            visualPreferFlat: root.contains("b"),
            revealVisualBeforeAnswer: false,
            optionComparisonCues: comparisonCues,
            formulaBadge: "Scale Formula: \(formula)",
            isGenerated: true
        )
    }

    // MARK: - 5. Aural Harmonic Cadences

    private struct CadenceBlueprint {
        let name: String
        let romanFormula: String
        let degreeIndices: [Int] // 0 = I, 1 = ii, 2 = iii, 3 = IV, 4 = V, 5 = vi
        let resolutionNote: String
    }

    public func makeAuralCadenceQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false
    ) -> QuizQuestionModel {
        let keyRoot = ["C", "F", "G", "D", "Bb", "Eb"].randomElement() ?? "C"
        let use7ths = difficulty != .beginner
        let diatonics = engine.diatonicChords(for: keyRoot, include7ths: use7ths)

        let blueprints: [CadenceBlueprint] = [
            CadenceBlueprint(
                name: "Authentic Cadence (IV → V → I)",
                romanFormula: "IV – V – I",
                degreeIndices: [3, 4, 0],
                resolutionNote: "Resolves tension from the Dominant (V) back home to Tonic (I) with strong leading-tone pull."
            ),
            CadenceBlueprint(
                name: "Plagal 'Amen' Cadence (I → IV → I)",
                romanFormula: "I – IV – I",
                degreeIndices: [0, 3, 0],
                resolutionNote: "Warm, hymn-like release moving gently from Subdominant (IV) back to Tonic (I) without a dominant tritone."
            ),
            CadenceBlueprint(
                name: "Deceptive Cadence (IV → V → vi)",
                romanFormula: "IV – V – vi",
                degreeIndices: [3, 4, 5],
                resolutionNote: "Sets up Dominant (V) expectation for Tonic (I), then pivots unexpectedly to the relative minor (vi)."
            ),
            CadenceBlueprint(
                name: "Half Cadence (I → IV → V)",
                romanFormula: "I – IV – V",
                degreeIndices: [0, 3, 4],
                resolutionNote: "Leaves the musical phrase suspended cleanly on the unresolved Dominant (V), inviting continuation."
            )
        ]

        let targetIdx = Int.random(in: 0..<blueprints.count)
        let target = blueprints[targetIdx]
        let shuffledBlueprints = blueprints.shuffled()
        let correctIndex = shuffledBlueprints.firstIndex(where: { $0.name == target.name }) ?? 0

        func chordSequence(for bp: CadenceBlueprint) -> [[String]] {
            bp.degreeIndices.map { degIndex in
                degIndex < diatonics.count ? diatonics[degIndex].notes : diatonics[0].notes
            }
        }

        let targetProgressions = chordSequence(for: target)
        let comparisonCues = shuffledBlueprints.map { bp in
            QuizAudioCue(
                style: .chordProgression,
                notes: [],
                progressions: chordSequence(for: bp),
                referenceRootNote: "\(keyRoot)4",
                stepDuration: 0.78,
                isGuitar: isGuitar
            )
        }

        let finalChordVisual = normalizeToVisualRange(targetProgressions.last ?? [])
        let chordSymbols = target.degreeIndices.compactMap { degIdx -> String? in
            guard degIdx < diatonics.count else { return nil }
            let c = diatonics[degIdx]
            return MusicTheoryEngine.formatNotationGlyphs("\(c.root) (\(c.degree))")
        }.joined(separator: " → ")

        return QuizQuestionModel(
            id: "gen-cad-\(UUID().uuidString.prefix(8))",
            instrument: isGuitar ? "guitar" : "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Listen to this 3-chord cadence in the key of \(MusicTheoryEngine.formatNotationGlyphs(keyRoot)) Major. Which harmonic cadence do you hear?",
            options: shuffledBlueprints.map(\.name),
            correctIndex: correctIndex,
            explanation: "\(target.name) in \(MusicTheoryEngine.formatNotationGlyphs(keyRoot)) Major (\(chordSymbols)): \(target.resolutionNote)",
            relatedTipId: "piano-int-04",
            domain: .auralCadences,
            audioCue: QuizAudioCue(
                style: .chordProgression,
                notes: [],
                progressions: targetProgressions,
                referenceRootNote: "\(keyRoot)4",
                stepDuration: 0.80,
                isGuitar: isGuitar
            ),
            visualNotes: finalChordVisual,
            visualRoot: diatonics[target.degreeIndices.last ?? 0].root,
            visualPreferFlat: keyRoot.contains("b"),
            revealVisualBeforeAnswer: false,
            optionComparisonCues: comparisonCues,
            formulaBadge: "\(chordSymbols)",
            isGenerated: true
        )
    }

    // MARK: - 6. Written Theory, Strict Spelling, Rule-of-9 & Visual Keyboard Chord ID

    public func makeTheoryQuestion(
        difficulty: QuizDifficulty = .intermediate,
        isGuitar: Bool = false,
        variantSeed: Int = 0
    ) -> QuizQuestionModel {
        switch variantSeed % 4 {
        case 0:
            return makeStrictSpellingQuestion(difficulty: difficulty)
        case 1:
            return makeRuleOf9InversionQuestion(difficulty: difficulty)
        case 2:
            return makeKeySignatureQuestion(difficulty: difficulty)
        default:
            return makeVisualChordIdentificationQuestion(difficulty: difficulty)
        }
    }

    /// Procedurally tests strict 7-letter diatonic spelling across scales and diminished 7th harmony.
    public func makeStrictSpellingQuestion(difficulty: QuizDifficulty = .intermediate) -> QuizQuestionModel {
        let scenario = Int.random(in: 0..<3)
        if scenario == 0 {
            // F# Major leading tone / Gb Major 4th degree spelling
            let useSharp = Bool.random()
            if useSharp {
                let fSharpScale = engine.notes(forScale: "major", rootKey: "F#")
                    .dropLast()
                    .map { MusicTheoryEngine.formatNotationGlyphs(String($0.prefix { !$0.isNumber })) }
                let options = ["E♯", "F♮", "E♮", "F♯"].shuffled()
                let correctIndex = options.firstIndex(of: "E♯") ?? 0
                return QuizQuestionModel(
                    id: "gen-spl-\(UUID().uuidString.prefix(8))",
                    instrument: "both",
                    level: difficulty == .all ? "intermediate" : difficulty.rawValue,
                    question: "Under strict 7-letter diatonic spelling, how is the 7th scale degree (leading tone) of F♯ Major named?",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "Every diatonic scale must use each letter A–G once. F♯ Major (\(fSharpScale.joined(separator: " – "))) already contains F♯, so its 7th letter step above F must be an E derivative: E♯.",
                    relatedTipId: "both-uni-01",
                    domain: .theoryAndSpelling,
                    visualNotes: engine.notes(forScale: "major", rootKey: "F#"),
                    visualRoot: "F#",
                    formulaBadge: fSharpScale.joined(separator: " · "),
                    isGenerated: true
                )
            } else {
                let options = ["C♭", "B♮", "C♮", "B♭"].shuffled()
                let correctIndex = options.firstIndex(of: "C♭") ?? 0
                let gbNotes = engine.notes(forScale: "major", rootKey: "Gb").dropLast()
                    .map { MusicTheoryEngine.formatNotationGlyphs(String($0.prefix { !$0.isNumber })) }
                return QuizQuestionModel(
                    id: "gen-spl-\(UUID().uuidString.prefix(8))",
                    instrument: "both",
                    level: difficulty == .all ? "intermediate" : difficulty.rawValue,
                    question: "Under strict 7-letter diatonic spelling, how is the 4th scale degree (subdominant) of G♭ Major written?",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "G♭ Major must contain both B♭ (3rd) and a C-letter 4th degree without repeating B: G♭ – A♭ – B♭ – C♭ – D♭ – E♭ – F.",
                    relatedTipId: "both-uni-01",
                    domain: .theoryAndSpelling,
                    visualNotes: normalizeToVisualRange(engine.notes(forScale: "major", rootKey: "Gb")),
                    visualRoot: "Gb",
                    visualPreferFlat: true,
                    formulaBadge: gbNotes.joined(separator: " · "),
                    isGenerated: true
                )
            }
        } else if scenario == 1 {
            // Cdim7 / Bdim7 diminished 7th double-flat & stack of thirds spelling
            let useDoubleFlat = difficulty == .advanced || Bool.random()
            if useDoubleFlat {
                let cDimNotes = engine.chordNotes(root: "C", qualityId: "dim7")
                let options = ["B𝄫 (double-flat)", "A♮", "G♯", "B♭"].shuffled()
                let correctIndex = options.firstIndex(of: "B𝄫 (double-flat)") ?? 0
                return QuizQuestionModel(
                    id: "gen-spl-\(UUID().uuidString.prefix(8))",
                    instrument: "both",
                    level: "advanced",
                    question: "Which note correctly completes the strict tertian spelling of a C Diminished 7th chord (Cdim7): C – E♭ – G♭ – ___?",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "A diminished 7th chord stacks thirds on letter steps 1–3–5–7. The 7th letter above C is B, lowered two half steps to B𝄫 (sounding A4), never A♮ (which would spell a 6th).",
                    relatedTipId: "piano-mst-02",
                    domain: .theoryAndSpelling,
                    audioCue: QuizAudioCue(style: .harmonic, notes: cDimNotes, referenceRootNote: "C4", stepDuration: 0.30, isGuitar: false),
                    visualNotes: normalizeToVisualRange(cDimNotes),
                    visualRoot: "C",
                    visualPreferFlat: true,
                    formulaBadge: "C – E♭ – G♭ – B𝄫  (1 · ♭3 · ♭5 · 𝄫7)",
                    isGenerated: true
                )
            } else {
                let gHarmonic = engine.notes(forScale: "harmonic_minor", rootKey: "G")
                let options = ["G – A – B♭ – C – D – E♭ – F♯", "G – A – A♯ – C – D – D♯ – F♯", "G – A – B♭ – C – D – D♯ – G♭", "G – B♭♭ – B♭ – C – D – E♭ – F♯"].shuffled()
                let correctIndex = options.firstIndex(of: "G – A – B♭ – C – D – E♭ – F♯") ?? 0
                return QuizQuestionModel(
                    id: "gen-spl-\(UUID().uuidString.prefix(8))",
                    instrument: "both",
                    level: "intermediate",
                    question: "Select the strictly spelled G Harmonic Minor scale (mixed flats and raised leading tone):",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "Harmonic minor takes its 2-flat minor key signature (B♭, E♭) and raises the 7th letter step (F → F♯), preserving all seven distinct letters G–A–B–C–D–E–F♯.",
                    relatedTipId: "both-uni-01",
                    domain: .theoryAndSpelling,
                    audioCue: QuizAudioCue(style: .scale, notes: gHarmonic, referenceRootNote: "G4", stepDuration: 0.24, isGuitar: false),
                    visualNotes: normalizeToVisualRange(gHarmonic),
                    visualRoot: "G",
                    formulaBadge: "G · A · B♭ · C · D · E♭ · F♯",
                    isGenerated: true
                )
            }
        } else {
            // Bdim7 spelling
            let bDimNotes = engine.chordNotes(root: "B", qualityId: "dim7")
            let options = ["B – D – F – A♭", "B – D – F – G♯", "B – C♯ – F – G♯", "B – D – E♯ – A♭"].shuffled()
            let correctIndex = options.firstIndex(of: "B – D – F – A♭") ?? 0
            return QuizQuestionModel(
                id: "gen-spl-\(UUID().uuidString.prefix(8))",
                instrument: "both",
                level: difficulty == .all ? "intermediate" : difficulty.rawValue,
                question: "How is B Diminished 7th (Bdim7) strictly spelled so each interval forms a minor 3rd above the preceding chord tone?",
                options: options,
                correctIndex: correctIndex,
                explanation: "Counting thirds from B yields B – D – F – A. Raising/lowering to minor 3rds (3 semitones each) produces B – D – F – A♭ (♭7 of B is A, lowered again to A♭ for 𝄫7).",
                relatedTipId: "piano-mst-02",
                domain: .theoryAndSpelling,
                audioCue: QuizAudioCue(style: .harmonic, notes: bDimNotes, referenceRootNote: "B3", stepDuration: 0.30, isGuitar: false),
                visualNotes: normalizeToVisualRange(bDimNotes),
                visualRoot: "B",
                visualPreferFlat: true,
                formulaBadge: "B – D – F – A♭  (1 · ♭3 · ♭5 · 𝄫7)",
                isGenerated: true
            )
        }
    }

    /// Generates conservatory Rule-of-9 interval inversion questions across major/minor/perfect/augmented/diminished intervals.
    public func makeRuleOf9InversionQuestion(difficulty: QuizDifficulty = .intermediate) -> QuizQuestionModel {
        let pairs: [(inputShort: String, inputFull: String, expectedShort: String, expectedFull: String, distractors: [String])] = [
            ("M3", "Major 3rd (M3)", "m6", "Minor 6th (m6)", ["Major 6th (M6)", "Minor 3rd (m3)", "Perfect 5th (P5)"]),
            ("m6", "Minor 6th (m6)", "M3", "Major 3rd (M3)", ["Minor 3rd (m3)", "Major 2nd (M2)", "Perfect 4th (P4)"]),
            ("P4", "Perfect 4th (P4)", "P5", "Perfect 5th (P5)", ["Major 5th (M5)", "Tritone (A4)", "Minor 6th (m6)"]),
            ("M2", "Major 2nd (M2)", "m7", "Minor 7th (m7)", ["Major 7th (M7)", "Minor 6th (m6)", "Diminished 7th (d7)"]),
            ("m2", "Minor 2nd (m2)", "M7", "Major 7th (M7)", ["Minor 7th (m7)", "Augmented 6th (A6)", "Major 6th (M6)"]),
            ("A4", "Augmented 4th (A4)", "d5", "Diminished 5th (d5)", ["Perfect 5th (P5)", "Augmented 5th (A5)", "Minor 6th (m6)"])
        ]

        let entry = pairs.randomElement() ?? pairs[0]
        let inv = engine.invertInterval(entry.inputShort)
        let options = ([entry.expectedFull] + entry.distractors).shuffled()
        let correctIndex = options.firstIndex(of: entry.expectedFull) ?? 0

        return QuizQuestionModel(
            id: "gen-inv9-\(UUID().uuidString.prefix(8))",
            instrument: "both",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "By the conservatory Rule of 9, what interval results when you invert a \(entry.inputFull)?",
            options: options,
            correctIndex: correctIndex,
            explanation: "Rule of 9: subtract the interval number from 9 (9 − number = inverted number) and flip quality (Major ↔ Minor, Augmented ↔ Diminished, Perfect ↔ Perfect). Inverting \(entry.inputShort) gives \(inv.invertedName) (\(inv.invertedShortName), \(inv.complementarySemitones) semitones).",
            relatedTipId: "both-uni-01",
            domain: .theoryAndSpelling,
            formulaBadge: "Rule of 9:  \(entry.inputShort) + \(inv.invertedShortName) = P8 (12 st)",
            isGenerated: true
        )
    }

    /// Generates Circle-of-Fifths key signature & relative minor questions across all 12 keys.
    public func makeKeySignatureQuestion(difficulty: QuizDifficulty = .beginner) -> QuizQuestionModel {
        let nonCKeys = KeyDefinitions.circleOfFifthsKeys.filter { $0.root != "C" }
        let chosen = nonCKeys.randomElement() ?? KeyDefinitions.circleOfFifthsKeys[1]
        let displayRoot = MusicTheoryEngine.formatNotationGlyphs(chosen.root)

        if Bool.random() {
            // Key signature accidental count
            let correctLabel = chosen.sharpsCount > 0
                ? "\(chosen.sharpsCount) \(chosen.sharpsCount == 1 ? "sharp" : "sharps")"
                : "\(chosen.flatsCount) \(chosen.flatsCount == 1 ? "flat" : "flats")"

            var distractorSet = Set<String>()
            let candidates = [
                "1 sharp", "2 sharps", "3 sharps", "4 sharps", "5 sharps", "6 sharps",
                "1 flat", "2 flats", "3 flats", "4 flats", "5 flats"
            ].filter { $0 != correctLabel }.shuffled()

            for cand in candidates where distractorSet.count < 3 {
                distractorSet.insert(cand)
            }
            let options = ([correctLabel] + Array(distractorSet)).shuffled()
            let correctIndex = options.firstIndex(of: correctLabel) ?? 0

            return QuizQuestionModel(
                id: "gen-key-\(UUID().uuidString.prefix(8))",
                instrument: "both",
                level: difficulty == .all ? "beginner" : difficulty.rawValue,
                question: "On the Circle of Fifths, how many sharps or flats belong in the key signature of \(displayRoot) Major?",
                options: options,
                correctIndex: correctIndex,
                explanation: "\(displayRoot) Major has \(correctLabel) (\(chosen.keySignatureDesc)), spelling \(chosen.majorScaleNotes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " – ")). Its relative minor is \(MusicTheoryEngine.formatNotationGlyphs(chosen.relativeMinor)).",
                relatedTipId: "both-uni-01",
                domain: .theoryAndSpelling,
                visualNotes: normalizeToVisualRange(engine.notes(forScale: "major", rootKey: chosen.root)),
                visualRoot: chosen.root,
                visualPreferFlat: chosen.accidentalType == "flat",
                formulaBadge: "\(displayRoot) Major  ·  \(correctLabel)  ·  Rel. \(MusicTheoryEngine.formatNotationGlyphs(chosen.relativeMinor))",
                isGenerated: true
            )
        } else {
            // Relative Minor lookup
            let correctMinor = MusicTheoryEngine.formatNotationGlyphs(chosen.relativeMinor)
            let otherMinors = nonCKeys
                .map { MusicTheoryEngine.formatNotationGlyphs($0.relativeMinor) }
                .filter { $0 != correctMinor }
                .shuffled()
                .prefix(3)
            let options = ([correctMinor] + otherMinors).shuffled()
            let correctIndex = options.firstIndex(of: correctMinor) ?? 0

            return QuizQuestionModel(
                id: "gen-rel-\(UUID().uuidString.prefix(8))",
                instrument: "both",
                level: difficulty == .all ? "beginner" : difficulty.rawValue,
                question: "Which minor key shares the exact same key signature as \(displayRoot) Major (its relative minor on the 6th scale degree)?",
                options: options,
                correctIndex: correctIndex,
                explanation: "The 6th scale degree of \(displayRoot) Major gives its relative minor, \(correctMinor) (\(chosen.keySignatureDesc)). Both scales share the same 7 diatonic pitch classes.",
                relatedTipId: "both-uni-01",
                domain: .theoryAndSpelling,
                visualNotes: normalizeToVisualRange(engine.notes(forScale: "major", rootKey: chosen.root)),
                visualRoot: chosen.root,
                visualPreferFlat: chosen.accidentalType == "flat",
                formulaBadge: "\(displayRoot) Major ↔ \(correctMinor)",
                isGenerated: true
            )
        }
    }

    /// Generates a Visual Keyboard Chord Identification question with lit keys rendered BEFORE answering (no audio spoiler).
    public func makeVisualChordIdentificationQuestion(difficulty: QuizDifficulty = .intermediate) -> QuizQuestionModel {
        let root = ["C", "D", "Eb", "F", "G", "Ab", "Bb"].randomElement() ?? "C"
        let poolIds: [String]
        switch difficulty {
        case .beginner:
            poolIds = ["major", "minor", "sus4", "dim"]
        case .intermediate, .all:
            poolIds = ["maj7", "dom7", "min7", "sus2"]
        case .advanced:
            poolIds = ["m7b5", "dim7", "maj9", "min9"]
        }

        let targetQualityId = poolIds.randomElement() ?? "maj7"
        let targetQuality = ChordDefinitions.chord(for: targetQualityId) ?? ChordDefinitions.allChords[0]
        let spelled = engine.spelledChord(root: root, qualityId: targetQuality.id, inversion: 0)

        let distractors = poolIds.filter { $0 != targetQuality.id }
            .compactMap { ChordDefinitions.chord(for: $0) }
            .prefix(3)
        let combined = ([targetQuality] + distractors).shuffled()
        let correctIndex = combined.firstIndex(where: { $0.id == targetQuality.id }) ?? 0

        let displayRoot = MusicTheoryEngine.formatNotationGlyphs(root)
        let options = combined.map { "\(displayRoot) \($0.name)" }

        let visualKeyNotes = normalizeToVisualRange(spelled.notes)
        let comparisonCues = combined.map { quality in
            let s = engine.spelledChord(root: root, qualityId: quality.id, inversion: 0)
            return QuizAudioCue(style: .harmonic, notes: s.notes, referenceRootNote: "\(root)4", stepDuration: 0.28, isGuitar: false)
        }

        return QuizQuestionModel(
            id: "gen-vis-\(UUID().uuidString.prefix(8))",
            instrument: "piano",
            level: difficulty == .all ? "intermediate" : difficulty.rawValue,
            question: "Inspect the highlighted notes illuminated on the grand piano keybed below. Which harmony is voiced?",
            options: options,
            correctIndex: correctIndex,
            explanation: "The lit keys trace \(spelled.notes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " – ")), forming \(displayRoot) \(targetQuality.name) (\(MusicTheoryEngine.formatNotationGlyphs(spelled.symbol))).",
            relatedTipId: "piano-beg-04",
            domain: .theoryAndSpelling,
            audioCue: nil, // Visual reading challenge before submission; unlocked in post-answer A/B compare
            visualNotes: visualKeyNotes,
            visualRoot: spelled.root,
            visualIntervals: spelled.intervalLabels,
            visualPreferFlat: root.contains("b"),
            revealVisualBeforeAnswer: true,
            optionComparisonCues: comparisonCues,
            formulaBadge: "\(MusicTheoryEngine.formatNotationGlyphs(spelled.symbol))  ·  \(visualKeyNotes.map { MusicTheoryEngine.formatNotationGlyphs($0) }.joined(separator: " "))",
            isGenerated: true
        )
    }

    // MARK: - Internal Helpers

    private func resolveLetterAndPitch(for bareRoot: String) -> (letterIndex: Int, pitchClass: Int) {
        let info = KeyDefinitions.keyInfo(for: bareRoot)
        let letters = ["C", "D", "E", "F", "G", "A", "B"]
        let letterIndex = info.root.first.flatMap { letters.firstIndex(of: String($0).uppercased()) } ?? 0
        return (letterIndex, info.pitchClass)
    }

    /// Transposes notes gently into the C4..C6 (`MIDI 60..84`) range so every note illuminates visibly on `NativePianoView` / compact keyboards.
    private func normalizeToVisualRange(_ notes: [String]) -> [String] {
        notes.map { note in
            var midi = engine.midiNote(for: note)
            let barePitch = String(note.prefix { !$0.isNumber && $0 != "-" })
            while midi < 60 { midi += 12 }
            while midi > 84 { midi -= 12 }
            let octave = (midi / 12) - 1
            return "\(barePitch)\(octave)"
        }
    }
}
