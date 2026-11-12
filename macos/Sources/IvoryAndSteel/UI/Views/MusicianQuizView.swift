import SwiftUI

// MARK: - Quiz Question Decodable Model

public struct QuizQuestionModel: Codable, Identifiable, Sendable {
    public let id: String
    public let instrument: String
    public let level: String
    public let question: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String
    public let relatedTipId: String?
}

/// Musician Quiz Studio View:
/// Ear training and music theory level assessment diagnostic quiz,
/// dynamic scoring, instant pedagogical feedback, and persistence via StorageManager.
public struct MusicianQuizView: View {
    @Environment(AppState.self) private var appState
    
    @State private var questions: [QuizQuestionModel] = []
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isAnswerSubmitted: Bool = false
    @State private var score: Int = 0
    @State private var isQuizFinished: Bool = false
    
    @State private var filterInstrument: String = "all"
    @State private var pastResults: [QuizResultRecord] = []
    
    public init() {}
    
    private var activeQuestions: [QuizQuestionModel] {
        if filterInstrument == "all" {
            return questions
        }
        return questions.filter { $0.instrument.lowercased() == filterInstrument.lowercased() }
    }
    
    private var currentQuestion: QuizQuestionModel? {
        guard !activeQuestions.isEmpty, currentIndex < activeQuestions.count else { return nil }
        return activeQuestions[currentIndex]
    }
    
    private var levelRating: String {
        guard !activeQuestions.isEmpty else { return "Developing Musician" }
        let pct = (Double(score) / Double(activeQuestions.count)) * 100.0
        if pct >= 90 { return "Virtuoso Maestro" }
        if pct >= 70 { return "Advanced Harmonicist" }
        if pct >= 50 { return "Intermediate Practitioner" }
        return "Developing Musician"
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Bar & Mode Selector
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Musician Diagnostic & Level Quiz")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text("Assess your music theory, ear training, and biomechanical comprehension")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                    Picker("Instrument Category", selection: $filterInstrument) {
                        Text("All Questions").tag("all")
                        Text("Piano Specialization").tag("piano")
                        Text("Guitar Specialization").tag("guitar")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: filterInstrument) { _, _ in
                        restartQuiz()
                    }
                }
                .padding(16)
                .background(Color.musicianCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                if isQuizFinished {
                    // Result Scorecard
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 54))
                            .foregroundColor(Color.musicianGold)
                            .shadow(color: Color.musicianGold.opacity(0.5), radius: 10)
                        
                        Text("Diagnostic Assessment Completed")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        Text("Assigned Skill Tier: \(levelRating)")
                            .font(.system(size: 15, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.musicianGoldLight)
                        
                        Text("Final Score: \(score) of \(activeQuestions.count) (\(Int((Double(score) / Double(max(1, activeQuestions.count))) * 100))%)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.musicianIvory)
                        
                        Button(action: restartQuiz) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Retake Diagnostic Quiz")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundColor(Color.musicianEbony)
                            .background(Color.musicianGold)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.musicianGold.opacity(0.3), lineWidth: 1)
                    )
                } else if let q = currentQuestion {
                    // Active Question View
                    VStack(alignment: .leading, spacing: 18) {
                        // Progress Bar & Question Counter
                        HStack {
                            Text("Question \(currentIndex + 1) of \(activeQuestions.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.musicianGold)
                            
                            Spacer()
                            
                            Text("Current Score: \(score)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.gray)
                        }
                        
                        // Question Prompt
                        Text(q.question)
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                            .lineSpacing(3)
                        
                        // Options List
                        VStack(spacing: 10) {
                            ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                                OptionButton(
                                    label: "\(Character(UnicodeScalar(65 + idx)!)).",
                                    text: option,
                                    isSelected: selectedOptionIndex == idx,
                                    isSubmitted: isAnswerSubmitted,
                                    isCorrect: idx == q.correctIndex,
                                    onSelect: {
                                        guard !isAnswerSubmitted else { return }
                                        selectedOptionIndex = idx
                                        submitAnswer(choice: idx, correct: q.correctIndex)
                                    }
                                )
                            }
                        }
                        
                        // Explanation & Next Button
                        if isAnswerSubmitted {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: selectedOptionIndex == q.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(selectedOptionIndex == q.correctIndex ? Color.subdominantEmerald : Color.steinwayCrimson)
                                        .font(.system(size: 14))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(selectedOptionIndex == q.correctIndex ? "CORRECT" : "INCORRECT")
                                            .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                                            .foregroundColor(selectedOptionIndex == q.correctIndex ? Color.subdominantEmerald : Color.steinwayCrimson)
                                        
                                        Text(q.explanation)
                                            .font(.system(size: 11.5))
                                            .foregroundColor(Color.musicianIvory.opacity(0.9))
                                            .lineSpacing(2)
                                    }
                                }
                                
                                HStack {
                                    Spacer()
                                    Button(action: nextQuestion) {
                                        HStack(spacing: 6) {
                                            Text(currentIndex + 1 < activeQuestions.count ? "Next Question" : "View Results")
                                            Image(systemName: "arrow.right")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .foregroundColor(Color.musicianEbony)
                                        .background(Color.musicianGold)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(14)
                            .background(Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(20)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.musicianGold.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Past Assessment History
                if !pastResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Past Assessment Results")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)
                        
                        ForEach(pastResults.prefix(5)) { res in
                            HStack {
                                Image(systemName: "rosette")
                                    .foregroundColor(Color.musicianGold)
                                
                                Text(res.levelName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.musicianIvory)
                                
                                Spacer()
                                
                                Text("\(res.score)/\(res.totalQuestions)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.musicianGold)
                                
                                Text(res.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(10)
                            .background(Color.musicianSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(16)
                    .background(Color.musicianCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .background(Color.musicianEbony)
        .onAppear {
            loadQuestions()
            pastResults = StorageManager.shared.quizResults
        }
    }
    
    private func submitAnswer(choice: Int, correct: Int) {
        isAnswerSubmitted = true
        if choice == correct {
            score += 1
            // Play rewarding chime
            appState.playPiano(midi: 72, velocity: 0.7, duration: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.appState.playPiano(midi: 76, velocity: 0.8, duration: 1.2)
            }
        }
    }
    
    private func nextQuestion() {
        if currentIndex + 1 < activeQuestions.count {
            currentIndex += 1
            selectedOptionIndex = nil
            isAnswerSubmitted = false
        } else {
            isQuizFinished = true
            let result = QuizResultRecord(
                score: score,
                totalQuestions: activeQuestions.count,
                levelName: levelRating,
                category: filterInstrument
            )
            StorageManager.shared.addQuizResult(result)
            pastResults = StorageManager.shared.quizResults
        }
    }
    
    private func restartQuiz() {
        currentIndex = 0
        score = 0
        selectedOptionIndex = nil
        isAnswerSubmitted = false
        isQuizFinished = false
    }
    
    private func loadQuestions() {
        if let url = Bundle.module.url(forResource: "QuizData", withExtension: "json") ??
                     Bundle.main.url(forResource: "QuizData", withExtension: "json") {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([QuizQuestionModel].self, from: data) {
                self.questions = decoded
                return
            }
        }
        
        let currentDir = FileManager.default.currentDirectoryPath
        let fallbackUrl = URL(fileURLWithPath: "\(currentDir)/Resources/QuizData.json")
        if let data = try? Data(contentsOf: fallbackUrl),
           let decoded = try? JSONDecoder().decode([QuizQuestionModel].self, from: data) {
            self.questions = decoded
        }
    }
}

// MARK: - Option Button

private struct OptionButton: View {
    let label: String
    let text: String
    let isSelected: Bool
    let isSubmitted: Bool
    let isCorrect: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.musicianGold)
                    .frame(width: 20)
                
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(Color.musicianIvory)
                
                Spacer()
                
                if isSubmitted {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.subdominantEmerald)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.steinwayCrimson)
                    }
                }
            }
            .padding(12)
            .background(
                isSubmitted
                    ? (isCorrect ? Color.subdominantEmerald.opacity(0.15) : (isSelected ? Color.steinwayCrimson.opacity(0.15) : Color.musicianSurface))
                    : (isSelected ? Color.musicianGold.opacity(0.15) : Color.musicianSurface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSubmitted
                            ? (isCorrect ? Color.subdominantEmerald : (isSelected ? Color.steinwayCrimson : Color.clear))
                            : (isSelected ? Color.musicianGold : Color.gray.opacity(0.2)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

