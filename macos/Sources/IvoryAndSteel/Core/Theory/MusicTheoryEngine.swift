import Foundation

/// Core 12-TET Music Theory Engine for Ivory & Steel Native macOS.
/// Conforms to `MusicTheoryProtocol` and provides 12-TET mathematical frequency calculations,
/// scientific pitch notation parsing, enharmonic mapping, diatonic harmonization, and scale generation.
public final class MusicTheoryEngine: MusicTheoryProtocol, @unchecked Sendable {
    public static let shared = MusicTheoryEngine()

    public static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private static let diatonicLetters = ["C", "D", "E", "F", "G", "A", "B"]
    private static let diatonicNaturalPitches = [0, 2, 4, 5, 7, 9, 11]

    public static let enharmonicMap: [String: String] = [
        "DB": "C#",
        "EB": "D#",
        "GB": "F#",
        "AB": "G#",
        "BB": "A#",
        "E#": "F",
        "B#": "C",
        "CB": "B",
        "FB": "E"
    ]

    /// Canonical conservatory interval taxonomy (semitones 0..12).
    public static let allIntervals: [IntervalModel] = [
        IntervalModel(id: "P1", shortName: "P1", name: "Perfect Unison", semitones: 0, diatonicSteps: 1, consonantCharacter: "Open Consonance"),
        IntervalModel(id: "m2", shortName: "m2", name: "Minor 2nd", semitones: 1, diatonicSteps: 2, consonantCharacter: "Sharp Dissonance"),
        IntervalModel(id: "M2", shortName: "M2", name: "Major 2nd", semitones: 2, diatonicSteps: 2, consonantCharacter: "Mild Dissonance"),
        IntervalModel(id: "m3", shortName: "m3", name: "Minor 3rd", semitones: 3, diatonicSteps: 3, consonantCharacter: "Imperfect Consonance"),
        IntervalModel(id: "M3", shortName: "M3", name: "Major 3rd", semitones: 4, diatonicSteps: 3, consonantCharacter: "Imperfect Consonance"),
        IntervalModel(id: "P4", shortName: "P4", name: "Perfect 4th", semitones: 5, diatonicSteps: 4, consonantCharacter: "Contextual Consonance"),
        IntervalModel(id: "TT", shortName: "TT", name: "Tritone (A4 / d5)", semitones: 6, diatonicSteps: 4, consonantCharacter: "Restless Dissonance"),
        IntervalModel(id: "P5", shortName: "P5", name: "Perfect 5th", semitones: 7, diatonicSteps: 5, consonantCharacter: "Open Consonance"),
        IntervalModel(id: "m6", shortName: "m6", name: "Minor 6th", semitones: 8, diatonicSteps: 6, consonantCharacter: "Imperfect Consonance"),
        IntervalModel(id: "M6", shortName: "M6", name: "Major 6th", semitones: 9, diatonicSteps: 6, consonantCharacter: "Imperfect Consonance"),
        IntervalModel(id: "m7", shortName: "m7", name: "Minor 7th", semitones: 10, diatonicSteps: 7, consonantCharacter: "Mild Dissonance"),
        IntervalModel(id: "M7", shortName: "M7", name: "Major 7th", semitones: 11, diatonicSteps: 7, consonantCharacter: "Sharp Dissonance"),
        IntervalModel(id: "P8", shortName: "P8", name: "Perfect Octave", semitones: 12, diatonicSteps: 8, consonantCharacter: "Open Consonance")
    ]

    public init() {}

    // MARK: - Frequency Calculation (12-TET)

    /// Calculate frequency in Hertz using 12-TET equal temperament: f(m) = 440.0 * 2^((m - 69) / 12)
    /// where m is the MIDI note number (A4 = 69 = 440 Hz).
    public func frequency(for midiNote: Int) -> Double {
        440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    /// Convenience: frequency for scientific note name (e.g. "A4" -> 440.0)
    public func frequency(for noteName: String) -> Double {
        frequency(for: midiNote(for: noteName))
    }

    // MARK: - Pitch Parsing & MIDI Note Number

    private func normalizeAccidentalASCII(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "𝄪", with: "##")
            .replacingOccurrences(of: "𝄫", with: "bb")
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
    }

    /// Parses a bare pitch (e.g. "F#", "Bbb", "Cx", "Db") into `(letterIndex 0..6, pitchClass 0..11, accidentalOffset -2..2)`.
    private func parsePitchToken(_ token: String) -> (letterIndex: Int, pitchClass: Int, accidentalOffset: Int)? {
        let normalized = normalizeAccidentalASCII(token)
        guard let firstChar = normalized.first else { return nil }
        let upperLetter = String(firstChar).uppercased()
        guard let letterIndex = Self.diatonicLetters.firstIndex(of: upperLetter) else {
            return nil
        }

        let accidental = String(normalized.dropFirst()).lowercased()
        let offset: Int
        switch accidental {
        case "": offset = 0
        case "#": offset = 1
        case "##", "x": offset = 2
        case "b": offset = -1
        case "bb": offset = -2
        default: return nil
        }

        let pitchClass = ((Self.diatonicNaturalPitches[letterIndex] + offset) % 12 + 12) % 12
        return (letterIndex, pitchClass, offset)
    }

    /// Converts scientific pitch notation (e.g. "C4", "F#3", "Bb5", "E#5", "Bbb4") to standard MIDI note number (0-127).
    /// Defaults to Middle C (60) if parsing fails.
    public func midiNote(for noteName: String) -> Int {
        let normalized = normalizeAccidentalASCII(noteName)
        guard !normalized.isEmpty else { return 60 }

        // Parse pitch letter, optional accidental (#, ##, x, b, bb), and octave number
        let pattern = "^([A-Ga-g](?:##|bb|[#bxX])?)(-?\\d+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 60 }
        let nsString = normalized as NSString
        let results = regex.matches(in: normalized, range: NSRange(location: 0, length: nsString.length))

        guard let match = results.first, match.numberOfRanges == 3 else {
            return 60
        }

        let pitchStr = nsString.substring(with: match.range(at: 1))
        let octaveStr = nsString.substring(with: match.range(at: 2))
        guard let octave = Int(octaveStr),
              let parsed = parsePitchToken(pitchStr) else {
            return 60
        }

        // Preserve established octave-wrapped convention (e.g. B#4 -> C4 = 60, Cb4 -> B4 = 71)
        return max(0, min(127, (octave + 1) * 12 + parsed.pitchClass))
    }

    // MARK: - Enharmonic Mapping

    /// Returns the standard enharmonic sharp/flat equivalent.
    /// Handles double accidentals ("Bbb4" -> "A4", "F##4" -> "G4"), single pitch roots ("Db" -> "C#", "E#" -> "F"),
    /// and scientific notes with octaves ("Eb4" -> "D#4", "Bbb4" -> "A4").
    public func enharmonicEquivalent(of note: String) -> String {
        let trimmed = normalizeAccidentalASCII(note)
        let upper = trimmed.uppercased()
        if let mapped = Self.enharmonicMap[upper] {
            return mapped
        }

        // Bare double-accidental normalization
        if let parsed = parsePitchToken(trimmed), abs(parsed.accidentalOffset) == 2 {
            return Self.noteNames[parsed.pitchClass]
        }

        // Note with octave (e.g. "Db4", "E#5", "Bbb4")
        let pattern = "^([A-Ga-g](?:##|bb|[#bxX])?)(-?\\d+)$"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = trimmed as NSString
            let results = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            if let match = results.first, match.numberOfRanges == 3 {
                let pitch = nsString.substring(with: match.range(at: 1))
                let octave = nsString.substring(with: match.range(at: 2))
                if let mappedPitch = Self.enharmonicMap[pitch.uppercased()] {
                    return "\(mappedPitch)\(octave)"
                }
                if let parsed = parsePitchToken(pitch), abs(parsed.accidentalOffset) == 2 {
                    return "\(Self.noteNames[parsed.pitchClass])\(octave)"
                }
            }
        }

        return trimmed
    }

    /// Normalizes any scientific pitch note to its corresponding physical piano key (sharp convention, e.g. "Eb4" -> "D#4").
    public func normalizeToPianoKey(_ noteWithOctave: String) -> String {
        enharmonicEquivalent(of: noteWithOctave)
    }

    // MARK: - Strict 7-Letter Diatonic Spelling Solver

    private func accidentalString(for offset: Int) -> String {
        switch offset {
        case 2: return "##"
        case 1: return "#"
        case 0: return ""
        case -1: return "b"
        case -2: return "bb"
        default: return offset > 0 ? String(repeating: "#", count: offset) : String(repeating: "b", count: abs(offset))
        }
    }

    /// Extracts diatonic letter step offset (0..6) from an interval label such as `"b3"`, `"#4"`, `"Perfect 5th (5)"`, `"Major 13th (13)"`.
    private func diatonicStepOffset(fromIntervalLabel label: String, fallbackIndex: Int) -> Int {
        // Prefer trailing/parenthesized numeric degree token so `"Perfect 5th (5)"` parses `5` instead of `55`.
        let pattern = "(\\d+)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsLabel = label as NSString
            let matches = regex.matches(in: label, range: NSRange(location: 0, length: nsLabel.length))
            if let lastMatch = matches.last {
                let token = nsLabel.substring(with: lastMatch.range)
                if let number = Int(token), number >= 1 {
                    return (number - 1) % 7
                }
            }
        }
        return fallbackIndex % 7
    }

    /// Spells a target pitch class strictly relative to a root letter and diatonic step offset (`0` = root, `1` = 2nd, ..., `6` = 7th).
    public func spellPitch(
        rootLetterIndex: Int,
        rootPitchClass: Int,
        semitonesFromRoot: Int,
        diatonicStepOffset: Int
    ) -> String {
        let targetLetterIndex = ((rootLetterIndex + diatonicStepOffset) % 7 + 7) % 7
        let targetLetter = Self.diatonicLetters[targetLetterIndex]
        let naturalPitch = Self.diatonicNaturalPitches[targetLetterIndex]
        let targetPitch = ((rootPitchClass + semitonesFromRoot) % 12 + 12) % 12
        let signedDiff = ((targetPitch - naturalPitch + 18) % 12) - 6

        if abs(signedDiff) <= 2 {
            return "\(targetLetter)\(accidentalString(for: signedDiff))"
        }
        // Exotic outlier (> double accidental): fallback cleanly to standard note table
        return Self.noteNames[targetPitch]
    }

    /// Canonicalizes a root key token into a clean `(rootLetterIndex, rootPitchClass, canonicalRootName)` tuple.
    private func resolveRoot(_ rootKey: String) -> (letterIndex: Int, pitchClass: Int, displayName: String) {
        let trimmed = normalizeAccidentalASCII(rootKey)
        if let parsed = parsePitchToken(trimmed) {
            let letter = Self.diatonicLetters[parsed.letterIndex]
            return (parsed.letterIndex, parsed.pitchClass, "\(letter)\(accidentalString(for: parsed.accidentalOffset))")
        }
        let info = KeyDefinitions.keyInfo(for: rootKey)
        if let parsed = parsePitchToken(info.root) {
            let letter = Self.diatonicLetters[parsed.letterIndex]
            return (parsed.letterIndex, parsed.pitchClass, "\(letter)\(accidentalString(for: parsed.accidentalOffset))")
        }
        return (0, 0, "C")
    }

    // MARK: - Scale Notes Generation

    /// Generates strictly spelled scale tones in scientific pitch notation (octave 4 to 5) for any of the 11 scale qualities.
    public func notes(forScale scaleId: String, rootKey: String) -> [String] {
        let root = resolveRoot(rootKey)
        let quality = ScaleDefinitions.scale(for: scaleId) ?? ScaleDefinitions.allScales[0]

        var result: [String] = []

        for (idx, st) in quality.semitones.enumerated() {
            let targetMidi = 60 + root.pitchClass + st
            let octave = (targetMidi / 12) - 1
            let label = idx < quality.intervalLabels.count ? quality.intervalLabels[idx] : "\(idx + 1)"
            let stepOffset = diatonicStepOffset(fromIntervalLabel: label, fallbackIndex: idx)
            let pitchName = spellPitch(
                rootLetterIndex: root.letterIndex,
                rootPitchClass: root.pitchClass,
                semitonesFromRoot: st,
                diatonicStepOffset: stepOffset
            )
            result.append("\(pitchName)\(octave)")
        }

        // Complete the octave resolution note
        result.append("\(root.displayName)5")
        return result
    }

    // MARK: - Diatonic Chords (Triads & 7ths)

    /// Algorithmic 12-key diatonic 7th chord generator (I, ii, iii, IV, V, vi, vii°).
    public func diatonicChords(for rootKey: String) -> [DiatonicChordModel] {
        diatonicChords(for: rootKey, include7ths: true)
    }

    /// Algorithmic diatonic chord generator with choice between 7th chords or triads using strict 7-letter spelling.
    public func diatonicChords(for rootKey: String, include7ths: Bool) -> [DiatonicChordModel] {
        let root = resolveRoot(rootKey)

        struct ScaleDegree {
            let degree: String
            let stepOffset: Int
            let semitone: Int
            let quality7th: String
            let qualityTriad: String
            let isTonic: Bool
            let isDominant: Bool
        }

        let degrees: [ScaleDegree] = [
            ScaleDegree(degree: "I", stepOffset: 0, semitone: 0, quality7th: "maj7", qualityTriad: "major", isTonic: true, isDominant: false),
            ScaleDegree(degree: "ii", stepOffset: 1, semitone: 2, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "iii", stepOffset: 2, semitone: 4, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "IV", stepOffset: 3, semitone: 5, quality7th: "maj7", qualityTriad: "major", isTonic: false, isDominant: false),
            ScaleDegree(degree: "V", stepOffset: 4, semitone: 7, quality7th: "dom7", qualityTriad: "major", isTonic: false, isDominant: true),
            ScaleDegree(degree: "vi", stepOffset: 5, semitone: 9, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "vii°", stepOffset: 6, semitone: 11, quality7th: "m7b5", qualityTriad: "dim", isTonic: false, isDominant: false)
        ]

        return degrees.map { deg in
            let chordRootName = spellPitch(
                rootLetterIndex: root.letterIndex,
                rootPitchClass: root.pitchClass,
                semitonesFromRoot: deg.semitone,
                diatonicStepOffset: deg.stepOffset
            )
            let qualityId = include7ths ? deg.quality7th : deg.qualityTriad
            let quality = ChordDefinitions.chord(for: qualityId)
            let notes = chordNotes(root: chordRootName, qualityId: qualityId)

            let qualityName = quality?.name ?? qualityId
            let fullName = "\(chordRootName) \(deg.degree) (\(chordRootName) \(qualityName))"
            let id = "\(rootKey)-\(deg.degree)"

            return DiatonicChordModel(
                id: id,
                degree: deg.degree,
                root: chordRootName,
                quality: qualityId,
                fullName: fullName,
                notes: notes,
                isTonic: deg.isTonic,
                isDominant: deg.isDominant
            )
        }
    }

    /// Convenience: diatonic triads (I, ii, iii, IV, V, vi, vii°)
    public func diatonicTriads(for rootKey: String) -> [DiatonicChordModel] {
        diatonicChords(for: rootKey, include7ths: false)
    }

    /// Generate strictly spelled notes for any arbitrary chord quality (e.g. "C", "dom7", "dim7", "m7b5").
    public func chordNotes(root: String, qualityId: String) -> [String] {
        let resolved = resolveRoot(root)
        let quality = ChordDefinitions.chord(for: qualityId) ?? ChordDefinitions.allChords[0]
        let startOctave = resolved.pitchClass >= 7 ? 3 : 4

        return quality.semitones.enumerated().map { idx, st in
            let targetMidi = (startOctave + 1) * 12 + resolved.pitchClass + st
            let octave = (targetMidi / 12) - 1
            let label = idx < quality.intervalLabels.count ? quality.intervalLabels[idx] : "\(idx + 1)"
            let stepOffset: Int
            if quality.id == "dim7" && st == 9 {
                stepOffset = 6 // Diminished 7th is always letter step 7 (bb7), never 6
            } else {
                stepOffset = diatonicStepOffset(fromIntervalLabel: label, fallbackIndex: idx)
            }
            let pitchName = spellPitch(
                rootLetterIndex: resolved.letterIndex,
                rootPitchClass: resolved.pitchClass,
                semitonesFromRoot: st,
                diatonicStepOffset: stepOffset
            )
            return "\(pitchName)\(octave)"
        }
    }

    /// Generate an octave-4-anchored strictly spelled chord voicing with inversion rotation (0 = Root, 1 = 1st Inv, etc.).
    public func spelledChord(root: String, qualityId: String, inversion: Int = 0) -> SpelledChordModel {
        let resolved = resolveRoot(root)
        let quality = ChordDefinitions.chord(for: qualityId) ?? ChordDefinitions.allChords[0]

        let rootMidi = 60 + resolved.pitchClass // C4..B4
        let invCount = max(0, min(inversion, max(0, quality.semitones.count - 1)))

        let pairs: [(midi: Int, note: String, intervalLabel: String)] = quality.semitones.enumerated().map { idx, st in
            let invertedOctaveShift = (idx < invCount) ? 12 : 0
            let midi = min(127, rootMidi + st + invertedOctaveShift)
            let octave = (midi / 12) - 1
            let rawLabel = idx < quality.intervalLabels.count ? quality.intervalLabels[idx] : "\(idx + 1)"
            let stepOffset = (quality.id == "dim7" && st == 9)
                ? 6
                : diatonicStepOffset(fromIntervalLabel: rawLabel, fallbackIndex: idx)
            let pitchName = spellPitch(
                rootLetterIndex: resolved.letterIndex,
                rootPitchClass: resolved.pitchClass,
                semitonesFromRoot: st,
                diatonicStepOffset: stepOffset
            )
            return (midi: midi, note: "\(pitchName)\(octave)", intervalLabel: rawLabel)
        }
        .sorted { $0.midi < $1.midi }

        let notes = pairs.map(\.note)
        let labels = pairs.map(\.intervalLabel)
        let bassPitchOnly = notes.first.map { String($0.prefix { !$0.isNumber && $0 != "-" }) } ?? resolved.displayName
        let meta = chordInversionMeta(qualityId: quality.id, inversion: invCount, bassNote: bassPitchOnly)

        return SpelledChordModel(
            root: resolved.displayName,
            qualityId: quality.id,
            symbol: "\(resolved.displayName)\(quality.symbol)",
            notes: notes,
            intervalLabels: labels,
            inversion: invCount,
            inversionLabel: meta.label,
            figuredBass: meta.figuredBass,
            bassNote: bassPitchOnly
        )
    }

    /// Generate an octave-4-anchored chord voicing with inversion rotation (0 = Root, 1 = 1st Inv, etc.)
    /// Returns ascending `(note, intervalLabel)` pairs suitable for keyboard display and auditioning.
    public func chordVoicing(root: String, qualityId: String, inversion: Int = 0) -> [(note: String, intervalLabel: String)] {
        let spelled = spelledChord(root: root, qualityId: qualityId, inversion: inversion)
        return Array(zip(spelled.notes, spelled.intervalLabels)).map { ($0.0, $0.1) }
    }

    // MARK: - Conservatory Interval Calculus & Chord Inversion Metadata

    /// Looks up the conservatory `IntervalModel` for a semitone span (`0..12`).
    public func intervalInfo(forSemitones semitones: Int, preferAugmentedFourth: Bool = true) -> IntervalModel {
        let clamped = max(0, min(12, semitones))
        if clamped == 6 && !preferAugmentedFourth {
            return IntervalModel(id: "d5", shortName: "d5", name: "Diminished 5th", semitones: 6, diatonicSteps: 5, consonantCharacter: "Restless Dissonance")
        }
        if clamped == 6 {
            return IntervalModel(id: "A4", shortName: "A4", name: "Augmented 4th (Tritone)", semitones: 6, diatonicSteps: 4, consonantCharacter: "Restless Dissonance")
        }
        return Self.allIntervals.first { $0.semitones == clamped } ?? Self.allIntervals[0]
    }

    /// Computes the true spelled interval between two scientific pitch notes (distinguishing `A4` vs `d5` from letter names).
    public func interval(between lowerNote: String, and upperNote: String) -> IntervalModel {
        let lowerMidi = midiNote(for: lowerNote)
        let upperMidi = midiNote(for: upperNote)
        let semitoneDiff = abs(upperMidi - lowerMidi)

        if semitoneDiff == 12 {
            return Self.allIntervals.last! // P8
        }
        let modSemitones = semitoneDiff % 12

        let lowerToken = String(normalizeAccidentalASCII(lowerNote).prefix { !$0.isNumber && $0 != "-" })
        let upperToken = String(normalizeAccidentalASCII(upperNote).prefix { !$0.isNumber && $0 != "-" })

        if modSemitones == 6,
           let lowerParsed = parsePitchToken(lowerToken),
           let upperParsed = parsePitchToken(upperToken) {
            let letterDistance = ((upperParsed.letterIndex - lowerParsed.letterIndex) % 7 + 7) % 7 + 1
            return intervalInfo(forSemitones: 6, preferAugmentedFourth: letterDistance != 5)
        }

        return intervalInfo(forSemitones: modSemitones)
    }

    /// Applies the conservatory Rule of 9 (`9 - number`, quality flip `M<->m`, `P<->P`, `A<->d`) to invert an interval.
    public func invertInterval(_ shortName: String) -> (invertedShortName: String, invertedName: String, complementarySemitones: Int) {
        let trimmed = shortName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "TT" {
            return ("TT", "Tritone (A4 / d5)", 6)
        }
        guard let firstChar = trimmed.first else {
            return ("P8", "Perfect Octave", 12)
        }
        let number = Int(String(trimmed.dropFirst())) ?? 1
        let invertedNumber = max(1, min(8, 9 - number))

        let flippedQuality: Character
        let qualityWord: String
        switch firstChar {
        case "M": flippedQuality = "m"; qualityWord = "Minor"
        case "m": flippedQuality = "M"; qualityWord = "Major"
        case "P": flippedQuality = "P"; qualityWord = "Perfect"
        case "A": flippedQuality = "d"; qualityWord = "Diminished"
        case "d": flippedQuality = "A"; qualityWord = "Augmented"
        default: flippedQuality = firstChar; qualityWord = ""
        }

        let ordinal: String
        switch invertedNumber {
        case 1: ordinal = "Unison"
        case 2: ordinal = "2nd"
        case 3: ordinal = "3rd"
        case 8: ordinal = "Octave"
        default: ordinal = "\(invertedNumber)th"
        }

        let existingSemitones: Int
        switch trimmed {
        case "P1": existingSemitones = 0
        case "m2": existingSemitones = 1
        case "M2", "d3": existingSemitones = 2
        case "m3", "A2": existingSemitones = 3
        case "M3", "d4": existingSemitones = 4
        case "P4": existingSemitones = 5
        case "A4", "d5": existingSemitones = 6
        case "P5": existingSemitones = 7
        case "m6", "A5": existingSemitones = 8
        case "M6", "d7": existingSemitones = 9
        case "m7", "A6": existingSemitones = 10
        case "M7": existingSemitones = 11
        case "P8": existingSemitones = 12
        default: existingSemitones = 0
        }

        let complementary = 12 - existingSemitones
        let invertedShort = "\(flippedQuality)\(invertedNumber)"
        let invertedFull = qualityWord.isEmpty ? invertedShort : "\(qualityWord) \(ordinal)"
        return (invertedShort, invertedFull, complementary)
    }

    /// Returns human-readable inversion name and traditional figured bass symbol (`5/3`, `6/3`, `6/4` for triads; `7`, `6/5`, `4/3`, `4/2` for 7ths).
    public func chordInversionMeta(qualityId: String, inversion: Int, bassNote: String) -> (label: String, figuredBass: String, bassNote: String) {
        let quality = ChordDefinitions.chord(for: qualityId) ?? ChordDefinitions.allChords[0]
        let isTriad = quality.semitones.count <= 3
        let clampedInv = max(0, min(inversion, max(0, quality.semitones.count - 1)))

        if isTriad {
            switch clampedInv {
            case 0: return ("Root Position", "5/3", bassNote)
            case 1: return ("1st Inversion", "6/3", bassNote)
            default: return ("2nd Inversion", "6/4", bassNote)
            }
        } else {
            switch clampedInv {
            case 0: return ("Root Position", "7", bassNote)
            case 1: return ("1st Inversion", "6/5", bassNote)
            case 2: return ("2nd Inversion", "4/3", bassNote)
            default: return ("3rd Inversion", "4/2", bassNote)
            }
        }
    }

    /// Converts ASCII accidentals inside standalone note/chord tokens (`F#`, `Bbb`, `F##`, `Eb`) into Unicode engraver glyphs (`♯`, `𝄫`, `𝄪`, `♭`).
    public static func formatNotationGlyphs(_ token: String) -> String {
        token
            .replacingOccurrences(of: "##", with: "𝄪")
            .replacingOccurrences(of: "bb", with: "𝄫")
            .replacingOccurrences(of: "#", with: "♯")
            .replacingOccurrences(of: "b", with: "♭")
    }
}
