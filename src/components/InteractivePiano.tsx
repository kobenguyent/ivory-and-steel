import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { audioEngine } from '../utils/audio';
import { Music, Sparkles, Volume2, Play, Layers } from 'lucide-react';

export interface KeyDef {
  note: string;
  isBlack: boolean;
  label: string;
  flatLabel?: string;
  keyTrigger?: string;
  offsetPercent?: number; // for black key absolute positioning across 15 white keys
}

/**
 * 15 White keys (C4 to C6) + 10 Black keys
 * White keys are exactly (100% / 15) = 6.6667% each.
 * Black keys are 4.2% wide, mathematically centered across white key boundaries
 * with subtle acoustic grand piano left/right offsets.
 */
export const PIANO_KEYS: KeyDef[] = [
  // Octave 4
  { note: 'C4', isBlack: false, label: 'C4', keyTrigger: 'a' },
  { note: 'C#4', isBlack: true, label: 'C#4', flatLabel: 'Db4', keyTrigger: 'w', offsetPercent: 4.35 },
  { note: 'D4', isBlack: false, label: 'D4', keyTrigger: 's' },
  { note: 'D#4', isBlack: true, label: 'D#4', flatLabel: 'Eb4', keyTrigger: 'e', offsetPercent: 11.45 },
  { note: 'E4', isBlack: false, label: 'E4', keyTrigger: 'd' },
  { note: 'F4', isBlack: false, label: 'F4', keyTrigger: 'f' },
  { note: 'F#4', isBlack: true, label: 'F#4', flatLabel: 'Gb4', keyTrigger: 't', offsetPercent: 24.20 },
  { note: 'G4', isBlack: false, label: 'G4', keyTrigger: 'g' },
  { note: 'G#4', isBlack: true, label: 'G#4', flatLabel: 'Ab4', keyTrigger: 'y', offsetPercent: 31.25 },
  { note: 'A4', isBlack: false, label: 'A4', keyTrigger: 'h' },
  { note: 'A#4', isBlack: true, label: 'A#4', flatLabel: 'Bb4', keyTrigger: 'u', offsetPercent: 38.25 },
  { note: 'B4', isBlack: false, label: 'B4', keyTrigger: 'j' },

  // Octave 5 (shifted by exactly 7 * 6.6667% = 46.6667%)
  { note: 'C5', isBlack: false, label: 'C5', keyTrigger: 'k' },
  { note: 'C#5', isBlack: true, label: 'C#5', flatLabel: 'Db5', keyTrigger: 'o', offsetPercent: 51.02 },
  { note: 'D5', isBlack: false, label: 'D5', keyTrigger: 'l' },
  { note: 'D#5', isBlack: true, label: 'D#5', flatLabel: 'Eb5', keyTrigger: 'p', offsetPercent: 58.12 },
  { note: 'E5', isBlack: false, label: 'E5', keyTrigger: ';' },
  { note: 'F5', isBlack: false, label: 'F5', keyTrigger: "'" },
  { note: 'F#5', isBlack: true, label: 'F#5', flatLabel: 'Gb5', keyTrigger: ']', offsetPercent: 70.87 },
  { note: 'G5', isBlack: false, label: 'G5' },
  { note: 'G#5', isBlack: true, label: 'G#5', flatLabel: 'Ab5', offsetPercent: 77.92 },
  { note: 'A5', isBlack: false, label: 'A5' },
  { note: 'A#5', isBlack: true, label: 'A#5', flatLabel: 'Bb5', offsetPercent: 84.92 },
  { note: 'B5', isBlack: false, label: 'B5' },

  // Resolution
  { note: 'C6', isBlack: false, label: 'C6' },
];

const PITCH_CLASS_MAP: Record<string, number> = {
  'C': 0, 'B#': 0,
  'C#': 1, 'DB': 1,
  'D': 2,
  'D#': 3, 'EB': 3,
  'E': 4, 'FB': 4,
  'F': 5, 'E#': 5,
  'F#': 6, 'GB': 6,
  'G': 7,
  'G#': 8, 'AB': 8,
  'A': 9,
  'A#': 10, 'BB': 10,
  'B': 11, 'CB': 11,
};

function parsePitch(noteStr: string): { pitch: string; octave: number; pitchClass: number } {
  const match = noteStr.trim().match(/^([A-Ga-g][b#]?)(-?\d+)$/);
  if (!match) {
    const clean = noteStr.trim().toUpperCase();
    return { pitch: clean, octave: 4, pitchClass: PITCH_CLASS_MAP[clean] ?? 0 };
  }
  const pitch = match[1].toUpperCase();
  const octave = parseInt(match[2], 10);
  return {
    pitch,
    octave,
    pitchClass: PITCH_CLASS_MAP[pitch] ?? 0,
  };
}

export interface InteractivePianoProps {
  highlightedNotes?: string[];
  rootNote?: string;
  intervals?: string[];
  preferFlat?: boolean;
  title?: string;
  subtitle?: string;
  externalActiveNotes?: Set<string>;
  onPlayNote?: (note: string) => void;
}

export const InteractivePiano: React.FC<InteractivePianoProps> = ({
  highlightedNotes = [],
  rootNote,
  intervals = [],
  preferFlat = false,
  title = 'Interactive Grand Piano',
  subtitle = 'Play using mouse clicks or computer keyboard (A-K keys)',
  externalActiveNotes,
  onPlayNote,
}) => {
  const [internalActiveNotes, setInternalActiveNotes] = useState<Set<string>>(new Set());
  const [showLabels, setShowLabels] = useState(true);
  const [showKeyShortcuts, setShowKeyShortcuts] = useState(true);
  const [showDegrees, setShowDegrees] = useState(true);
  const [isArpeggiating, setIsArpeggiating] = useState(false);

  // Union of internal clicks and external playback triggers
  const activeNotes = useMemo(() => {
    if (!externalActiveNotes || externalActiveNotes.size === 0) {
      return internalActiveNotes;
    }
    const combined = new Set(internalActiveNotes);
    externalActiveNotes.forEach((n) => combined.add(n));
    return combined;
  }, [internalActiveNotes, externalActiveNotes]);

  // Derive root pitch class from rootNote prop, or from title/subtitle, or first highlighted note
  const resolvedRootPitchClass = useMemo(() => {
    if (rootNote) {
      return parsePitch(rootNote).pitchClass;
    }
    // Attempt extraction from title e.g. "Piano Voicing: E I (E Major 7th)" -> "E"
    const titleMatch = title.match(/Voicing:\s*([A-G][b#]?)/i);
    if (titleMatch) {
      return parsePitch(titleMatch[1]).pitchClass;
    }
    if (highlightedNotes.length > 0) {
      return parsePitch(highlightedNotes[0]).pitchClass;
    }
    return null;
  }, [rootNote, title, highlightedNotes]);

  // Audio Playback Handler
  const playNote = useCallback(
    (note: string) => {
      audioEngine.playPianoNote(note, 1.8, 0.85);
      onPlayNote?.(note);

      setInternalActiveNotes((prev) => {
        const next = new Set(prev);
        next.add(note);
        return next;
      });

      setTimeout(() => {
        setInternalActiveNotes((prev) => {
          const next = new Set(prev);
          next.delete(note);
          return next;
        });
      }, 260);
    },
    [onPlayNote]
  );

  // Arpeggiate highlighted notes in musical sequence
  const handleArpeggiate = useCallback(() => {
    if (highlightedNotes.length === 0 || isArpeggiating) return;
    setIsArpeggiating(true);

    // Sort ascending by frequency/pitch
    const sortedNotes = [...highlightedNotes].sort((a, b) => {
      const pA = parsePitch(a);
      const pB = parsePitch(b);
      return pA.octave * 12 + pA.pitchClass - (pB.octave * 12 + pB.pitchClass);
    });

    sortedNotes.forEach((note, idx) => {
      setTimeout(() => {
        playNote(note);
        if (idx === sortedNotes.length - 1) {
          setTimeout(() => setIsArpeggiating(false), 300);
        }
      }, idx * 150);
    });
  }, [highlightedNotes, isArpeggiating, playNote]);

  // Play full harmonic chord block
  const handlePlayChordBlock = useCallback(() => {
    if (highlightedNotes.length === 0) return;
    audioEngine.playChord(highlightedNotes, 'piano', 0.04);

    setInternalActiveNotes(new Set(highlightedNotes));
    setTimeout(() => {
      setInternalActiveNotes(new Set());
    }, 450);
  }, [highlightedNotes]);

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

  // Check if a key is highlighted (handling enharmonic equivalents e.g. D#4 vs Eb4)
  const isKeyHighlighted = useCallback(
    (keyDef: KeyDef): boolean => {
      if (highlightedNotes.includes(keyDef.note)) return true;
      if (keyDef.flatLabel && highlightedNotes.includes(keyDef.flatLabel)) return true;

      const keyPitch = parsePitch(keyDef.note);
      return highlightedNotes.some((hn) => {
        const hPitch = parsePitch(hn);
        return hPitch.pitchClass === keyPitch.pitchClass && hPitch.octave === keyPitch.octave;
      });
    },
    [highlightedNotes]
  );

  // Check if a key is the harmonic Root
  const isKeyRoot = useCallback(
    (keyDef: KeyDef): boolean => {
      if (resolvedRootPitchClass === null) return false;
      const keyPitch = parsePitch(keyDef.note);
      return keyPitch.pitchClass === resolvedRootPitchClass;
    },
    [resolvedRootPitchClass]
  );

  // Compute harmonic interval label (Root, 3rd, 5th, 7th or 1, 2, 3...)
  const getIntervalLabel = useCallback(
    (keyDef: KeyDef): string => {
      if (resolvedRootPitchClass === null) return '';
      const keyPitch = parsePitch(keyDef.note);
      const semitones = (keyPitch.pitchClass - resolvedRootPitchClass + 12) % 12;

      // Check if intervals array aligns with highlightedNotes
      const matchIdx = highlightedNotes.findIndex((hn) => {
        const hPitch = parsePitch(hn);
        return hPitch.pitchClass === keyPitch.pitchClass && hPitch.octave === keyPitch.octave;
      });

      if (matchIdx !== -1 && intervals[matchIdx]) {
        const raw = intervals[matchIdx];
        if (raw.toLowerCase().includes('root') || raw === '1') return 'ROOT';
        return raw;
      }

      // Default diatonic/chromatic interval mapping
      const intervalMap: Record<number, string> = {
        0: 'ROOT',
        1: 'b2',
        2: '2nd',
        3: 'm3',
        4: '3rd',
        5: '4th',
        6: 'b5',
        7: '5th',
        8: 'b6',
        9: '6th',
        10: 'm7',
        11: '7th',
      };
      return intervalMap[semitones] || '';
    },
    [resolvedRootPitchClass, highlightedNotes, intervals]
  );

  const whiteKeys = PIANO_KEYS.filter((k) => !k.isBlack);
  const blackKeys = PIANO_KEYS.filter((k) => k.isBlack);

  return (
    <div className="bg-[#0f1117] border border-amber-900/40 rounded-2xl p-4 sm:p-6 shadow-2xl backdrop-blur-md relative overflow-hidden transition-all duration-300">
      {/* Background Concert Hall Ambient Glow */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500/5 rounded-full blur-3xl pointer-events-none -mr-32 -mt-32" />

      {/* Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5 relative z-10">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-amber-500/10 border border-amber-500/30 flex items-center justify-center shadow-inner">
              <Music className="w-4 h-4 text-amber-400" />
            </div>
            <div>
              <h3 className="text-xl font-serif font-bold text-slate-100 tracking-wide flex items-center gap-2">
                <span>{title}</span>
                {highlightedNotes.length > 0 && (
                  <span className="text-[10px] font-mono font-semibold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30">
                    {highlightedNotes.length} Notes Active
                  </span>
                )}
              </h3>
            </div>
          </div>
          <p className="text-xs sm:text-sm text-slate-400 mt-1 pl-10 font-sans">{subtitle}</p>
        </div>

        {/* Action & Toggle Controls */}
        <div className="flex flex-wrap items-center gap-2 sm:gap-2.5 self-end sm:self-auto">
          {/* Audio Action Buttons */}
          {highlightedNotes.length > 0 && (
            <>
              <button
                type="button"
                onClick={handleArpeggiate}
                disabled={isArpeggiating}
                title="Arpeggiate notes in sequence"
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 border transition-all ${
                  isArpeggiating
                    ? 'bg-amber-500 text-slate-950 border-amber-400 animate-pulse shadow-md shadow-amber-500/30'
                    : 'bg-amber-500/15 text-amber-300 border-amber-500/40 hover:bg-amber-500/25 active:scale-95'
                }`}
              >
                <Play className="w-3.5 h-3.5 fill-current" />
                <span>Arpeggio</span>
              </button>

              <button
                type="button"
                onClick={handlePlayChordBlock}
                title="Play harmonic chord block"
                className="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 bg-slate-800/80 text-slate-300 border border-slate-700/80 hover:bg-slate-800 hover:text-amber-300 transition-all active:scale-95"
              >
                <Layers className="w-3.5 h-3.5 text-amber-400" />
                <span>Strum</span>
              </button>
            </>
          )}

          {/* Toggle Buttons */}
          <div className="flex items-center gap-1.5 p-1 rounded-lg bg-slate-950/60 border border-slate-800">
            <button
              type="button"
              onClick={() => setShowLabels(!showLabels)}
              className={`px-2.5 py-1 rounded text-xs font-medium transition-all ${
                showLabels
                  ? 'bg-amber-500/20 text-amber-300 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {showLabels ? 'Notes: ON' : 'Notes: OFF'}
            </button>

            <button
              type="button"
              onClick={() => setShowDegrees(!showDegrees)}
              className={`px-2.5 py-1 rounded text-xs font-medium transition-all ${
                showDegrees
                  ? 'bg-amber-500/20 text-amber-300 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {showDegrees ? 'Roles: ON' : 'Roles: OFF'}
            </button>

            <button
              type="button"
              onClick={() => setShowKeyShortcuts(!showKeyShortcuts)}
              className={`px-2.5 py-1 rounded text-xs font-medium transition-all ${
                showKeyShortcuts
                  ? 'bg-amber-500/20 text-amber-300 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {showKeyShortcuts ? 'Keys: ON' : 'Keys: OFF'}
            </button>
          </div>
        </div>
      </div>

      {/* Grand Piano Keyboard Console */}
      <div className="relative overflow-x-auto pb-4 select-none">
        <div className="min-w-[700px] relative bg-[#07080b] rounded-b-xl shadow-2xl border border-slate-800/80 pt-0 overflow-hidden">
          {/* Steinway / Concert Grand Crimson Felt Rail & Brass Inlay */}
          <div className="h-3.5 w-full bg-gradient-to-r from-red-950 via-[#8b1e2d] to-red-950 border-b border-[#a32235]/60 relative flex items-center justify-between px-3 shadow-md z-30">
            <div className="h-[1px] w-full bg-gradient-to-r from-transparent via-amber-300/40 to-transparent absolute bottom-0 left-0" />
            <span className="text-[8px] font-serif tracking-[0.25em] text-amber-200/50 uppercase font-bold">
              Concert Grand · 12-TET Physical Model
            </span>
            <span className="text-[8px] font-mono text-amber-200/40 tracking-wider">C4 — C6</span>
          </div>

          {/* Keybed Container */}
          <div className="relative h-56 sm:h-64 px-1 pb-1">
            {/* White Keys Row (Natural Ivory) */}
            <div className="flex w-full h-full">
              {whiteKeys.map((key) => {
                const isActive = activeNotes.has(key.note);
                const isHighlighted = isKeyHighlighted(key);
                const isRoot = isHighlighted && isKeyRoot(key);
                const intervalLabel = isHighlighted ? getIntervalLabel(key) : '';

                return (
                  <button
                    key={key.note}
                    data-testid={`piano-key-${key.note}`}
                    type="button"
                    onClick={() => playNote(key.note)}
                    aria-label={`Piano key ${key.note}${isHighlighted ? `, active ${intervalLabel}` : ''}`}
                    className={`flex-1 h-full rounded-b-md transition-all duration-100 ease-out relative flex flex-col justify-between items-center pb-3 pt-3 border-r border-slate-300/80 last:border-r-0 ${
                      isActive
                        ? 'translate-y-1.5 bg-gradient-to-b from-amber-300 via-amber-200 to-amber-300 shadow-inner ring-2 ring-amber-400 z-10'
                        : isHighlighted
                        ? isRoot
                          ? 'bg-gradient-to-b from-[#fffbeb] via-[#fef3c7] to-[#fde68a] ring-2 ring-amber-400 z-10 shadow-[0_0_24px_rgba(245,158,11,0.5),inset_0_-4px_8px_rgba(217,119,6,0.3)]'
                          : 'bg-gradient-to-b from-[#fffdfa] via-[#fef9ee] to-[#fef3c7] ring-2 ring-amber-400/80 z-10 shadow-[0_0_16px_rgba(245,158,11,0.3)]'
                        : 'bg-gradient-to-b from-[#ffffff] via-[#faf8f4] to-[#ede7dc] hover:from-[#ffffff] hover:to-[#f5f0e6] shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_4px_6px_rgba(0,0,0,0.14),inset_0_-3px_0_rgba(0,0,0,0.08)]'
                    }`}
                  >
                    {/* Active Key Acoustic Shockwave Glow */}
                    {isActive && (
                      <span className="absolute inset-x-0 bottom-0 top-0 bg-gradient-to-t from-amber-400/50 via-amber-300/20 to-transparent pointer-events-none rounded-b-md animate-pulse" />
                    )}

                    {/* Top Harmonic Role Badge (Root / Interval) */}
                    <div className="w-full flex justify-center px-1">
                      {isHighlighted && showDegrees && (
                        <span
                          className={`text-[9px] font-mono font-black uppercase tracking-wider px-1.5 py-0.5 rounded shadow-sm border ${
                            isRoot
                              ? 'bg-amber-500 text-slate-950 border-amber-300 shadow-amber-500/40 animate-pulse'
                              : 'bg-amber-400/25 text-amber-900 border-amber-500/40'
                          }`}
                        >
                          {intervalLabel || 'TONE'}
                        </span>
                      )}
                    </div>

                    {/* Middle Keyboard Trigger Shortcut Badge */}
                    <div className="flex flex-col items-center">
                      {showKeyShortcuts && key.keyTrigger && (
                        <span className="text-[9px] uppercase font-mono text-slate-400 px-1.5 py-0.5 rounded bg-black/5 border border-black/5 shadow-inner">
                          {key.keyTrigger}
                        </span>
                      )}
                    </div>

                    {/* Bottom Pitch Label Badge */}
                    <div className="flex flex-col items-center">
                      {showLabels && (
                        <span
                          className={`text-xs tracking-tight rounded px-1.5 py-0.5 transition-colors ${
                            isHighlighted
                              ? isRoot
                                ? 'text-amber-950 font-black bg-amber-400/60 shadow-sm'
                                : 'text-amber-900 font-extrabold bg-amber-300/40'
                              : 'text-slate-700 font-semibold'
                          }`}
                        >
                          {key.note}
                        </span>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Black Keys Row (Satin Ebony with 3D Bevels) */}
            <div className="absolute top-0 left-1 right-1 h-[62%] pointer-events-none">
              {blackKeys.map((key) => {
                const isActive = activeNotes.has(key.note);
                const isHighlighted = isKeyHighlighted(key);
                const isRoot = isHighlighted && isKeyRoot(key);
                const intervalLabel = isHighlighted ? getIntervalLabel(key) : '';

                // Smart enharmonic display label
                const displayPitch = preferFlat && key.flatLabel ? key.flatLabel : key.label;
                const cleanDisplayPitch = displayPitch.replace(/[0-9]/g, '');

                return (
                  <button
                    key={key.note}
                    data-testid={`piano-key-${key.note}`}
                    type="button"
                    onClick={() => playNote(key.note)}
                    aria-label={`Piano key ${displayPitch}${isHighlighted ? `, active ${intervalLabel}` : ''}`}
                    style={{
                      left: `${key.offsetPercent}%`,
                      width: '4.2%',
                    }}
                    className={`pointer-events-auto absolute top-0 h-full rounded-b-md transition-all duration-100 ease-out flex flex-col justify-between items-center pb-2 pt-1.5 z-20 ${
                      isActive
                        ? 'translate-y-1.5 scale-y-[0.97] bg-gradient-to-b from-amber-400 via-amber-500 to-amber-600 shadow-lg ring-2 ring-amber-300'
                        : isHighlighted
                        ? isRoot
                          ? 'bg-gradient-to-b from-[#3d321d] via-[#261e10] to-[#120f08] ring-2 ring-amber-400 shadow-[0_0_24px_rgba(245,158,11,0.65),0_8px_16px_rgba(0,0,0,0.8)] border-x border-amber-500/50 border-b-2 border-b-amber-400'
                          : 'bg-gradient-to-b from-[#2e281b] via-[#1c170f] to-[#0d0b07] ring-2 ring-amber-400/80 shadow-[0_0_18px_rgba(245,158,11,0.45),0_8px_16px_rgba(0,0,0,0.7)] border-x border-amber-500/40 border-b-2 border-b-amber-400/80'
                        : 'bg-gradient-to-b from-[#2e323b] via-[#1a1c22] to-[#0c0d10] hover:from-[#383c48] hover:via-[#22252d] shadow-[0_6px_14px_rgba(0,0,0,0.7),inset_0_1px_1px_rgba(255,255,255,0.2),inset_0_-2px_0_rgba(255,255,255,0.05)] border-x border-black/95 border-b-[3px] border-b-black/90'
                    }`}
                  >
                    {/* Top Luminous Crown for Highlighted Black Keys */}
                    {isHighlighted ? (
                      <span
                        className={`absolute top-0 inset-x-0 h-3.5 rounded-t-sm shadow-sm ${
                          isRoot
                            ? 'bg-gradient-to-b from-amber-300 via-amber-400 to-amber-500 border-b border-amber-600'
                            : 'bg-gradient-to-b from-amber-400 via-amber-500 to-amber-600 border-b border-amber-700/80'
                        }`}
                      />
                    ) : (
                      <span className="absolute top-0 inset-x-0 h-1 bg-white/10 rounded-t-sm" />
                    )}

                    {/* Top Harmonic Role Badge on Black Key */}
                    <div className="w-full flex justify-center px-0.5 relative z-10 pt-2">
                      {isHighlighted && showDegrees && (
                        <span
                          className={`text-[8px] font-mono font-black uppercase tracking-tight px-1 py-0.5 rounded shadow ${
                            isRoot
                              ? 'bg-amber-400 text-slate-950 font-black'
                              : 'bg-amber-500/25 text-amber-200 border border-amber-400/50'
                          }`}
                        >
                          {intervalLabel || 'TONE'}
                        </span>
                      )}
                    </div>

                    {/* Middle Keyboard Trigger Shortcut Badge */}
                    <div className="flex flex-col items-center relative z-10">
                      {showKeyShortcuts && key.keyTrigger && (
                        <span className="text-[8px] uppercase font-mono text-amber-200/70 px-1 py-0.5 rounded bg-black/40 border border-white/5">
                          {key.keyTrigger}
                        </span>
                      )}
                    </div>

                    {/* Bottom Pitch Label Badge on Black Key */}
                    <div className="flex flex-col items-center relative z-10">
                      {showLabels && (
                        <span
                          className={`text-[10px] font-extrabold tracking-tight drop-shadow-[0_1px_2px_rgba(0,0,0,0.9)] ${
                            isHighlighted
                              ? isRoot
                                ? 'text-amber-300 font-black'
                                : 'text-amber-200'
                              : 'text-slate-200'
                          }`}
                        >
                          {cleanDisplayPitch}
                        </span>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Footer Info & Acoustic Specs */}
      <div className="mt-3 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-400 relative z-10 px-1">
        <div className="flex items-center gap-2">
          <Sparkles className="w-3.5 h-3.5 text-amber-400 shrink-0" />
          <span className="text-slate-300 font-medium">12-TET Physical Acoustic Resonance</span>
          <span className="text-slate-600 hidden sm:inline">·</span>
          <span className="text-slate-500 hidden sm:inline">25-Key Dual Octave Studio Range</span>
        </div>
        <div className="flex items-center gap-1.5 text-slate-400">
          <Volume2 className="w-3.5 h-3.5 text-amber-400/80" />
          <span className="font-mono text-[11px] text-slate-400">Polyphonic 4-Part Harmonic Modeling</span>
        </div>
      </div>
    </div>
  );
};
