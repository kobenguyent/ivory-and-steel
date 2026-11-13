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

        let decodedTips = ResourceLoader.decodeJSON([MasterclassTipModel].self, resource: "TipsData")
        XCTAssertNotNil(decodedTips)
        XCTAssertEqual(decodedTips?.count, 32, "ResourceLoader.decodeJSON must decode all 32 MasterclassTipModel items")

        let quizData = try Data(contentsOf: validQuizURL)
        let quizArray = try JSONSerialization.jsonObject(with: quizData) as? [[String: Any]]
        XCTAssertNotNil(quizArray)
        XCTAssertEqual(quizArray?.count, 12, "QuizData.json must contain 12 quiz questions")

        let decodedQuiz = ResourceLoader.decodeJSON([QuizQuestionModel].self, resource: "QuizData")
        XCTAssertNotNil(decodedQuiz)
        XCTAssertEqual(decodedQuiz?.count, 12, "ResourceLoader.decodeJSON must decode all 12 QuizQuestionModel items")
    }
}
