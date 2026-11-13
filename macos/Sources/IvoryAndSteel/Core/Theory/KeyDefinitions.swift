import Foundation

/// 12-Key Circle of Fifths definitions, relative minors, and pitch mapping for Ivory & Steel.
public enum KeyDefinitions {
    public static let circleOfFifthsKeys: [KeyInfoModel] = [
        KeyInfoModel(
            root: "C",
            name: "C Major",
            pitchClass: 0,
            sharpsCount: 0,
            flatsCount: 0,
            accidentalType: "natural",
            keySignatureDesc: "Natural (No sharps or flats)",
            relativeMinor: "A Minor",
            relativeMinorRoot: "A",
            majorScaleNotes: ["C", "D", "E", "F", "G", "A", "B"]
        ),
        KeyInfoModel(
            root: "G",
            name: "G Major",
            pitchClass: 7,
            sharpsCount: 1,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "1 Sharp (F♯)",
            relativeMinor: "E Minor",
            relativeMinorRoot: "E",
            majorScaleNotes: ["G", "A", "B", "C", "D", "E", "F#"]
        ),
        KeyInfoModel(
            root: "D",
            name: "D Major",
            pitchClass: 2,
            sharpsCount: 2,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "2 Sharps (F♯, C♯)",
            relativeMinor: "B Minor",
            relativeMinorRoot: "B",
            majorScaleNotes: ["D", "E", "F#", "G", "A", "B", "C#"]
        ),
        KeyInfoModel(
            root: "A",
            name: "A Major",
            pitchClass: 9,
            sharpsCount: 3,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "3 Sharps (F♯, C♯, G♯)",
            relativeMinor: "F# Minor",
            relativeMinorRoot: "F#",
            majorScaleNotes: ["A", "B", "C#", "D", "E", "F#", "G#"]
        ),
        KeyInfoModel(
            root: "E",
            name: "E Major",
            pitchClass: 4,
            sharpsCount: 4,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "4 Sharps (F♯, C♯, G♯, D♯)",
            relativeMinor: "C# Minor",
            relativeMinorRoot: "C#",
            majorScaleNotes: ["E", "F#", "G#", "A", "B", "C#", "D#"]
        ),
        KeyInfoModel(
            root: "B",
            name: "B Major",
            pitchClass: 11,
            sharpsCount: 5,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "5 Sharps (F♯, C♯, G♯, D♯, A♯)",
            relativeMinor: "G# Minor",
            relativeMinorRoot: "G#",
            majorScaleNotes: ["B", "C#", "D#", "E", "F#", "G#", "A#"]
        ),
        KeyInfoModel(
            root: "F#",
            name: "F# Major",
            pitchClass: 6,
            sharpsCount: 6,
            flatsCount: 0,
            accidentalType: "sharp",
            keySignatureDesc: "6 Sharps (F♯, C♯, G♯, D♯, A♯, E♯)",
            relativeMinor: "D# Minor",
            relativeMinorRoot: "D#",
            majorScaleNotes: ["F#", "G#", "A#", "B", "C#", "D#", "E#"]
        ),
        KeyInfoModel(
            root: "Db",
            name: "D♭ Major",
            pitchClass: 1,
            sharpsCount: 0,
            flatsCount: 5,
            accidentalType: "flat",
            keySignatureDesc: "5 Flats (B♭, E♭, A♭, D♭, G♭)",
            relativeMinor: "B♭ Minor",
            relativeMinorRoot: "Bb",
            majorScaleNotes: ["Db", "Eb", "F", "Gb", "Ab", "Bb", "C"]
        ),
        KeyInfoModel(
            root: "Ab",
            name: "A♭ Major",
            pitchClass: 8,
            sharpsCount: 0,
            flatsCount: 4,
            accidentalType: "flat",
            keySignatureDesc: "4 Flats (B♭, E♭, A♭, D♭)",
            relativeMinor: "F Minor",
            relativeMinorRoot: "F",
            majorScaleNotes: ["Ab", "Bb", "C", "Db", "Eb", "F", "G"]
        ),
        KeyInfoModel(
            root: "Eb",
            name: "E♭ Major",
            pitchClass: 3,
            sharpsCount: 0,
            flatsCount: 3,
            accidentalType: "flat",
            keySignatureDesc: "3 Flats (B♭, E♭, A♭)",
            relativeMinor: "C Minor",
            relativeMinorRoot: "C",
            majorScaleNotes: ["Eb", "F", "G", "Ab", "Bb", "C", "D"]
        ),
        KeyInfoModel(
            root: "Bb",
            name: "B♭ Major",
            pitchClass: 10,
            sharpsCount: 0,
            flatsCount: 2,
            accidentalType: "flat",
            keySignatureDesc: "2 Flats (B♭, E♭)",
            relativeMinor: "G Minor",
            relativeMinorRoot: "G",
            majorScaleNotes: ["Bb", "C", "D", "Eb", "F", "G", "A"]
        ),
        KeyInfoModel(
            root: "F",
            name: "F Major",
            pitchClass: 5,
            sharpsCount: 0,
            flatsCount: 1,
            accidentalType: "flat",
            keySignatureDesc: "1 Flat (B♭)",
            relativeMinor: "D Minor",
            relativeMinorRoot: "D",
            majorScaleNotes: ["F", "G", "A", "Bb", "C", "D", "E"]
        )
    ]

    public static let chromaticRoots: [String] = [
        "C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"
    ]

    public static let rootPitchMap: [String: Int] = [
        "C": 0, "C#": 1, "DB": 1,
        "D": 2, "D#": 3, "EB": 3,
        "E": 4, "FB": 4,
        "F": 5, "E#": 5,
        "F#": 6, "GB": 6,
        "G": 7, "G#": 8, "AB": 8,
        "A": 9, "A#": 10, "BB": 10,
        "B": 11, "CB": 11, "B#": 0
    ]

    public static let standardSharpPitchNames: [String] = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    public static let standardFlatPitchNames: [String] = [
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ]

    /// Lookup `KeyInfoModel` for a given root note name or pitch class
    public static func keyInfo(for root: String) -> KeyInfoModel {
        let upper = root.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if let direct = circleOfFifthsKeys.first(where: {
            $0.root.uppercased() == upper || $0.name.uppercased().hasPrefix(upper)
        }) {
            return direct
        }

        if let pitch = rootPitchMap[upper] {
            if let match = circleOfFifthsKeys.first(where: { $0.pitchClass == pitch }) {
                return match
            }
        }

        return circleOfFifthsKeys[0] // fallback to C Major
    }

    /// Format pitch name using preferred accidental style (# or b)
    public static func formatPitchName(pitchClass: Int, preferFlat: Bool = false) -> String {
        let normalized = ((pitchClass % 12) + 12) % 12
        return preferFlat
            ? standardFlatPitchNames[normalized]
            : standardSharpPitchNames[normalized]
    }
}
