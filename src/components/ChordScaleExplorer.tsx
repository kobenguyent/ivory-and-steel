import React, { useState } from 'react';
import { CHORDS_DATA, SCALES_DATA } from '../data/chordsAndScalesData';
import { InteractivePiano } from './InteractivePiano';
import { InteractiveFretboard } from './InteractiveFretboard';
import { audioEngine } from '../utils/audio';
import { Play, Compass } from 'lucide-react';

export const ChordScaleExplorer: React.FC = () => {
  const [instrument, setInstrument] = useState<'piano' | 'guitar'>('piano');
  const [viewType, setViewType] = useState<'chords' | 'scales'>('chords');
  const [selectedChordIndex, setSelectedChordIndex] = useState(0);
  const [selectedScaleIndex, setSelectedScaleIndex] = useState(0);

  const availableChords = CHORDS_DATA.filter((c) => c.instrument === instrument);
  const currentChord = availableChords[selectedChordIndex] || availableChords[0];
  const currentScale = SCALES_DATA[selectedScaleIndex] || SCALES_DATA[0];

  const handlePlayChord = () => {
    if (viewType === 'chords' && currentChord) {
      audioEngine.playChord(currentChord.notes, currentChord.instrument);
    } else if (viewType === 'scales' && currentScale) {
      audioEngine.playScale(currentScale.notes, instrument);
    }
  };

  // Convert guitar fret definitions to highlights
  const guitarHighlights = React.useMemo(() => {
    if (viewType === 'chords' && currentChord?.guitarFrets) {
      return currentChord.guitarFrets.map((f, i) => ({
        stringNum: f.stringNum,
        fret: f.fret,
        label: f.finger === 'open' ? 'O' : f.finger,
        isRoot: i === 0,
      }));
    } else if (viewType === 'scales' && currentScale?.guitarPattern) {
      const list: { stringNum: number; fret: number; label?: string; isRoot?: boolean }[] = [];
      currentScale.guitarPattern.forEach((pat) => {
        pat.frets.forEach((fret, fIdx) => {
          list.push({
            stringNum: pat.stringNum,
            fret,
            isRoot: fIdx === 0 && (pat.stringNum === 6 || pat.stringNum === 1),
          });
        });
      });
      return list;
    }
    return [];
  }, [viewType, currentChord, currentScale]);

  const pianoHighlightedNotes = React.useMemo(() => {
    if (viewType === 'chords' && currentChord?.pianoKeys) {
      return currentChord.pianoKeys;
    } else if (viewType === 'scales' && currentScale?.pianoKeys) {
      return currentScale.pianoKeys;
    }
    return [];
  }, [viewType, currentChord, currentScale]);

  return (
    <div className="flex flex-col gap-6">
      {/* Control Selector Header */}
      <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-6 shadow-xl backdrop-blur-md">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
          <div>
            <div className="flex items-center gap-2">
              <Compass className="w-5 h-5 text-amber-400" />
              <h2 className="text-2xl font-serif font-bold text-slate-100">
                Chord & Scale Theory Explorer
              </h2>
            </div>
            <p className="text-sm text-slate-400 mt-1">
              Visualize voicings, study intervals, and hear real-time synthesized acoustic playback.
            </p>
          </div>

          {/* Instrument and View Toggle */}
          <div className="flex flex-wrap items-center gap-2">
            <div className="bg-slate-950 p-1 rounded-xl border border-slate-800 flex">
              <button
                data-testid="toggle-piano"
                onClick={() => {
                  setInstrument('piano');
                  setSelectedChordIndex(0);
                }}
                className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  instrument === 'piano'
                    ? 'bg-amber-500 text-slate-950 shadow'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Piano
              </button>
              <button
                data-testid="toggle-guitar"
                onClick={() => {
                  setInstrument('guitar');
                  setSelectedChordIndex(0);
                }}
                className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  instrument === 'guitar'
                    ? 'bg-amber-500 text-slate-950 shadow'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Guitar
              </button>
            </div>

            <div className="bg-slate-950 p-1 rounded-xl border border-slate-800 flex">
              <button
                data-testid="toggle-chords"
                onClick={() => setViewType('chords')}
                className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  viewType === 'chords'
                    ? 'bg-emerald-500 text-white shadow'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Chords
              </button>
              <button
                data-testid="toggle-scales"
                onClick={() => setViewType('scales')}
                className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  viewType === 'scales'
                    ? 'bg-emerald-500 text-white shadow'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Scales
              </button>
            </div>
          </div>
        </div>

        {/* List of items to select */}
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin">
          {viewType === 'chords'
            ? availableChords.map((chord, idx) => (
                <button
                  key={chord.name}
                  onClick={() => setSelectedChordIndex(idx)}
                  className={`px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all border ${
                    selectedChordIndex === idx
                      ? 'bg-amber-500/20 text-amber-300 border-amber-500/80 shadow-md ring-1 ring-amber-400/40'
                      : 'bg-slate-950/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                  }`}
                >
                  {chord.name}
                </button>
              ))
            : SCALES_DATA.map((scale, idx) => (
                <button
                  key={scale.name}
                  onClick={() => setSelectedScaleIndex(idx)}
                  className={`px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all border ${
                    selectedScaleIndex === idx
                      ? 'bg-amber-500/20 text-amber-300 border-amber-500/80 shadow-md ring-1 ring-amber-400/40'
                      : 'bg-slate-950/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                  }`}
                >
                  {scale.name}
                </button>
              ))}
        </div>

        {/* Selected Details Card */}
        <div className="mt-5 p-4 rounded-xl bg-slate-950/70 border border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-3">
              <h3 className="text-xl font-serif font-bold text-slate-100">
                {viewType === 'chords' ? currentChord?.name : currentScale?.name}
              </h3>
              <span className="text-xs font-mono px-2 py-0.5 rounded bg-amber-500/10 text-amber-300 border border-amber-500/30">
                {viewType === 'chords' ? currentChord?.quality : currentScale?.quality}
              </span>
            </div>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              {viewType === 'chords' ? currentChord?.description : currentScale?.description}
            </p>

            <div className="flex flex-wrap items-center gap-4 mt-3 text-xs">
              <div>
                <span className="text-slate-500 font-semibold uppercase mr-1.5">Notes:</span>
                <span className="font-mono text-amber-300 font-bold">
                  {(viewType === 'chords' ? currentChord?.notes : currentScale?.notes)?.join(' - ')}
                </span>
              </div>
              <div>
                <span className="text-slate-500 font-semibold uppercase mr-1.5">Intervals:</span>
                <span className="font-mono text-emerald-400 font-semibold">
                  {(viewType === 'chords' ? currentChord?.intervals : currentScale?.intervals)?.join(' • ')}
                </span>
              </div>
            </div>
          </div>

          <button
            data-testid="play-audio-btn"
            onClick={handlePlayChord}
            className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-bold text-xs uppercase tracking-wider flex items-center gap-2 shadow-lg shadow-amber-950/40 shrink-0 self-start md:self-auto transition-all"
          >
            <Play className="w-4 h-4 fill-current" />
            {viewType === 'chords' ? 'Play Arpeggio' : 'Play Scale'}
          </button>
        </div>
      </div>

      {/* Render the matching instrument graphic */}
      {instrument === 'piano' ? (
        <InteractivePiano
          highlightedNotes={pianoHighlightedNotes}
          title={`Piano Voicing: ${viewType === 'chords' ? currentChord?.name : currentScale?.name}`}
          subtitle="Golden highlighted keys correspond to the active chord or scale degrees."
        />
      ) : (
        <InteractiveFretboard
          highlights={guitarHighlights}
          title={`Guitar Fretboard Pattern: ${viewType === 'chords' ? currentChord?.name : currentScale?.name}`}
          subtitle="Gold dots indicate root notes. Green dots denote chord tones or scale degrees."
        />
      )}
    </div>
  );
};
