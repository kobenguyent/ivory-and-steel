import React, { useState, useEffect, useRef } from 'react';
import { PracticeRoutineBlock, DifficultyLevel, Instrument } from '../types';
import { audioEngine } from '../utils/audio';
import { Play, Pause, RotateCcw, CheckCircle2, Clock } from 'lucide-react';

const PRESET_ROUTINES: {
  name: string;
  instrument: Instrument;
  level: DifficultyLevel;
  totalDuration: number;
  blocks: PracticeRoutineBlock[];
}[] = [
  {
    name: '30-Minute Pianist Finger Independence & Voicing',
    instrument: 'piano',
    level: 'intermediate',
    totalDuration: 30,
    blocks: [
      {
        id: 'p-blk-1',
        title: 'Arm-Weight Drop & Finger Warmup',
        category: 'ergonomics',
        durationMinutes: 5,
        description: 'Drop arm weight into 5-finger patterns on C-G. Release all forearm and neck tension.',
        instrument: 'piano',
        targetLevel: 'intermediate',
        recommendedBpm: 60,
      },
      {
        id: 'p-blk-2',
        title: 'Thumb-Under Scale Transitions (2 Octaves)',
        category: 'technique',
        durationMinutes: 7,
        description: 'Focus on silent thumb glide underneath the palm on C, G, and D major scales.',
        instrument: 'piano',
        targetLevel: 'intermediate',
        recommendedBpm: 80,
      },
      {
        id: 'p-blk-3',
        title: 'ii-V-I Guide Tone Voice Leading',
        category: 'theory',
        durationMinutes: 8,
        description: 'Cycle Dm7 -> G7 -> Cmaj7 using 3rd and 7th shells. Keep common tones anchored.',
        instrument: 'piano',
        targetLevel: 'intermediate',
        recommendedBpm: 75,
      },
      {
        id: 'p-blk-4',
        title: 'Repertoire 2-Bar Isolation Loop',
        category: 'repertoire',
        durationMinutes: 10,
        description: 'Isolate the most difficult 2 measures of your current performance piece at 60% speed.',
        instrument: 'piano',
        targetLevel: 'intermediate',
      },
    ],
  },
  {
    name: '30-Minute Guitarist Fretboard & Speed Architecture',
    instrument: 'guitar',
    level: 'intermediate',
    totalDuration: 30,
    blocks: [
      {
        id: 'g-blk-1',
        title: 'Minimal Pressure Fretting Warmup',
        category: 'ergonomics',
        durationMinutes: 5,
        description: 'Fret notes on High E and B strings with minimal pressure right behind fret crowns.',
        instrument: 'guitar',
        targetLevel: 'intermediate',
        recommendedBpm: 70,
      },
      {
        id: 'g-blk-2',
        title: '45° Alternate Picking & String Skipping',
        category: 'technique',
        durationMinutes: 8,
        description: 'Maintain wrist relaxation while alternate picking across open and fretted strings.',
        instrument: 'guitar',
        targetLevel: 'intermediate',
        recommendedBpm: 90,
      },
      {
        id: 'g-blk-3',
        title: 'CAGED Shape Highway Navigation',
        category: 'theory',
        durationMinutes: 7,
        description: 'Walk through C, A, G, E, and D chord shapes for G Major and C Major across 12 frets.',
        instrument: 'guitar',
        targetLevel: 'intermediate',
      },
      {
        id: 'g-blk-4',
        title: 'Pitch-Targeted String Bending with Vibrato',
        category: 'tone',
        durationMinutes: 10,
        description: 'Verify 1-step and 1.5-step bends with a tuner or reference pitch. Add wide vocal vibrato.',
        instrument: 'guitar',
        targetLevel: 'intermediate',
        recommendedBpm: 60,
      },
    ],
  },
];

export const PracticeRoutine: React.FC = () => {
  const [selectedRoutineIndex, setSelectedRoutineIndex] = useState(0);
  const currentRoutine = PRESET_ROUTINES[selectedRoutineIndex];

  const [activeBlockIndex, setActiveBlockIndex] = useState(0);
  const [secondsRemaining, setSecondsRemaining] = useState(
    currentRoutine.blocks[0].durationMinutes * 60
  );
  const [isRunning, setIsRunning] = useState(false);
  const [completedBlocks, setCompletedBlocks] = useState<Set<string>>(new Set());

  const timerRef = useRef<number | null>(null);

  // Update timer when routine or block changes
  const selectBlock = (index: number) => {
    setActiveBlockIndex(index);
    setSecondsRemaining(currentRoutine.blocks[index].durationMinutes * 60);
    setIsRunning(false);
  };

  useEffect(() => {
    selectBlock(0);
    setCompletedBlocks(new Set());
  }, [selectedRoutineIndex]);

  useEffect(() => {
    if (isRunning) {
      timerRef.current = window.setInterval(() => {
        setSecondsRemaining((prev) => {
          if (prev <= 1) {
            // Block completed! Play completion chime
            audioEngine.playPianoNote('C5', 0.4, 0.8);
            setTimeout(() => audioEngine.playPianoNote('G5', 0.8, 0.9), 200);

            // Mark completed
            const currentBlock = currentRoutine.blocks[activeBlockIndex];
            setCompletedBlocks((curr) => new Set(curr).add(currentBlock.id));

            // Auto-advance if not last
            if (activeBlockIndex < currentRoutine.blocks.length - 1) {
              const nextIdx = activeBlockIndex + 1;
              setActiveBlockIndex(nextIdx);
              return currentRoutine.blocks[nextIdx].durationMinutes * 60;
            } else {
              setIsRunning(false);
              return 0;
            }
          }
          return prev - 1;
        });
      }, 1000);
    } else {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    }

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isRunning, activeBlockIndex, currentRoutine]);

  const toggleTimer = () => {
    setIsRunning(!isRunning);
  };

  const resetTimer = () => {
    setIsRunning(false);
    setSecondsRemaining(currentRoutine.blocks[activeBlockIndex].durationMinutes * 60);
  };

  const toggleBlockCompleted = (id: string) => {
    setCompletedBlocks((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const formatTime = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const activeBlock = currentRoutine.blocks[activeBlockIndex];

  return (
    <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-6 shadow-xl backdrop-blur-md">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5 text-amber-400" />
            <h2 className="text-2xl font-serif font-bold text-slate-100">
              Deliberate Practice Routine
            </h2>
          </div>
          <p className="text-sm text-slate-400 mt-1">
            Transform aimless playing into targeted neuromuscular progress with timed blocks.
          </p>
        </div>

        {/* Routine Presets Switcher */}
        <div className="flex items-center gap-2">
          {PRESET_ROUTINES.map((routine, idx) => (
            <button
              key={routine.name}
              data-testid={`routine-preset-${idx}`}
              onClick={() => setSelectedRoutineIndex(idx)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition-all ${
                selectedRoutineIndex === idx
                  ? 'bg-amber-500 text-slate-950 border-amber-400 shadow'
                  : 'bg-slate-800 text-slate-300 border-slate-700 hover:text-white'
              }`}
            >
              {routine.instrument.toUpperCase()} ({routine.totalDuration}m)
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Practice Timer Display */}
        <div className="lg:col-span-1 bg-slate-950/80 rounded-xl p-6 border border-slate-800 flex flex-col justify-between items-center text-center">
          <div className="w-full">
            <span className="text-xs uppercase font-bold tracking-widest text-slate-400">
              Active Session Block
            </span>
            <h3 className="text-lg font-serif font-bold text-amber-300 mt-1 truncate">
              {activeBlock.title}
            </h3>
            <span className="text-xs text-slate-400 block mt-0.5 capitalize">
              {activeBlock.category} • Step {activeBlockIndex + 1} of {currentRoutine.blocks.length}
            </span>
          </div>

          {/* Big Digital Countdown */}
          <div className="my-6">
            <div
              data-testid="timer-display"
              className="text-6xl font-mono font-black tracking-tight text-white drop-shadow-md"
            >
              {formatTime(secondsRemaining)}
            </div>
            {activeBlock.recommendedBpm && (
              <div className="mt-2 text-xs font-mono text-amber-400 bg-amber-500/10 px-3 py-1 rounded-full border border-amber-500/30 inline-block">
                Set Metronome: {activeBlock.recommendedBpm} BPM
              </div>
            )}
          </div>

          {/* Timer Controls */}
          <div className="flex gap-3 w-full">
            <button
              data-testid="toggle-timer-btn"
              onClick={toggleTimer}
              className={`flex-1 py-3 px-4 rounded-xl font-bold flex items-center justify-center gap-2 shadow-lg transition-all ${
                isRunning
                  ? 'bg-amber-600 hover:bg-amber-500 text-slate-950'
                  : 'bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950'
              }`}
            >
              {isRunning ? <Pause className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current" />}
              {isRunning ? 'Pause Drill' : 'Start Drill'}
            </button>

            <button
              data-testid="reset-timer-btn"
              onClick={resetTimer}
              className="p-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl border border-slate-700"
              title="Reset timer"
            >
              <RotateCcw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Practice Blocks Breakdown */}
        <div className="lg:col-span-2 space-y-3">
          <div className="flex items-center justify-between text-xs text-slate-400 px-1 mb-1">
            <span className="font-bold uppercase tracking-wider">Practice Blocks Checklist</span>
            <span>
              {completedBlocks.size} / {currentRoutine.blocks.length} Completed
            </span>
          </div>

          {currentRoutine.blocks.map((block, idx) => {
            const isCurrent = activeBlockIndex === idx;
            const isDone = completedBlocks.has(block.id);

            return (
              <div
                key={block.id}
                onClick={() => selectBlock(idx)}
                className={`p-4 rounded-xl border transition-all cursor-pointer flex items-start gap-4 ${
                  isCurrent
                    ? 'bg-slate-800/90 border-amber-500/80 shadow-md ring-1 ring-amber-500/40'
                    : 'bg-slate-950/60 border-slate-800 hover:border-slate-700'
                }`}
              >
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleBlockCompleted(block.id);
                  }}
                  className={`w-6 h-6 rounded-full flex items-center justify-center transition-colors shrink-0 mt-0.5 ${
                    isDone
                      ? 'bg-emerald-500 text-slate-950'
                      : 'border-2 border-slate-600 hover:border-emerald-400 text-transparent'
                  }`}
                >
                  <CheckCircle2 className="w-4 h-4 fill-current" />
                </button>

                <div className="flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <h4
                      className={`text-sm font-bold ${
                        isCurrent ? 'text-amber-300' : 'text-slate-200'
                      } ${isDone ? 'line-through opacity-70' : ''}`}
                    >
                      {block.title}
                    </h4>
                    <span className="text-xs font-mono px-2 py-0.5 rounded bg-slate-800 text-slate-400 shrink-0">
                      {block.durationMinutes} min
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                    {block.description}
                  </p>
                </div>
              </div>
            );
          })}

          <div className="mt-4 p-3 rounded-lg bg-amber-950/20 border border-amber-600/30 text-xs text-amber-200/90">
            <span>
              <strong>Focus cue:</strong> If you lose focus during a block, pause the timer and take three slow breaths before resuming.
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
