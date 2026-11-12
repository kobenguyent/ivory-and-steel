import Foundation

/// Chord quality definitions covering Triads, 7ths, Sus2, Sus4, Add9, 9th, 11th.
public enum ChordDefinitions {
    public static let allChords: [ChordQualityModel] = [
        // --- TRIADS ---
        ChordQualityModel(
            id: "major",
            name: "Major Triad",
            symbol: "",
            semitones: [0, 4, 7],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)"],
            description: "Pure, consonant, and uplifting foundation of Western harmony."
        ),
        ChordQualityModel(
            id: "minor",
            name: "Minor Triad",
            symbol: "m",
            semitones: [0, 3, 7],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Perfect 5th (5)"],
            description: "Somber, dramatic, and emotionally profound."
        ),
        ChordQualityModel(
            id: "dim",
            name: "Diminished Triad",
            symbol: "dim",
            semitones: [0, 3, 6],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Diminished 5th (b5)"],
            description: "High dissonance and tension, leading strongly back to tonic."
        ),
        ChordQualityModel(
            id: "aug",
            name: "Augmented Triad",
            symbol: "aug",
            semitones: [0, 4, 8],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Augmented 5th (#5)"],
            description: "Suspended, mysterious, and dreamlike with symmetrical major thirds."
        ),

        // --- 7THS ---
        ChordQualityModel(
            id: "dom7",
            name: "Dominant 7th",
            symbol: "7",
            semitones: [0, 4, 7, 10],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Minor 7th (b7)"],
            description: "Tense and bluesy, possessing a powerful tritone yearning to resolve."
        ),
        ChordQualityModel(
            id: "maj7",
            name: "Major 7th",
            symbol: "maj7",
            semitones: [0, 4, 7, 11],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Major 7th (7)"],
            description: "Lush, nostalgic, and sophisticated. Hallmark of jazz and neo-soul."
        ),
        ChordQualityModel(
            id: "min7",
            name: "Minor 7th",
            symbol: "m7",
            semitones: [0, 3, 7, 10],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Perfect 5th (5)", "Minor 7th (b7)"],
            description: "Mellow, introspective, and smooth. The definitive ii chord in jazz."
        ),
        ChordQualityModel(
            id: "m7b5",
            name: "Half-Diminished (m7♭5)",
            symbol: "m7b5",
            semitones: [0, 3, 6, 10],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Dim 5th (b5)", "Minor 7th (b7)"],
            description: "The quintessential ii chord in minor key jazz cadences."
        ),
        ChordQualityModel(
            id: "dim7",
            name: "Diminished 7th",
            symbol: "dim7",
            semitones: [0, 3, 6, 9],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Dim 5th (b5)", "Dim 7th (bb7)"],
            description: "Symmetrical stack of minor thirds; acts as a master harmonic pivot."
        ),

        // --- SUSPENDED ---
        ChordQualityModel(
            id: "sus2",
            name: "Suspended 2nd (sus2)",
            symbol: "sus2",
            semitones: [0, 2, 7],
            intervalLabels: ["Root (1)", "Major 2nd (2)", "Perfect 5th (5)"],
            description: "Airy, expansive, and gentle modern acoustic pop accompaniment."
        ),
        ChordQualityModel(
            id: "sus4",
            name: "Suspended 4th (sus4)",
            symbol: "sus4",
            semitones: [0, 5, 7],
            intervalLabels: ["Root (1)", "Perfect 4th (4)", "Perfect 5th (5)"],
            description: "Open and ambiguous, replacing the 3rd with a 4th anticipating resolution."
        ),

        // --- EXTENDED & ADD CHORDS ---
        ChordQualityModel(
            id: "add9",
            name: "Added 9th (add9)",
            symbol: "add9",
            semitones: [0, 4, 7, 14],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Major 9th (9)"],
            description: "Sparkling, rich acoustic pop and neo-classical triad with an added 9th."
        ),
        ChordQualityModel(
            id: "dom9",
            name: "Dominant 9th",
            symbol: "9",
            semitones: [0, 4, 7, 10, 14],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Minor 7th (b7)", "Major 9th (9)"],
            description: "Full and funky dominant extension commonly found in blues, funk, and jazz."
        ),
        ChordQualityModel(
            id: "maj9",
            name: "Major 9th",
            symbol: "maj9",
            semitones: [0, 4, 7, 11, 14],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Major 7th (7)", "Major 9th (9)"],
            description: "Ethereal, complex, and expansive jazz chord."
        ),
        ChordQualityModel(
            id: "min9",
            name: "Minor 9th",
            symbol: "m9",
            semitones: [0, 3, 7, 10, 14],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Perfect 5th (5)", "Minor 7th (b7)", "Major 9th (9)"],
            description: "Moody, melancholic modern jazz and R&B chord."
        ),
        ChordQualityModel(
            id: "dom11",
            name: "Dominant 11th",
            symbol: "11",
            semitones: [0, 4, 7, 10, 14, 17],
            intervalLabels: ["Root (1)", "Major 3rd (3)", "Perfect 5th (5)", "Minor 7th (b7)", "Major 9th (9)", "Perfect 11th (11)"],
            description: "Towering stack of thirds creating modern fusion and modal harmonic resonance."
        ),
        ChordQualityModel(
            id: "min11",
            name: "Minor 11th",
            symbol: "m11",
            semitones: [0, 3, 7, 10, 14, 17],
            intervalLabels: ["Root (1)", "Minor 3rd (b3)", "Perfect 5th (5)", "Minor 7th (b7)", "Major 9th (9)", "Perfect 11th (11)"],
            description: "Deep, ambient minor chord favored by McCoy Tyner and modern pianists."
        )
    ]

    /// Lookup chord quality by id or symbol
    public static func chord(for id: String) -> ChordQualityModel? {
        let clean = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalized = clean.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: " ", with: "_")

        return allChords.first(where: {
            $0.id.lowercased() == clean ||
            $0.id.lowercased() == normalized ||
            $0.symbol.lowercased() == clean ||
            $0.name.lowercased() == clean
        })
    }
}
