import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case theoryExplorer = "Theory Explorer"
    case virtualPiano = "Virtual Piano"
    case guitarFretboard = "Guitar Fretboard"
    case metronome = "Metronome"
    case practiceRoutine = "Practice Routine"
    case masterclassHub = "Masterclass Tips"
    case musicianQuiz = "Level Quiz"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .theoryExplorer: return "circle.grid.cross"
        case .virtualPiano: return "pianokeys"
        case .guitarFretboard: return "guitars"
        case .metronome: return "metronome"
        case .practiceRoutine: return "timer"
        case .masterclassHub: return "book.closed"
        case .musicianQuiz: return "checkmark.seal"
        }
    }
}

