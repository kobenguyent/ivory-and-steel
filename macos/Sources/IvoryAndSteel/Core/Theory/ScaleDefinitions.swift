import Foundation

/// 11 scale qualities for Ivory & Steel: Major, Natural Minor, Harmonic Minor, Melodic Minor,
/// Major Pentatonic, Minor Pentatonic, Blues, Dorian, Mixolydian, Phrygian, Lydian.
public enum ScaleDefinitions {
    public static let allScales: [ScaleQualityModel] = [
        ScaleQualityModel(
            id: "major",
            name: "Major Scale (Ionian)",
            category: "major",
            semitones: [0, 2, 4, 5, 7, 9, 11],
            intervalLabels: ["1", "2", "3", "4", "5", "6", "7", "8"],
            description: "The primary diatonic major scale. Formula: W-W-H-W-W-W-H. Bright, consonant, and foundational."
        ),
        ScaleQualityModel(
            id: "natural_minor",
            name: "Natural Minor (Aeolian)",
            category: "minor",
            semitones: [0, 2, 3, 5, 7, 8, 10],
            intervalLabels: ["1", "2", "b3", "4", "5", "b6", "b7", "8"],
            description: "The natural minor scale. Formula: W-H-W-W-H-W-W. Melancholic, dramatic, and emotionally resonant."
        ),
        ScaleQualityModel(
            id: "harmonic_minor",
            name: "Harmonic Minor",
            category: "minor",
            semitones: [0, 2, 3, 5, 7, 8, 11],
            intervalLabels: ["1", "2", "b3", "4", "5", "b6", "7", "8"],
            description: "Natural minor with a raised 7th (leading tone). Creates an exotic 1.5-step leap between ♭6 and 7."
        ),
        ScaleQualityModel(
            id: "melodic_minor",
            name: "Melodic Minor (Jazz)",
            category: "minor",
            semitones: [0, 2, 3, 5, 7, 9, 11],
            intervalLabels: ["1", "2", "b3", "4", "5", "6", "7", "8"],
            description: "Minor third with natural 6th and 7th. The essential parent scale for modern jazz improvisation."
        ),
        ScaleQualityModel(
            id: "major_pentatonic",
            name: "Major Pentatonic",
            category: "pentatonic",
            semitones: [0, 2, 4, 7, 9],
            intervalLabels: ["1", "2", "3", "5", "6", "8"],
            description: "5-note pure major scale with no clashing semitones. Ubiquitous in country, pop, and blues solos."
        ),
        ScaleQualityModel(
            id: "minor_pentatonic",
            name: "Minor Pentatonic",
            category: "pentatonic",
            semitones: [0, 3, 5, 7, 10],
            intervalLabels: ["1", "b3", "4", "5", "b7", "8"],
            description: "The ultimate rock and blues soloing scale. Contains degrees 1, ♭3, 4, 5, ♭7."
        ),
        ScaleQualityModel(
            id: "blues",
            name: "Blues Scale",
            category: "pentatonic",
            semitones: [0, 3, 5, 6, 7, 10],
            intervalLabels: ["1", "b3", "4", "b5", "5", "b7", "8"],
            description: "Minor pentatonic amplified with the crying \"Blue Note\" (diminished 5th / ♭5)."
        ),
        ScaleQualityModel(
            id: "dorian",
            name: "Dorian Mode",
            category: "mode",
            semitones: [0, 2, 3, 5, 7, 9, 10],
            intervalLabels: ["1", "2", "b3", "4", "5", "6", "b7", "8"],
            description: "The 2nd mode of the major scale. Minor with a sweet, raised natural 6th (Santana / So What)."
        ),
        ScaleQualityModel(
            id: "mixolydian",
            name: "Mixolydian Mode",
            category: "mode",
            semitones: [0, 2, 4, 5, 7, 9, 10],
            intervalLabels: ["1", "2", "3", "4", "5", "6", "b7", "8"],
            description: "The 5th mode of the major scale. Major with a bluesy flattened 7th. Southern rock and funk staple."
        ),
        ScaleQualityModel(
            id: "phrygian",
            name: "Phrygian Mode",
            category: "mode",
            semitones: [0, 1, 3, 5, 7, 8, 10],
            intervalLabels: ["1", "b2", "b3", "4", "5", "b6", "b7", "8"],
            description: "The 3rd mode of the major scale. Features a dark, immediate half-step ♭2. Spanish and metal flavor."
        ),
        ScaleQualityModel(
            id: "lydian",
            name: "Lydian Mode",
            category: "mode",
            semitones: [0, 2, 4, 6, 7, 9, 11],
            intervalLabels: ["1", "2", "3", "#4", "5", "6", "7", "8"],
            description: "The 4th mode of the major scale. Major with an ethereal raised 4th (♯4). Dreamy and cinematic."
        )
    ]

    /// Lookup scale quality by id or name
    public static func scale(for id: String) -> ScaleQualityModel? {
        let clean = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalized = clean.replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: " ", with: "_")

        return allScales.first(where: {
            $0.id.lowercased() == clean ||
            $0.id.lowercased() == normalized ||
            $0.name.lowercased().contains(clean)
        })
    }
}
