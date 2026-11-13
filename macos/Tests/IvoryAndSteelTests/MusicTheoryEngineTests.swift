import XCTest
@testable import IvoryAndSteel

final class MusicTheoryEngineTests: XCTestCase {
    let engine = MusicTheoryEngine.shared

    // MARK: - 12-TET Frequency Math

    func testFrequency12TET() {
        // A4 (MIDI 69) must be exactly 440.0 Hz
        let freqA4 = engine.frequency(for: 69)
        XCTAssertEqual(freqA4, 440.0, accuracy: 0.0001)

        // A5 (MIDI 81) is one octave higher -> 880.0 Hz
        let freqA5 = engine.frequency(for: 81)
        XCTAssertEqual(freqA5, 880.0, accuracy: 0.0001)

        // A3 (MIDI 57) is one octave lower -> 220.0 Hz
        let freqA3 = engine.frequency(for: 57)
        XCTAssertEqual(freqA3, 220.0, accuracy: 0.0001)

        // Middle C (C4, MIDI 60) -> ~261.6256 Hz
        let freqC4 = engine.frequency(for: 60)
        XCTAssertEqual(freqC4, 261.6256, accuracy: 0.01)

        // String overload convenience
        XCTAssertEqual(engine.frequency(for: "A4"), 440.0, accuracy: 0.0001)
        XCTAssertEqual(engine.frequency(for: "C4"), 261.6256, accuracy: 0.01)
    }

    // MARK: - Scientific Pitch Notation Parser

    func testScientificPitchNotationParsing() {
        XCTAssertEqual(engine.midiNote(for: "C4"), 60)
        XCTAssertEqual(engine.midiNote(for: "A4"), 69)
        XCTAssertEqual(engine.midiNote(for: "F#3"), 54)
        XCTAssertEqual(engine.midiNote(for: "Bb5"), 82)
        XCTAssertEqual(engine.midiNote(for: "Db4"), 61)
        XCTAssertEqual(engine.midiNote(for: "Eb4"), 63)
        XCTAssertEqual(engine.midiNote(for: "Gb4"), 66)
        XCTAssertEqual(engine.midiNote(for: "Ab4"), 68)
        XCTAssertEqual(engine.midiNote(for: "E#4"), 65)
        XCTAssertEqual(engine.midiNote(for: "B#4"), 60)
        XCTAssertEqual(engine.midiNote(for: "Cb4"), 71)

        // Unicode accidental handling
        XCTAssertEqual(engine.midiNote(for: "F♯3"), 54)
        XCTAssertEqual(engine.midiNote(for: "B♭5"), 82)

        // Graceful fallback for invalid strings
        XCTAssertEqual(engine.midiNote(for: "Invalid"), 60)
        XCTAssertEqual(engine.midiNote(for: ""), 60)
    }

    // MARK: - Enharmonic Mapping

    func testEnharmonicMapping() {
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Db"), "C#")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Eb"), "D#")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Gb"), "F#")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Ab"), "G#")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Bb"), "A#")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "E#"), "F")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "B#"), "C")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Cb"), "B")

        // With octaves
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Eb4"), "D#4")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Bb5"), "A#5")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "Db3"), "C#3")

        // Unaltered notes
        XCTAssertEqual(engine.enharmonicEquivalent(of: "C4"), "C4")
        XCTAssertEqual(engine.enharmonicEquivalent(of: "F#4"), "F#4")

        // Virtual piano key normalization
        XCTAssertEqual(engine.normalizeToPianoKey("Eb4"), "D#4")
        XCTAssertEqual(engine.normalizeToPianoKey("Bb4"), "A#4")
        XCTAssertEqual(engine.normalizeToPianoKey("Ab5"), "G#5")
    }

    // MARK: - Circle of Fifths & Key Definitions

    func testAll12KeysCircleOfFifths() {
        let keys = KeyDefinitions.circleOfFifthsKeys
        XCTAssertEqual(keys.count, 12)

        // All 12 pitch classes must be uniquely represented
        let pitchClasses = Set(keys.map { $0.pitchClass })
        XCTAssertEqual(pitchClasses.count, 12)

        let cKey = KeyDefinitions.keyInfo(for: "C")
        XCTAssertEqual(cKey.sharpsCount, 0)
        XCTAssertEqual(cKey.flatsCount, 0)
        XCTAssertEqual(cKey.relativeMinor, "A Minor")
        XCTAssertEqual(cKey.relativeMinorRoot, "A")

        let ebKey = KeyDefinitions.keyInfo(for: "Eb")
        XCTAssertEqual(ebKey.flatsCount, 3)
        XCTAssertEqual(ebKey.relativeMinor, "C Minor")

        let aKey = KeyDefinitions.keyInfo(for: "A")
        XCTAssertEqual(aKey.sharpsCount, 3)
        XCTAssertEqual(aKey.relativeMinor, "F# Minor")

        let fsKey = KeyDefinitions.keyInfo(for: "F#")
        XCTAssertEqual(fsKey.sharpsCount, 6)
        XCTAssertEqual(fsKey.relativeMinor, "D# Minor")
    }

    // MARK: - Algorithmic Diatonic Chord Generation (All 12 Keys)

    func testDiatonicChordsAll12Keys() {
        let allKeys = KeyDefinitions.circleOfFifthsKeys.map { $0.root }
        XCTAssertEqual(allKeys.count, 12)

        let expectedDegrees = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        let expected7thQualities = ["maj7", "min7", "min7", "maj7", "dom7", "min7", "m7b5"]

        for root in allKeys {
            let chords = engine.diatonicChords(for: root)
            XCTAssertEqual(chords.count, 7, "Key \(root) must have 7 diatonic chords")

            for (index, chord) in chords.enumerated() {
                XCTAssertEqual(chord.degree, expectedDegrees[index])
                XCTAssertEqual(chord.quality, expected7thQualities[index])
                XCTAssertEqual(chord.notes.count, 4, "7th chord must contain 4 notes")

                if index == 0 {
                    XCTAssertTrue(chord.isTonic, "Degree I must be marked as tonic")
                    XCTAssertFalse(chord.isDominant)
                } else if index == 4 {
                    XCTAssertTrue(chord.isDominant, "Degree V must be marked as dominant")
                    XCTAssertFalse(chord.isTonic)
                } else {
                    XCTAssertFalse(chord.isTonic)
                    XCTAssertFalse(chord.isDominant)
                }
            }
        }
    }

    func testCMajorDiatonicChordsDetailed() {
        let chords = engine.diatonicChords(for: "C")
        XCTAssertEqual(chords.count, 7)

        // I = Cmaj7 (C4, E4, G4, B4)
        XCTAssertEqual(chords[0].root, "C")
        XCTAssertEqual(chords[0].quality, "maj7")
        XCTAssertEqual(chords[0].notes, ["C4", "E4", "G4", "B4"])

        // ii = Dm7 (D4, F4, A4, C5)
        XCTAssertEqual(chords[1].root, "D")
        XCTAssertEqual(chords[1].quality, "min7")
        XCTAssertEqual(chords[1].notes, ["D4", "F4", "A4", "C5"])

        // IV = Fmaj7 (F4, A4, C5, E5)
        XCTAssertEqual(chords[3].root, "F")
        XCTAssertEqual(chords[3].quality, "maj7")

        // V = G7 (G3, B3, D4, F4)
        XCTAssertEqual(chords[4].root, "G")
        XCTAssertEqual(chords[4].quality, "dom7")
        XCTAssertTrue(chords[4].isDominant)

        // Diatonic Triads
        let triads = engine.diatonicTriads(for: "C")
        XCTAssertEqual(triads.count, 7)
        XCTAssertEqual(triads[0].quality, "major")
        XCTAssertEqual(triads[0].notes, ["C4", "E4", "G4"])
        XCTAssertEqual(triads[1].quality, "minor")
        XCTAssertEqual(triads[1].notes, ["D4", "F4", "A4"])
        XCTAssertEqual(triads[6].quality, "dim")
        XCTAssertEqual(triads[6].notes, ["B3", "D4", "F4"])
    }

    // MARK: - Scale Generator for All 11 Scales

    func testScaleGenerationAll11Scales() {
        let scales = ScaleDefinitions.allScales
        XCTAssertEqual(scales.count, 11)

        // 1. Major (8 notes with octave root)
        let cMajor = engine.notes(forScale: "major", rootKey: "C")
        XCTAssertEqual(cMajor.count, 8)
        XCTAssertEqual(cMajor.first, "C4")
        XCTAssertEqual(cMajor.last, "C5")
        XCTAssertEqual(cMajor, ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"])

        // 2. Natural Minor
        let aMinor = engine.notes(forScale: "natural_minor", rootKey: "A")
        XCTAssertEqual(aMinor.count, 8)
        XCTAssertEqual(aMinor.first, "A4")
        XCTAssertEqual(aMinor.last, "A5")

        // 3. Harmonic Minor
        let aHarmonicMinor = engine.notes(forScale: "harmonic_minor", rootKey: "A")
        XCTAssertEqual(aHarmonicMinor.count, 8)

        // 4. Melodic Minor
        let cMelodicMinor = engine.notes(forScale: "melodic_minor", rootKey: "C")
        XCTAssertEqual(cMelodicMinor.count, 8)

        // 5. Major Pentatonic (6 notes with octave root)
        let gMajorPentatonic = engine.notes(forScale: "major_pentatonic", rootKey: "G")
        XCTAssertEqual(gMajorPentatonic.count, 6)
        XCTAssertEqual(gMajorPentatonic.first, "G4")
        XCTAssertEqual(gMajorPentatonic.last, "G5")

        // 6. Minor Pentatonic (6 notes with octave root)
        let ebMinorPentatonic = engine.notes(forScale: "minor_pentatonic", rootKey: "Eb")
        XCTAssertEqual(ebMinorPentatonic.count, 6)
        XCTAssertEqual(ebMinorPentatonic.first, "Eb4")
        XCTAssertEqual(ebMinorPentatonic.last, "Eb5")

        // 7. Blues Scale (7 notes with octave root)
        let fsBlues = engine.notes(forScale: "blues", rootKey: "F#")
        XCTAssertEqual(fsBlues.count, 7)
        XCTAssertEqual(fsBlues.first, "F#4")
        XCTAssertEqual(fsBlues.last, "F#5")

        // 8. Dorian
        let dDorian = engine.notes(forScale: "dorian", rootKey: "D")
        XCTAssertEqual(dDorian.count, 8)

        // 9. Mixolydian
        let gMixolydian = engine.notes(forScale: "mixolydian", rootKey: "G")
        XCTAssertEqual(gMixolydian.count, 8)

        // 10. Phrygian
        let ePhrygian = engine.notes(forScale: "phrygian", rootKey: "E")
        XCTAssertEqual(ePhrygian.count, 8)

        // 11. Lydian
        let fLydian = engine.notes(forScale: "lydian", rootKey: "F")
        XCTAssertEqual(fLydian.count, 8)
    }

    // MARK: - Chord Definitions Coverage

    func testChordDefinitionsCoverage() {
        // Triads
        XCTAssertNotNil(ChordDefinitions.chord(for: "major"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "minor"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "dim"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "aug"))

        // 7ths
        XCTAssertNotNil(ChordDefinitions.chord(for: "dom7"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "maj7"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "min7"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "m7b5"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "dim7"))

        // Suspended
        XCTAssertNotNil(ChordDefinitions.chord(for: "sus2"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "sus4"))

        // Extended: Add9, 9th, 11th
        XCTAssertNotNil(ChordDefinitions.chord(for: "add9"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "dom9"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "maj9"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "min9"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "dom11"))
        XCTAssertNotNil(ChordDefinitions.chord(for: "min11"))

        // Arbitrary chord note generator
        let cMajor = engine.chordNotes(root: "C", qualityId: "major")
        XCTAssertEqual(cMajor, ["C4", "E4", "G4"])

        let cDom7 = engine.chordNotes(root: "C", qualityId: "dom7")
        XCTAssertEqual(cDom7.count, 4)

        // All StudioPresets chords & aliases must resolve directly (never silently fallback)
        for item in StudioPresets.chords {
            XCTAssertNotNil(ChordDefinitions.chord(for: item.id), "StudioPresets chord \(item.id) must exist in ChordDefinitions")
        }
        XCTAssertEqual(ChordDefinitions.chord(for: "diminished")?.id, "dim")
        XCTAssertEqual(ChordDefinitions.chord(for: "augmented")?.id, "aug")
        XCTAssertEqual(ChordDefinitions.chord(for: "m7")?.id, "min7")
        XCTAssertEqual(ChordDefinitions.chord(for: "9th")?.id, "dom9")
        XCTAssertEqual(ChordDefinitions.chord(for: "11th")?.id, "dom11")
        XCTAssertEqual(ChordDefinitions.chord(for: "13th")?.id, "dom13")

        // Chord Voicing Inversions (Root Pos -> 1st Inv -> 2nd Inv)
        let cRoot = engine.chordVoicing(root: "C", qualityId: "major", inversion: 0).map { $0.note }
        let cFirst = engine.chordVoicing(root: "C", qualityId: "major", inversion: 1).map { $0.note }
        let cSecond = engine.chordVoicing(root: "C", qualityId: "major", inversion: 2).map { $0.note }
        XCTAssertEqual(cRoot, ["C4", "E4", "G4"])
        XCTAssertEqual(cFirst, ["E4", "G4", "C5"])
        XCTAssertEqual(cSecond, ["G4", "C5", "E5"])
    }

    // MARK: - Bundled Resources (TipsData.json & QuizData.json)

    func testBundledResourcesValidity() throws {
        // Locate TipsData.json and QuizData.json via ResourceLoader (crash-safe, never calls Bundle.module)
        let tipsURL = ResourceLoader.url(forResource: "TipsData", withExtension: "json")
        let quizURL = ResourceLoader.url(forResource: "QuizData", withExtension: "json")

        guard let validTipsURL = tipsURL, let validQuizURL = quizURL else {
            XCTFail("TipsData.json or QuizData.json not found via ResourceLoader")
            return
        }

        let tipsData = try Data(contentsOf: validTipsURL)
        let tipsArray = try JSONSerialization.jsonObject(with: tipsData) as? [[String: Any]]
        XCTAssertNotNil(tipsArray)
        XCTAssertEqual(tipsArray?.count, 32, "TipsData.json must contain 32 masterclass tips")
        let validTipIds = Set(tipsArray?.compactMap { $0["id"] as? String } ?? [])

        let decodedTips = ResourceLoader.decodeJSON([MasterclassTipModel].self, resource: "TipsData")
        XCTAssertNotNil(decodedTips)
        XCTAssertEqual(decodedTips?.count, 32, "ResourceLoader.decodeJSON must decode all 32 MasterclassTipModel items")

        let quizData = try Data(contentsOf: validQuizURL)
        let quizArray = try JSONSerialization.jsonObject(with: quizData) as? [[String: Any]]
        XCTAssertNotNil(quizArray)
        XCTAssertGreaterThanOrEqual(quizArray?.count ?? 0, 26, "QuizData.json must contain at least 26 conservatory quiz questions")

        // Decode into QuizQuestionModel via ResourceLoader & cross-validate every relatedTipId against TipsData.json
        let resourceDecoded = ResourceLoader.decodeJSON([QuizQuestionModel].self, resource: "QuizData")
        XCTAssertNotNil(resourceDecoded, "ResourceLoader.decodeJSON must decode QuizData.json")
        let decodedQuestions = try JSONDecoder().decode([QuizQuestionModel].self, from: quizData)
        XCTAssertEqual(decodedQuestions.count, quizArray?.count)
        XCTAssertEqual(resourceDecoded?.count, decodedQuestions.count)
        for q in decodedQuestions {
            XCTAssertEqual(q.options.count, 4, "Question \(q.id) must have 4 options")
            XCTAssertTrue((0..<4).contains(q.correctIndex), "Question \(q.id) has invalid correctIndex")
            if let tipId = q.relatedTipId {
                XCTAssertTrue(validTipIds.contains(tipId), "Question \(q.id) references missing relatedTipId '\(tipId)'")
            }
        }
    }

    func testDiatonicChordNotesParseIntoValidPlayableMIDIRange() {
        for root in KeyDefinitions.circleOfFifthsKeys.map({ $0.root }) {
            let chords = engine.diatonicChords(for: root)
            for chord in chords {
                for note in chord.notes {
                    let midi = engine.midiNote(for: note)
                    XCTAssertGreaterThanOrEqual(midi, 36, "Note \(note) in \(chord.fullName) parsed below C2")
                    XCTAssertLessThanOrEqual(midi, 96, "Note \(note) in \(chord.fullName) parsed above C7")
                }
            }
        }
        // Defensive clamping on invalid octave input (e.g. C44)
        XCTAssertEqual(engine.midiNote(for: "C44"), 127)
    }

    // MARK: - Strict 7-Letter Diatonic Spelling, Double Accidentals & Interval Calculus

    func testStrictDiatonicSpellingAndDoubleAccidentals() {
        // F# Major must use E# as its leading tone (never F)
        XCTAssertEqual(KeyDefinitions.keyInfo(for: "F#").majorScaleNotes, ["F#", "G#", "A#", "B", "C#", "D#", "E#"])
        XCTAssertEqual(
            engine.notes(forScale: "major", rootKey: "F#"),
            ["F#4", "G#4", "A#4", "B4", "C#5", "D#5", "E#5", "F#5"]
        )

        // G Harmonic Minor must spell b3 = Bb, b6 = Eb, leading tone = F#
        XCTAssertEqual(
            engine.notes(forScale: "harmonic_minor", rootKey: "G"),
            ["G4", "A4", "Bb4", "C5", "D5", "Eb5", "F#5", "G5"]
        )

        // Diminished 7th spelling must preserve stack of thirds (1, b3, b5, bb7)
        XCTAssertEqual(engine.chordNotes(root: "B", qualityId: "dim7"), ["B3", "D4", "F4", "Ab4"])
        XCTAssertEqual(engine.chordNotes(root: "C", qualityId: "dim7"), ["C4", "Eb4", "Gb4", "Bbb4"])

        // F# diatonic vii° triad root must be E#
        let fSharpTriads = engine.diatonicTriads(for: "F#")
        XCTAssertEqual(fSharpTriads.last?.root, "E#")

        // Double accidentals & E#5 round-trip accurately into MIDI & physical piano keys
        XCTAssertEqual(engine.midiNote(for: "Bbb4"), 69)
        XCTAssertEqual(engine.midiNote(for: "F##4"), 67)
        XCTAssertEqual(engine.midiNote(for: "E#5"), 77)
        XCTAssertEqual(engine.normalizeToPianoKey("Bbb4"), "A4")
        XCTAssertEqual(engine.normalizeToPianoKey("E#5"), "F5")
    }

    func testIntervalCalculusAndRuleOf9Inversions() {
        XCTAssertEqual(engine.interval(between: "C4", and: "F#4").shortName, "A4")
        XCTAssertEqual(engine.interval(between: "C4", and: "Gb4").shortName, "d5")
        XCTAssertEqual(engine.interval(between: "C4", and: "Ab4").shortName, "m6")

        let invM3 = engine.invertInterval("M3")
        XCTAssertEqual(invM3.invertedShortName, "m6")
        XCTAssertEqual(invM3.complementarySemitones, 8)

        let invP4 = engine.invertInterval("P4")
        XCTAssertEqual(invP4.invertedShortName, "P5")
        XCTAssertEqual(invP4.complementarySemitones, 7)

        let invA4 = engine.invertInterval("A4")
        XCTAssertEqual(invA4.invertedShortName, "d5")
        XCTAssertEqual(invA4.complementarySemitones, 6)

        let invm2 = engine.invertInterval("m2")
        XCTAssertEqual(invm2.invertedShortName, "M7")
        XCTAssertEqual(invm2.complementarySemitones, 11)
    }

    func testSpelledChordAndFiguredBassInversions() {
        let triadInv1 = engine.spelledChord(root: "C", qualityId: "major", inversion: 1)
        XCTAssertEqual(triadInv1.figuredBass, "6/3")
        XCTAssertEqual(triadInv1.bassNote, "E")
        XCTAssertEqual(triadInv1.inversionLabel, "1st Inversion")

        let triadInv2 = engine.spelledChord(root: "C", qualityId: "major", inversion: 2)
        XCTAssertEqual(triadInv2.figuredBass, "6/4")
        XCTAssertEqual(triadInv2.bassNote, "G")

        let seventhInv1 = engine.spelledChord(root: "G", qualityId: "dom7", inversion: 1)
        XCTAssertEqual(seventhInv1.figuredBass, "6/5")
        XCTAssertEqual(seventhInv1.bassNote, "B")

        let seventhInv2 = engine.spelledChord(root: "G", qualityId: "dom7", inversion: 2)
        XCTAssertEqual(seventhInv2.figuredBass, "4/3")
        XCTAssertEqual(seventhInv2.bassNote, "D")

        let seventhInv3 = engine.spelledChord(root: "G", qualityId: "dom7", inversion: 3)
        XCTAssertEqual(seventhInv3.figuredBass, "4/2")
        XCTAssertEqual(seventhInv3.bassNote, "F")
        XCTAssertEqual(seventhInv3.inversionLabel, "3rd Inversion")
    }

    // MARK: - Conservatory Quiz Generator & Backward-Compatible Storage Models

    func testQuizQuestionGeneratorAllDomainsAndModes() {
        let generator = QuizQuestionGenerator.shared

        // Exact lookup invariant: `"lydian"` must never match `"Mixolydian Mode"` substring first
        XCTAssertEqual(ScaleDefinitions.scale(for: "lydian")?.id, "lydian")
        XCTAssertEqual(ScaleDefinitions.scale(for: "mixolydian")?.id, "mixolydian")

        // Every domain must produce valid 4-option, non-duplicate MCQs across difficulties & iterations
        for domain in QuizDomain.allCases {
            for difficulty in [QuizDifficulty.beginner, .intermediate, .advanced] {
                for seed in 0..<5 {
                    let q = generator.generateQuestion(for: domain, difficulty: difficulty, isGuitar: false, variantSeed: seed)
                    XCTAssertEqual(q.options.count, 4, "Generated question in \(domain.rawValue) must have 4 options")
                    XCTAssertEqual(Set(q.options).count, 4, "Options in \(domain.rawValue) must all be unique: \(q.options)")
                    XCTAssertTrue((0..<4).contains(q.correctIndex))
                    XCTAssertFalse(q.explanation.isEmpty)
                    for visualNote in q.resolvedVisualNotes {
                        let midi = engine.midiNote(for: visualNote)
                        XCTAssertGreaterThanOrEqual(midi, 60, "Visual note \(visualNote) must stay within piano keybed >= C4")
                        XCTAssertLessThanOrEqual(midi, 84, "Visual note \(visualNote) must stay within piano keybed <= C6")
                    }
                }
            }
        }

        // Placement exam must yield 12 balanced items spanning at least 5 domains
        let placement = generator.buildSession(mode: .placementExam, instrument: "all", difficulty: .all, curatedQuestions: [], targetCount: 12)
        XCTAssertEqual(placement.count, 12)
        let coveredDomains = Set(placement.map(\.resolvedDomain))
        XCTAssertGreaterThanOrEqual(coveredDomains.count, 5)

        // Ear training lab must yield pure aural questions with valid playable audio cues
        let earLab = generator.buildSession(mode: .earTrainingLab, instrument: "piano", difficulty: .intermediate, curatedQuestions: [], targetCount: 10)
        XCTAssertEqual(earLab.count, 10)
        XCTAssertTrue(earLab.allSatisfy { $0.audioCue != nil && $0.resolvedDomain.isAuralDomain })

        // Weighted Conservatory Grade Tiers
        XCTAssertEqual(ConservatoryGradeTier.evaluate(weightedPercentage: 92).title, "Conservatory Laureate")
        XCTAssertEqual(ConservatoryGradeTier.evaluate(weightedPercentage: 80).title, "Concert Harmonicist")
        XCTAssertEqual(ConservatoryGradeTier.evaluate(weightedPercentage: 60).title, "Lyric Practitioner")
        XCTAssertEqual(ConservatoryGradeTier.evaluate(weightedPercentage: 40).title, "Apprentice Musician")
    }

    func testQuizResultRecordBackwardCompatibleDecoding() throws {
        // Legacy JSON produced prior to Conservatory Upgrade
        let legacyJSON = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "date": "2026-05-01T12:00:00Z",
            "score": 5,
            "totalQuestions": 6,
            "levelName": "Advanced Harmonicist",
            "category": "piano"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let legacy = try decoder.decode(QuizResultRecord.self, from: legacyJSON)
        XCTAssertEqual(legacy.score, 5)
        XCTAssertEqual(legacy.totalQuestions, 6)
        XCTAssertNil(legacy.mode)
        XCTAssertNil(legacy.weightedPercentage)
        XCTAssertNil(legacy.domainScores)

        // New Conservatory Record round-trip (whole-second epoch aligns with ISO-8601 encoder precision)
        let modern = QuizResultRecord(
            date: Date(timeIntervalSince1970: 1_780_000_000),
            score: 11,
            totalQuestions: 12,
            levelName: "Conservatory Laureate",
            category: "all",
            mode: "Placement Exam",
            weightedPercentage: 93.4,
            domainScores: [DomainPerformanceRecord(domain: .auralIntervals, correct: 2, total: 2)]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(modern)
        let roundTripped = try decoder.decode(QuizResultRecord.self, from: encoded)
        XCTAssertEqual(roundTripped, modern)
    }
}
