import React, { useState } from 'react';
import { QUIZ_QUESTIONS } from '../data/quizData';
import { QuizQuestion, DifficultyLevel } from '../types';
import { HelpCircle, CheckCircle2, XCircle, Award, RotateCcw, ArrowRight } from 'lucide-react';

export const MusicianQuiz: React.FC = () => {
  const [instrument, setInstrument] = useState<'piano' | 'guitar'>('piano');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [isAnswered, setIsAnswered] = useState(false);
  const [score, setScore] = useState(0);
  const [isComplete, setIsComplete] = useState(false);

  const questions = QUIZ_QUESTIONS.filter((q) => q.instrument === instrument);
  const currentQuestion: QuizQuestion = questions[currentIndex] || questions[0];

  const handleSelectOption = (idx: number) => {
    if (isAnswered) return;
    setSelectedOption(idx);
    setIsAnswered(true);

    if (idx === currentQuestion.correctIndex) {
      setScore((prev) => prev + 1);
    }
  };

  const handleNext = () => {
    if (currentIndex < questions.length - 1) {
      setCurrentIndex((prev) => prev + 1);
      setSelectedOption(null);
      setIsAnswered(false);
    } else {
      setIsComplete(true);
    }
  };

  const handleReset = (newInstrument?: 'piano' | 'guitar') => {
    if (newInstrument) setInstrument(newInstrument);
    setCurrentIndex(0);
    setSelectedOption(null);
    setIsAnswered(false);
    setScore(0);
    setIsComplete(false);
  };

  const getLevelRecommendation = (finalScore: number, total: number): { level: DifficultyLevel; description: string } => {
    const ratio = finalScore / total;
    if (ratio >= 0.85) {
      return {
        level: 'mastery',
        description: 'Virtuoso Tier: You possess exceptional theoretical command and nuanced mechanical instincts! Focus on micro-pedaling, Holdsworth legato, and complex reharmonization.',
      };
    } else if (ratio >= 0.65) {
      return {
        level: 'advanced',
        description: 'Advanced Musician: Strong harmonic and technical foundation. Hone rootless jazz voicings, sweep picking, and modal target tones.',
      };
    } else if (ratio >= 0.4) {
      return {
        level: 'intermediate',
        description: 'Solid Intermediate: Great momentum! Level up with the CAGED fretboard roadmap, ii-V-I guide tones, and polyrhythmic independence.',
      };
    } else {
      return {
        level: 'beginner',
        description: 'Promising Apprentice: Focus on foundational ergonomics, curved dome posture, anchor chord changes, and landmark reading.',
      };
    }
  };

  return (
    <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-6 shadow-xl backdrop-blur-md">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <HelpCircle className="w-5 h-5 text-amber-400" />
            <h2 className="text-2xl font-serif font-bold text-slate-100">
              Musician Level Self-Assessment
            </h2>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Evaluate your knowledge of technique, ergonomics, and harmony across all 4 levels.
          </p>
        </div>

        {/* Instrument Switcher */}
        <div className="bg-slate-950 p-1 rounded-xl border border-slate-800 flex self-start sm:self-auto">
          <button
            data-testid="quiz-inst-piano"
            onClick={() => handleReset('piano')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
              instrument === 'piano'
                ? 'bg-amber-500 text-slate-950 shadow'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            Piano Quiz
          </button>
          <button
            data-testid="quiz-inst-guitar"
            onClick={() => handleReset('guitar')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
              instrument === 'guitar'
                ? 'bg-amber-500 text-slate-950 shadow'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            Guitar Quiz
          </button>
        </div>
      </div>

      {!isComplete ? (
        <div className="max-w-2xl mx-auto space-y-6">
          {/* Progress Bar */}
          <div>
            <div className="flex justify-between text-xs text-slate-400 font-mono mb-2">
              <span>
                Question {currentIndex + 1} of {questions.length}
              </span>
              <span className="capitalize font-semibold text-amber-400">
                Tier: {currentQuestion.level}
              </span>
            </div>
            <div className="w-full h-2 bg-slate-950 rounded-full overflow-hidden border border-slate-800">
              <div
                className="h-full bg-gradient-to-r from-amber-500 to-amber-300 transition-all duration-300"
                style={{ width: `${((currentIndex + 1) / questions.length) * 100}%` }}
              />
            </div>
          </div>

          {/* Question Card */}
          <div className="bg-slate-950/80 p-6 rounded-xl border border-slate-800">
            <h3 data-testid="quiz-question-text" className="text-lg font-serif font-bold text-slate-100 leading-snug">
              {currentQuestion.question}
            </h3>

            {/* Options */}
            <div className="space-y-3 mt-6">
              {currentQuestion.options.map((option, idx) => {
                const isSelected = selectedOption === idx;
                const isCorrect = idx === currentQuestion.correctIndex;

                let optionStyle =
                  'bg-slate-900 border-slate-800 hover:border-slate-700 text-slate-200';
                if (isAnswered) {
                  if (isCorrect) {
                    optionStyle = 'bg-emerald-950/40 border-emerald-500 text-emerald-200';
                  } else if (isSelected && !isCorrect) {
                    optionStyle = 'bg-rose-950/40 border-rose-500 text-rose-200';
                  } else {
                    optionStyle = 'bg-slate-950/40 border-slate-900 text-slate-500';
                  }
                }

                return (
                  <button
                    key={idx}
                    data-testid={`quiz-option-${idx}`}
                    onClick={() => handleSelectOption(idx)}
                    disabled={isAnswered}
                    className={`w-full text-left p-4 rounded-xl border font-medium text-sm transition-all flex items-center justify-between gap-3 ${optionStyle}`}
                  >
                    <span>{option}</span>
                    {isAnswered && (
                      <span className="shrink-0">
                        {isCorrect ? (
                          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                        ) : isSelected ? (
                          <XCircle className="w-5 h-5 text-rose-400" />
                        ) : null}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Explanation reveal */}
            {isAnswered && (
              <div className="mt-6 p-4 rounded-xl bg-slate-900 border border-slate-700/80 animate-fadeIn">
                <span className="text-xs uppercase font-bold text-amber-400 block mb-1">
                  Musician Breakdown
                </span>
                <p className="text-xs text-slate-300 leading-relaxed">
                  {currentQuestion.explanation}
                </p>

                <div className="mt-4 flex justify-end">
                  <button
                    data-testid="quiz-next-btn"
                    onClick={handleNext}
                    className="px-5 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs uppercase tracking-wider flex items-center gap-1.5 shadow"
                  >
                    {currentIndex < questions.length - 1 ? 'Next Question' : 'View Results'}
                    <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      ) : (
        /* Results View */
        <div className="max-w-xl mx-auto bg-slate-950/90 rounded-2xl p-8 border border-amber-900/40 text-center space-y-6">
          <div className="w-16 h-16 rounded-full bg-amber-500/20 border border-amber-500/50 flex items-center justify-center mx-auto text-amber-400 shadow-lg shadow-amber-950/50">
            <Award className="w-8 h-8" />
          </div>

          <div>
            <span className="text-xs font-mono uppercase tracking-widest text-slate-400">
              Assessment Complete
            </span>
            <div data-testid="quiz-score-display" className="text-5xl font-mono font-black text-white mt-1">
              {score} / {questions.length}
            </div>
            <span className="text-xs text-amber-400 font-bold">
              ({Math.round((score / questions.length) * 100)}% Accuracy)
            </span>
          </div>

          {(() => {
            const recommendation = getLevelRecommendation(score, questions.length);
            return (
              <div className="bg-slate-900/90 p-5 rounded-xl border border-slate-800 text-left">
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-400" />
                  <h4 className="text-base font-bold text-slate-100 capitalize">
                    Recommended Study Tier: {recommendation.level}
                  </h4>
                </div>
                <p className="text-xs text-slate-300 leading-relaxed">
                  {recommendation.description}
                </p>
              </div>
            );
          })()}

          <button
            data-testid="quiz-retake-btn"
            onClick={() => handleReset()}
            className="px-6 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-100 font-bold text-xs uppercase tracking-wider border border-slate-700 inline-flex items-center gap-2 transition-all shadow"
          >
            <RotateCcw className="w-4 h-4" />
            Retake Assessment
          </button>
        </div>
      )}
    </div>
  );
};
