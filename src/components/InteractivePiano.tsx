import React, { useState, useEffect, useCallback } from 'react';
import { audioEngine } from '../utils/audio';
import { Volume2, Music, Sparkles } from 'lucide-react';

interface KeyDef {
  note: string;
  isBlack: boolean;
  label: string;
  keyTrigger?: string;
  offsetPercent?: number; // for black key absolute positioning
}

// 2 Octaves from C4 to C6
const PIANO_KEYS: KeyDef[] = [
  { note: 'C4', isBlack: false, label: 'C4', keyTrigger: 'a' },
  { note: 'C#4', isBlack: true, label: 'C#4', keyTrigger: 'w', offsetPercent: 5.2 },
  { note: 'D4', isBlack: false, label: 'D4', keyTrigger: 's' },
  { note: 'D#4', isBlack: true, label: 'D#4', keyTrigger: 'e', offsetPercent: 12.3 },
  { note: 'E4', isBlack: false, label: 'E4', keyTrigger: 'd' },
  { note: 'F4', isBlack: false, label: 'F4', keyTrigger: 'f' },
  { note: 'F#4', isBlack: true, label: 'F#4', keyTrigger: 't', offsetPercent: 26.6 },
  { note: 'G4', isBlack: false, label: 'G4', keyTrigger: 'g' },
  { note: 'G#4', isBlack: true, label: 'G#4', keyTrigger: 'y', offsetPercent: 33.7 },
  { note: 'A4', isBlack: false, label: 'A4', keyTrigger: 'h' },
  { note: 'A#4', isBlack: true, label: 'A#4', keyTrigger: 'u', offsetPercent: 40.8 },
  { note: 'B4', isBlack: false, label: 'B4', keyTrigger: 'j' },

  { note: 'C5', isBlack: false, label: 'C5', keyTrigger: 'k' },
  { note: 'C#5', isBlack: true, label: 'C#5', keyTrigger: 'o', offsetPercent: 55.2 },
  { note: 'D5', isBlack: false, label: 'D5', keyTrigger: 'l' },
  { note: 'D#5', isBlack: true, label: 'D#5', keyTrigger: 'p', offsetPercent: 62.3 },
  { note: 'E5', isBlack: false, label: 'E5', keyTrigger: ';' },
  { note: 'F5', isBlack: false, label: 'F5', keyTrigger: "'" },
  { note: 'F#5', isBlack: true, label: 'F#5', keyTrigger: ']', offsetPercent: 76.6 },
  { note: 'G5', isBlack: false, label: 'G5' },
  { note: 'G#5', isBlack: true, label: 'G#5', offsetPercent: 83.7 },
  { note: 'A5', isBlack: false, label: 'A5' },
  { note: 'A#5', isBlack: true, label: 'A#5', offsetPercent: 90.8 },
  { note: 'B5', isBlack: false, label: 'B5' },
  { note: 'C6', isBlack: false, label: 'C6' },
];

interface InteractivePianoProps {
  highlightedNotes?: string[];
  title?: string;
  subtitle?: string;
}

export const InteractivePiano: React.FC<InteractivePianoProps> = ({
  highlightedNotes = [],
  title = 'Interactive Grand Piano',
  subtitle = 'Play using mouse clicks or computer keyboard (A-K keys)',
}) => {
  const [activeNotes, setActiveNotes] = useState<Set<string>>(new Set());
  const [showLabels, setShowLabels] = useState(true);
  const [showKeyShortcuts, setShowKeyShortcuts] = useState(true);

  const playNote = useCallback((note: string) => {
    audioEngine.playPianoNote(note, 1.8, 0.85);
    setActiveNotes((prev) => {
      const next = new Set(prev);
      next.add(note);
      return next;
    });

    setTimeout(() => {
      setActiveNotes((prev) => {
        const next = new Set(prev);
        next.delete(note);
        return next;
      });
    }, 300);
  }, []);

  // Keyboard events listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.repeat || e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return;
      }
      const key = e.key.toLowerCase();
      const match = PIANO_KEYS.find((k) => k.keyTrigger === key);
      if (match) {
        playNote(match.note);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [playNote]);

  const whiteKeys = PIANO_KEYS.filter((k) => !k.isBlack);
  const blackKeys = PIANO_KEYS.filter((k) => k.isBlack);

  return (
    <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-4 sm:p-6 shadow-2xl backdrop-blur-md">
      {/* Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Music className="w-5 h-5 text-amber-400" />
            <h3 className="text-xl font-serif font-bold text-slate-100">{title}</h3>
          </div>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">{subtitle}</p>
        </div>

        <div className="flex items-center gap-3 self-end sm:self-auto">
          <button
            onClick={() => setShowLabels(!showLabels)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
              showLabels
                ? 'bg-amber-500/20 text-amber-300 border-amber-500/50'
                : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-slate-200'
            }`}
          >
            {showLabels ? 'Notes: ON' : 'Notes: OFF'}
          </button>
          <button
            onClick={() => setShowKeyShortcuts(!showKeyShortcuts)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
              showKeyShortcuts
                ? 'bg-amber-500/20 text-amber-300 border-amber-500/50'
                : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-slate-200'
            }`}
          >
            {showKeyShortcuts ? 'Keys: ON' : 'Keys: OFF'}
          </button>
        </div>
      </div>

      {/* Piano Keyboard Container */}
      <div className="relative overflow-x-auto pb-4 select-none">
        <div className="min-w-[680px] h-52 sm:h-60 relative bg-black/80 rounded-b-xl p-2 shadow-inner border-t-8 border-amber-950">
          {/* White Keys */}
          <div className="flex w-full h-full">
            {whiteKeys.map((key) => {
              const isActive = activeNotes.has(key.note);
              const isHighlighted = highlightedNotes.includes(key.note);

              return (
                <button
                  key={key.note}
                  data-testid={`piano-key-${key.note}`}
                  onClick={() => playNote(key.note)}
                  className={`flex-1 h-full rounded-b-md transition-all duration-75 relative flex flex-col justify-end items-center pb-3 border-r border-slate-300/80 last:border-r-0 ${
                    isActive
                      ? 'bg-amber-300 shadow-inner scale-[0.98]'
                      : isHighlighted
                      ? 'bg-amber-100 ring-4 ring-amber-400/80 z-10'
                      : 'bg-gradient-to-b from-[#f7f5f0] via-[#faf8f5] to-[#ece7df] hover:bg-[#fffdfa]'
                  } shadow-md`}
                >
                  {isHighlighted && (
                    <span className="absolute top-2 w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
                  )}
                  {showKeyShortcuts && key.keyTrigger && (
                    <span className="text-[10px] uppercase font-mono text-slate-400 mb-1 px-1 rounded bg-black/5">
                      {key.keyTrigger}
                    </span>
                  )}
                  {showLabels && (
                    <span
                      className={`text-xs font-semibold ${
                        isHighlighted ? 'text-amber-900 font-bold' : 'text-slate-700'
                      }`}
                    >
                      {key.note}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Black Keys */}
          <div className="absolute top-2 left-2 right-2 h-32 sm:h-36 pointer-events-none">
            {blackKeys.map((key) => {
              const isActive = activeNotes.has(key.note);
              const isHighlighted = highlightedNotes.includes(key.note);

              return (
                <button
                  key={key.note}
                  data-testid={`piano-key-${key.note}`}
                  onClick={() => playNote(key.note)}
                  style={{
                    left: `${key.offsetPercent}%`,
                    width: '4.2%',
                  }}
                  className={`pointer-events-auto absolute top-0 h-full rounded-b-md transition-all duration-75 flex flex-col justify-end items-center pb-2 z-20 ${
                    isActive
                      ? 'bg-amber-500 shadow-lg scale-y-95'
                      : isHighlighted
                      ? 'bg-amber-600 ring-2 ring-amber-300'
                      : 'bg-gradient-to-b from-[#252830] via-[#15171c] to-[#0a0c10] hover:from-[#323640]'
                  } shadow-2xl border-x border-b border-black/80`}
                >
                  {isHighlighted && (
                    <span className="absolute top-2 w-1.5 h-1.5 rounded-full bg-amber-300 animate-ping" />
                  )}
                  {showKeyShortcuts && key.keyTrigger && (
                    <span className="text-[9px] uppercase font-mono text-amber-200/70 mb-0.5">
                      {key.keyTrigger}
                    </span>
                  )}
                  {showLabels && (
                    <span className="text-[10px] font-bold text-slate-200">
                      {key.note.replace(/[0-9]/g, '')}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Footer Info */}
      <div className="mt-3 flex items-center justify-between text-xs text-slate-400">
        <div className="flex items-center gap-1.5">
          <Sparkles className="w-4 h-4 text-amber-400" />
          <span>Natural piano physical modeling via Web Audio API</span>
        </div>
        <div className="flex items-center gap-1">
          <Volume2 className="w-3.5 h-3.5 text-slate-400" />
          <span>Polyphonic Audio Output</span>
        </div>
      </div>
    </div>
  );
};
