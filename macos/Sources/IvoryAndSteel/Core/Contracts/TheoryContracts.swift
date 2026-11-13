import Foundation

public protocol MusicTheoryProtocol: Sendable {
    func frequency(for midiNote: Int) -> Double
    func midiNote(for noteName: String) -> Int
    func diatonicChords(for rootKey: String) -> [DiatonicChordModel]
    func notes(forScale scaleId: String, rootKey: String) -> [String]
    func enharmonicEquivalent(of note: String) -> String
}

public struct DiatonicChordModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let degree: String
    public let root: String
    public let quality: String
    public let fullName: String
    public let notes: [String]
    public let isTonic: Bool
    public let isDominant: Bool

    public init(
        id: String,
        degree: String,
        root: String,
        quality: String,
        fullName: String,
        notes: [String],
        isTonic: Bool = false,
        isDominant: Bool = false
    ) {
        self.id = id
        self.degree = degree
        self.root = root
        self.quality = quality
        self.fullName = fullName
        self.notes = notes
        self.isTonic = isTonic
        self.isDominant = isDominant
    }
}

public struct KeyInfoModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let root: String
    public let name: String
    public let pitchClass: Int
    public let sharpsCount: Int
    public let flatsCount: Int
    public let accidentalType: String
    public let keySignatureDesc: String
    public let relativeMinor: String
    public let relativeMinorRoot: String
    public let majorScaleNotes: [String]

    public init(
        root: String,
        name: String,
        pitchClass: Int,
        sharpsCount: Int,
        flatsCount: Int,
        accidentalType: String,
        keySignatureDesc: String,
        relativeMinor: String,
        relativeMinorRoot: String,
        majorScaleNotes: [String]
    ) {
        self.id = root
        self.root = root
        self.name = name
        self.pitchClass = pitchClass
        self.sharpsCount = sharpsCount
        self.flatsCount = flatsCount
        self.accidentalType = accidentalType
        self.keySignatureDesc = keySignatureDesc
        self.relativeMinor = relativeMinor
        self.relativeMinorRoot = relativeMinorRoot
        self.majorScaleNotes = majorScaleNotes
    }
}

public struct ScaleQualityModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let semitones: [Int]
    public let intervalLabels: [String]
    public let description: String

    public init(
        id: String,
        name: String,
        category: String,
        semitones: [Int],
        intervalLabels: [String],
        description: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.semitones = semitones
        self.intervalLabels = intervalLabels
        self.description = description
    }
}

public struct ChordQualityModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let symbol: String
    public let semitones: [Int]
    public let intervalLabels: [String]
    public let description: String

    public init(
        id: String,
        name: String,
        symbol: String,
        semitones: [Int],
        intervalLabels: [String],
        description: String
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.semitones = semitones
        self.intervalLabels = intervalLabels
        self.description = description
    }
}

/// Conservatory interval taxonomy entry with diatonic step distance and Rule-of-9 inversion.
public struct IntervalModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let shortName: String
    public let name: String
    public let semitones: Int
    public let diatonicSteps: Int
    public let consonantCharacter: String

    public init(
        id: String,
        shortName: String,
        name: String,
        semitones: Int,
        diatonicSteps: Int,
        consonantCharacter: String
    ) {
        self.id = id
        self.shortName = shortName
        self.name = name
        self.semitones = semitones
        self.diatonicSteps = diatonicSteps
        self.consonantCharacter = consonantCharacter
    }
}

/// Strictly spelled chord voicing including inversion / figured-bass telemetry.
public struct SpelledChordModel: Sendable, Equatable {
    public let root: String
    public let qualityId: String
    public let symbol: String
    public let notes: [String]
    public let intervalLabels: [String]
    public let inversion: Int
    public let inversionLabel: String
    public let figuredBass: String
    public let bassNote: String

    public init(
        root: String,
        qualityId: String,
        symbol: String,
        notes: [String],
        intervalLabels: [String],
        inversion: Int,
        inversionLabel: String,
        figuredBass: String,
        bassNote: String
    ) {
        self.root = root
        self.qualityId = qualityId
        self.symbol = symbol
        self.notes = notes
        self.intervalLabels = intervalLabels
        self.inversion = inversion
        self.inversionLabel = inversionLabel
        self.figuredBass = figuredBass
        self.bassNote = bassNote
    }
}

