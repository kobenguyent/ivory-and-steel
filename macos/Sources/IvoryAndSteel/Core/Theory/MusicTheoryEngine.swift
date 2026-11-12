import Foundation

/// Core 12-TET Music Theory Engine for Ivory & Steel Native macOS.
/// Conforms to `MusicTheoryProtocol` and provides 12-TET mathematical frequency calculations,
/// scientific pitch notation parsing, enharmonic mapping, diatonic harmonization, and scale generation.
public final class MusicTheoryEngine: MusicTheoryProtocol, @unchecked Sendable {
    public static let shared = MusicTheoryEngine()

    public static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    public static let enharmonicMap: [String: String] = [
        "DB": "C#",
        "EB": "D#",
        "GB": "F#",
        "AB": "G#",
        "BB": "A#",
        "E#": "F",
        "B#": "C",
        "CB": "B"
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

    /// Converts scientific pitch notation (e.g. "C4", "F#3", "Bb5", "Db4") to standard MIDI note number (0-127).
    /// Defaults to Middle C (60) if parsing fails.
    public func midiNote(for noteName: String) -> Int {
        let trimmed = noteName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 60 }

        // Normalize unicode sharps/flats
        let normalized = trimmed
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")

        // Parse pitch letter, optional accidental (#, b), and octave number
        let pattern = "^([A-Ga-g][#b]?)(-?\\d+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 60 }
        let nsString = normalized as NSString
        let results = regex.matches(in: normalized, range: NSRange(location: 0, length: nsString.length))

        guard let match = results.first, match.numberOfRanges == 3 else {
            return 60
        }

        var pitch = nsString.substring(with: match.range(at: 1)).uppercased()
        let octaveStr = nsString.substring(with: match.range(at: 2))
        guard let octave = Int(octaveStr) else { return 60 }

        if let mapped = Self.enharmonicMap[pitch] {
            pitch = mapped
        }

        guard let noteIndex = Self.noteNames.firstIndex(of: pitch) else {
            return 60
        }

        // MIDI note 60 is C4: (octave + 1) * 12 + noteIndex
        return (octave + 1) * 12 + noteIndex
    }

    // MARK: - Enharmonic Mapping

    /// Returns the standard enharmonic sharp/flat equivalent.
    /// Handles single pitch roots (e.g. "Db" -> "C#", "Eb" -> "D#", "E#" -> "F", "B#" -> "C", "Cb" -> "B")
    /// as well as scientific notes with octaves (e.g. "Eb4" -> "D#4", "Bb5" -> "A#5").
    public func enharmonicEquivalent(of note: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")

        // Check if it's a bare pitch name
        let upper = trimmed.uppercased()
        if let mapped = Self.enharmonicMap[upper] {
            return mapped
        }

        // Check if note has an octave (e.g. "Db4")
        let pattern = "^([A-Ga-g][#b]?)(-?\\d+)$"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = trimmed as NSString
            let results = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            if let match = results.first, match.numberOfRanges == 3 {
                let pitch = nsString.substring(with: match.range(at: 1)).uppercased()
                let octave = nsString.substring(with: match.range(at: 2))
                if let mappedPitch = Self.enharmonicMap[pitch] {
                    return "\(mappedPitch)\(octave)"
                }
            }
        }

        return trimmed
    }

    /// Normalizes any scientific pitch note to its corresponding physical piano key (sharp convention, e.g. "Eb4" -> "D#4").
    public func normalizeToPianoKey(_ noteWithOctave: String) -> String {
        enharmonicEquivalent(of: noteWithOctave)
    }

    // MARK: - Scale Notes Generation

    /// Generates scale tones in scientific pitch notation (octave 4 to 5) for any of the 11 scale qualities.
    public func notes(forScale scaleId: String, rootKey: String) -> [String] {
        let key = KeyDefinitions.keyInfo(for: rootKey)
        let rootUpper = rootKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let rootPitch = KeyDefinitions.rootPitchMap[rootUpper] ?? key.pitchClass
        let quality = ScaleDefinitions.scale(for: scaleId) ?? ScaleDefinitions.allScales[0]
        let preferFlat = key.accidentalType == "flat" || rootKey.contains("b") || rootKey.contains("♭")

        var result: [String] = []

        for st in quality.semitones {
            let notePitch = (rootPitch + st) % 12
            let octaveOffset = (rootPitch + st) / 12
            let octave = 4 + octaveOffset
            let pitchName = KeyDefinitions.formatPitchName(pitchClass: notePitch, preferFlat: preferFlat)
            result.append("\(pitchName)\(octave)")
        }

        // Complete the octave resolution note
        let rootPitchName = KeyDefinitions.formatPitchName(pitchClass: rootPitch, preferFlat: preferFlat)
        result.append("\(rootPitchName)5")

        return result
    }

    // MARK: - Diatonic Chords (Triads & 7ths)

    /// Algorithmic 12-key diatonic 7th chord generator (I, ii, iii, IV, V, vi, vii°).
    public func diatonicChords(for rootKey: String) -> [DiatonicChordModel] {
        diatonicChords(for: rootKey, include7ths: true)
    }

    /// Algorithmic diatonic chord generator with choice between 7th chords or triads.
    public func diatonicChords(for rootKey: String, include7ths: Bool) -> [DiatonicChordModel] {
        let key = KeyDefinitions.keyInfo(for: rootKey)
        let rootUpper = rootKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let rootPitch = KeyDefinitions.rootPitchMap[rootUpper] ?? key.pitchClass
        let preferFlat = key.accidentalType == "flat" || rootKey.contains("b") || rootKey.contains("♭")

        struct ScaleDegree {
            let degree: String
            let semitone: Int
            let quality7th: String
            let qualityTriad: String
            let isTonic: Bool
            let isDominant: Bool
        }

        let degrees: [ScaleDegree] = [
            ScaleDegree(degree: "I", semitone: 0, quality7th: "maj7", qualityTriad: "major", isTonic: true, isDominant: false),
            ScaleDegree(degree: "ii", semitone: 2, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "iii", semitone: 4, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "IV", semitone: 5, quality7th: "maj7", qualityTriad: "major", isTonic: false, isDominant: false),
            ScaleDegree(degree: "V", semitone: 7, quality7th: "dom7", qualityTriad: "major", isTonic: false, isDominant: true),
            ScaleDegree(degree: "vi", semitone: 9, quality7th: "min7", qualityTriad: "minor", isTonic: false, isDominant: false),
            ScaleDegree(degree: "vii°", semitone: 11, quality7th: "m7b5", qualityTriad: "dim", isTonic: false, isDominant: false)
        ]

        return degrees.map { deg in
            let chordRootPitch = (rootPitch + deg.semitone) % 12
            let chordRootName = KeyDefinitions.formatPitchName(pitchClass: chordRootPitch, preferFlat: preferFlat)
            let qualityId = include7ths ? deg.quality7th : deg.qualityTriad
            let quality = ChordDefinitions.chord(for: qualityId)

            let semitones = quality?.semitones ?? (include7ths ? [0, 4, 7, 10] : [0, 4, 7])
            let startOctave = chordRootPitch >= 7 ? 3 : 4

            let notes: [String] = semitones.map { st in
                let notePitch = (chordRootPitch + st) % 12
                let octaveOffset = (chordRootPitch + st) / 12
                let octave = startOctave + octaveOffset
                let pitchName = KeyDefinitions.formatPitchName(pitchClass: notePitch, preferFlat: preferFlat)
                return "\(pitchName)\(octave)"
            }

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

    /// Generate notes for any arbitrary chord quality (e.g. "C", "dom7")
    public func chordNotes(root: String, qualityId: String) -> [String] {
        let key = KeyDefinitions.keyInfo(for: root)
        let rootUpper = root.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let rootPitch = KeyDefinitions.rootPitchMap[rootUpper] ?? key.pitchClass
        let quality = ChordDefinitions.chord(for: qualityId) ?? ChordDefinitions.allChords[0]
        let preferFlat = key.accidentalType == "flat" || root.contains("b") || root.contains("♭")

        let startOctave = rootPitch >= 7 ? 3 : 4

        return quality.semitones.map { st in
            let notePitch = (rootPitch + st) % 12
            let octaveOffset = (rootPitch + st) / 12
            let octave = startOctave + octaveOffset
            let pitchName = KeyDefinitions.formatPitchName(pitchClass: notePitch, preferFlat: preferFlat)
            return "\(pitchName)\(octave)"
        }
    }
}
