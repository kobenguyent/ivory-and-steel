import React, { useState, useMemo } from 'react';
import { audioEngine } from '../utils/audio';
import { Volume2, Eye } from 'lucide-react';

// Standard 6-string guitar tuning open MIDI notes:
// String 1 (High E): E4 (MIDI 64)
// String 2 (B): B3 (MIDI 59)
// String 3 (G): G3 (MIDI 55)
// String 4 (D): D3 (MIDI 50)
// String 5 (A): A2 (MIDI 45)
// String 6 (Low E): E2 (MIDI 40)
const STRING_BASE_MIDI = [64, 59, 55, 50, 45, 40];
const STRING_NAMES = ['e', 'B', 'G', 'D', 'A', 'E'];
const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

export function midiToNoteName(midi: number): string {
  const noteIndex = midi % 12;
  const octave = Math.floor(midi / 12) - 1;
  return `${NOTE_NAMES[noteIndex]}${octave}`;
}

export function midiToPitchClass(midi: number): string {
  return NOTE_NAMES[midi % 12];
}

interface FretHighlight {
  stringNum: number; // 1 to 6
  fret: number;
  label?: string;
  isRoot?: boolean;
}

interface InteractiveFretboardProps {
  highlights?: FretHighlight[];
  title?: string;
  subtitle?: string;
}

export const InteractiveFretboard: React.FC<InteractiveFretboardProps> = ({
  highlights = [],
  title = 'Interactive 6-String Fretboard',
  subtitle = 'Click any string and fret to hear the note. Frets 0 to 15 in Standard Tuning (EADGBE).',
}) => {
  const [activeFret, setActiveFret] = useState<{ stringNum: number; fret: number } | null>(null);
  const [displayMode, setDisplayMode] = useState<'notes' | 'none'>('notes');

  const fretMarkers = [3, 5, 7, 9, 12, 15];

  const handleFretClick = (stringNum: number, fret: number) => {
    const baseMidi = STRING_BASE_MIDI[stringNum - 1];
    const midi = baseMidi + fret;
    const noteName = midiToNoteName(midi);

    audioEngine.playGuitarNote(noteName, 2.0, 0.85);
    setActiveFret({ stringNum, fret });

    setTimeout(() => {
      setActiveFret((curr) => (curr?.stringNum === stringNum && curr?.fret === fret ? null : curr));
    }, 350);
  };

  // Convert preset or incoming highlights to a fast lookup map
  const highlightMap = useMemo(() => {
    const map = new Map<string, FretHighlight>();
    highlights.forEach((h) => {
      map.set(`${h.stringNum}-${h.fret}`, h);
    });
    return map;
  }, [highlights]);

  return (
    <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-4 sm:p-6 shadow-2xl backdrop-blur-md">
      {/* Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-amber-500 animate-pulse" />
            <h3 className="text-xl font-serif font-bold text-slate-100">{title}</h3>
          </div>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">{subtitle}</p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setDisplayMode(displayMode === 'notes' ? 'none' : 'notes')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium border flex items-center gap-1.5 transition-colors ${
              displayMode === 'notes'
                ? 'bg-amber-500/20 text-amber-300 border-amber-500/50'
                : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-slate-200'
            }`}
          >
            <Eye className="w-3.5 h-3.5" />
            {displayMode === 'notes' ? 'Note Names: ON' : 'Note Names: OFF'}
          </button>
        </div>
      </div>

      {/* Fretboard Graphic View */}
      <div className="relative overflow-x-auto pb-4 select-none">
        <div className="min-w-[850px] bg-gradient-to-r from-[#211510] via-[#2d1b13] to-[#1c110b] rounded-xl border border-amber-950 p-4 shadow-2xl relative">
          {/* Fret Numbers Header */}
          <div className="flex ml-12 mb-2 text-xs font-mono text-amber-300/70 border-b border-amber-900/30 pb-1">
            <div className="w-10 text-center font-bold text-amber-400">Nut (0)</div>
            {Array.from({ length: 15 }, (_, i) => i + 1).map((fret) => (
              <div key={fret} className="flex-1 text-center font-semibold">
                {fret}
              </div>
            ))}
          </div>

          {/* Strings and Frets Grid */}
          <div className="relative flex flex-col gap-4 py-2">
            {[1, 2, 3, 4, 5, 6].map((stringNum) => {
              const stringIdx = stringNum - 1;
              const stringName = STRING_NAMES[stringIdx];
              // Gauge thickness styling: String 1 is 1.5px, String 6 is 4px
              const stringGaugePx = 1.5 + stringIdx * 0.55;

              return (
                <div key={stringNum} className="flex items-center relative group">
                  {/* String Tuning Head Name */}
                  <div className="w-12 flex items-center justify-center font-mono font-bold text-sm text-amber-200/90 z-20">
                    <span className="w-7 h-7 rounded-full bg-slate-800/90 border border-amber-500/30 flex items-center justify-center shadow">
                      {stringName}
                    </span>
                  </div>

                  {/* Open Fret Button (Nut Fret 0) */}
                  <div className="w-10 flex justify-center z-10">
                    {(() => {
                      const highlight = highlightMap.get(`${stringNum}-0`);
                      const isActive = activeFret?.stringNum === stringNum && activeFret?.fret === 0;
                      const baseMidi = STRING_BASE_MIDI[stringIdx];
                      const pitch = midiToPitchClass(baseMidi);

                      return (
                        <button
                          data-testid={`fret-${stringNum}-0`}
                          onClick={() => handleFretClick(stringNum, 0)}
                          className={`w-7 h-7 rounded-full text-xs font-bold transition-transform flex items-center justify-center shadow-md ${
                            isActive
                              ? 'bg-amber-400 text-slate-950 scale-125 ring-2 ring-amber-200'
                              : highlight
                              ? highlight.isRoot
                                ? 'bg-amber-500 text-slate-950 font-extrabold ring-2 ring-amber-300'
                                : 'bg-emerald-500 text-white font-bold ring-2 ring-emerald-300'
                              : 'bg-slate-800/80 text-slate-300 hover:bg-amber-600/60 border border-slate-600'
                          }`}
                        >
                          {highlight?.label || (displayMode === 'notes' ? pitch : '0')}
                        </button>
                      );
                    })()}
                  </div>

                  {/* Frets 1 to 15 */}
                  <div className="flex-1 flex relative">
                    {/* Continuous Metallic String Horizontal Wire */}
                    <div
                      style={{ height: `${stringGaugePx}px` }}
                      className="absolute inset-y-1/2 left-0 right-0 -translate-y-1/2 bg-gradient-to-r from-amber-100 via-slate-300 to-amber-200/80 shadow pointer-events-none z-0 opacity-90"
                    />

                    {Array.from({ length: 15 }, (_, i) => i + 1).map((fret) => {
                      const highlight = highlightMap.get(`${stringNum}-${fret}`);
                      const isActive = activeFret?.stringNum === stringNum && activeFret?.fret === fret;
                      const midi = STRING_BASE_MIDI[stringIdx] + fret;
                      const pitch = midiToPitchClass(midi);

                      return (
                        <div
                          key={fret}
                          className="flex-1 h-9 flex items-center justify-center relative border-r-2 border-slate-400/50 first:border-l-4 first:border-l-amber-100/90"
                        >
                          <button
                            data-testid={`fret-${stringNum}-${fret}`}
                            onClick={() => handleFretClick(stringNum, fret)}
                            className={`z-10 w-6 h-6 rounded-full text-[11px] font-bold transition-transform flex items-center justify-center ${
                              isActive
                                ? 'bg-amber-300 text-slate-950 scale-125 ring-2 ring-white shadow-lg'
                                : highlight
                                ? highlight.isRoot
                                  ? 'bg-amber-500 text-slate-950 font-extrabold ring-2 ring-amber-200 scale-110 shadow-md'
                                  : 'bg-emerald-500 text-white font-bold ring-1 ring-emerald-200 scale-105 shadow'
                                : displayMode === 'notes'
                                ? 'bg-slate-950/70 text-slate-300 hover:bg-amber-600/80 hover:text-white border border-slate-700/80'
                                : 'opacity-0 hover:opacity-100 bg-amber-500/80 text-slate-950 font-bold'
                            }`}
                          >
                            {highlight?.label || pitch}
                          </button>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Fretboard Inlays (Fret Markers: 3, 5, 7, 9, 12 double dot, 15) */}
          <div className="flex ml-22 mt-2 pt-1 border-t border-amber-900/40">
            <div className="w-10" />
            {Array.from({ length: 15 }, (_, i) => i + 1).map((fret) => (
              <div key={fret} className="flex-1 flex justify-center items-center h-4">
                {fret === 12 ? (
                  <div className="flex gap-1">
                    <span className="w-2 h-2 rounded-full bg-amber-100/60 shadow-sm" />
                    <span className="w-2 h-2 rounded-full bg-amber-100/60 shadow-sm" />
                  </div>
                ) : fretMarkers.includes(fret) ? (
                  <span className="w-2 h-2 rounded-full bg-amber-100/60 shadow-sm" />
                ) : null}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Legend & Acoustic details */}
      <div className="mt-3 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-400">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded-full bg-amber-500" />
            <span>Root Note (1)</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded-full bg-emerald-500" />
            <span>Chord Tone / Scale Degree</span>
          </div>
        </div>
        <div className="flex items-center gap-1">
          <Volume2 className="w-3.5 h-3.5 text-amber-400" />
          <span>Plucked Acoustic String Resonance</span>
        </div>
      </div>
    </div>
  );
};
