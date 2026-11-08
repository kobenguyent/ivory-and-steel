import React, { useState, useMemo } from 'react';
import {
  CIRCLE_OF_FIFTHS_KEYS,
  CHROMATIC_ROOTS,
  SCALE_QUALITIES,
  CHORD_QUALITIES,
  getKeyInfo,
  getScaleNotes,
  getChordNotes,
  getGuitarScaleHighlights,
  getGuitarChordVoicing,
  getDiatonicChords,
  DiatonicChord,
  normalizeToPianoKey,
} from '../utils/musicTheory';
import { InteractivePiano } from './InteractivePiano';
import { InteractiveFretboard } from './InteractiveFretboard';
import { CircleOfFifths } from './CircleOfFifths';
import { audioEngine } from '../utils/audio';
import {
  Play,
  Compass,
  Sparkles,
  Music2,
  Layers,
  Volume2,
  Guitar,
  Piano,
  RotateCcw,
  CheckCircle2,
  Filter,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Grid,
} from 'lucide-react';

export type ExplorerViewType = 'diatonic' | 'chords' | 'scales';

// Harmonic function roles and psychological descriptions for Western music pedagogy
const HARMONIC_ROLES_MAJOR: Record<string, { role: string; tag: string; color: string }> = {
  'I': { role: 'Tonic Home Base', tag: 'Tonic', color: 'text-amber-400 bg-amber-500/10 border-amber-500/30' },
  'ii': { role: 'Supertonic (Pre-dominant)', tag: 'Supertonic', color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' },
  'iii': { role: 'Mediant (Tonic substitute)', tag: 'Mediant', color: 'text-slate-300 bg-slate-800/40 border-slate-700/40' },
  'IV': { role: 'Subdominant (Departure)', tag: 'Subdominant', color: 'text-emerald-300 bg-emerald-500/15 border-emerald-500/30' },
  'V': { role: 'Dominant (Peak Tension)', tag: 'Dominant', color: 'text-sky-300 bg-sky-500/15 border-sky-500/30' },
  'vi': { role: 'Submediant (Relative Minor)', tag: 'Submediant', color: 'text-purple-300 bg-purple-500/15 border-purple-500/30' },
  'vii°': { role: 'Leading Tone (Resolving to I)', tag: 'Leading Tone', color: 'text-rose-300 bg-rose-500/15 border-rose-500/30' },
};

const HARMONIC_ROLES_MINOR: Record<string, { role: string; tag: string; color: string }> = {
  'i': { role: 'Tonic Minor Home Base', tag: 'Tonic', color: 'text-amber-400 bg-amber-500/10 border-amber-500/30' },
  'ii°': { role: 'Supertonic Diminished', tag: 'Supertonic', color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' },
  'III': { role: 'Mediant (Relative Major)', tag: 'Mediant', color: 'text-purple-300 bg-purple-500/15 border-purple-500/30' },
  'iv': { role: 'Subdominant Minor', tag: 'Subdominant', color: 'text-emerald-300 bg-emerald-500/15 border-emerald-500/30' },
  'v': { role: 'Dominant Minor', tag: 'Dominant', color: 'text-sky-300 bg-sky-500/15 border-sky-500/30' },
  'VI': { role: 'Submediant Major', tag: 'Submediant', color: 'text-slate-300 bg-slate-800/40 border-slate-700/40' },
  'VII': { role: 'Subtonic Major', tag: 'Subtonic', color: 'text-rose-300 bg-rose-500/15 border-rose-500/30' },
};

export const ChordScaleExplorer: React.FC = () => {
  const [instrument, setInstrument] = useState<'piano' | 'guitar'>('piano');
  const [viewType, setViewType] = useState<ExplorerViewType>('diatonic');
  const [selectedRoot, setSelectedRoot] = useState<string>('C');
  const [keyMode, setKeyMode] = useState<'major' | 'minor'>('major');
  const [selectedScaleQualityId, setSelectedScaleQualityId] = useState<string>('major');
  const [selectedChordQualityId, setSelectedChordQualityId] = useState<string>('major');
  const [selectedDiatonicIndex, setSelectedDiatonicIndex] = useState<number>(0);
  const [showCircleOfFifths, setShowCircleOfFifths] = useState<boolean>(true);

  // Category filter state for cleaner cognitive load in Scales & Chords
  const [scaleCategoryFilter, setScaleCategoryFilter] = useState<'all' | 'mode' | 'minor' | 'pentatonic'>('all');
  const [chordCategoryFilter, setChordCategoryFilter] = useState<'all' | 'triads' | 'sevenths'>('all');
  const [showAllScalesGrid, setShowAllScalesGrid] = useState(false);
  const [showAllChordsGrid, setShowAllChordsGrid] = useState(false);

  // Stepping logic for Scale Qualities
  const currentScaleIdx = useMemo(() => {
    const idx = SCALE_QUALITIES.findIndex((s) => s.id === selectedScaleQualityId);
    return idx >= 0 ? idx : 0;
  }, [selectedScaleQualityId]);

  const handlePrevScale = () => {
    const prevIdx = (currentScaleIdx - 1 + SCALE_QUALITIES.length) % SCALE_QUALITIES.length;
    setSelectedScaleQualityId(SCALE_QUALITIES[prevIdx].id);
  };

  const handleNextScale = () => {
    const nextIdx = (currentScaleIdx + 1) % SCALE_QUALITIES.length;
    setSelectedScaleQualityId(SCALE_QUALITIES[nextIdx].id);
  };

  // Stepping logic for Chord Qualities
  const currentChordIdx = useMemo(() => {
    const idx = CHORD_QUALITIES.findIndex((c) => c.id === selectedChordQualityId);
    return idx >= 0 ? idx : 0;
  }, [selectedChordQualityId]);

  const handlePrevChord = () => {
    const prevIdx = (currentChordIdx - 1 + CHORD_QUALITIES.length) % CHORD_QUALITIES.length;
    setSelectedChordQualityId(CHORD_QUALITIES[prevIdx].id);
  };

  const handleNextChord = () => {
    const nextIdx = (currentChordIdx + 1) % CHORD_QUALITIES.length;
    setSelectedChordQualityId(CHORD_QUALITIES[nextIdx].id);
  };

  // Active Key Information
  const activeKeyInfo = useMemo(() => getKeyInfo(selectedRoot), [selectedRoot]);

  // Diatonic Chords for active key and mode
  const diatonicChords = useMemo(
    () => getDiatonicChords(selectedRoot, keyMode),
    [selectedRoot, keyMode]
  );
  const activeDiatonicChord = diatonicChords[selectedDiatonicIndex] || diatonicChords[0];

  // Active Scale Information
  const activeScale = useMemo(() => {
    const scaleData = getScaleNotes(selectedRoot, selectedScaleQualityId);
    const quality = SCALE_QUALITIES.find((q) => q.id === selectedScaleQualityId) || SCALE_QUALITIES[0];
    return {
      ...scaleData,
      name: `${activeKeyInfo.root} ${quality.name}`,
      description: quality.description,
      qualityName: quality.name,
      category: quality.category,
    };
  }, [selectedRoot, selectedScaleQualityId, activeKeyInfo]);

  // Active Chord Information
  const activeChord = useMemo(() => {
    const chordData = getChordNotes(selectedRoot, selectedChordQualityId);
    const quality = CHORD_QUALITIES.find((q) => q.id === selectedChordQualityId) || CHORD_QUALITIES[0];
    const guitarVoicing = getGuitarChordVoicing(selectedRoot, selectedChordQualityId);
    return {
      ...chordData,
      qualityName: quality.name,
      description: quality.description,
      guitarVoicing,
    };
  }, [selectedRoot, selectedChordQualityId]);

  // Convert guitar definitions to InteractiveFretboard highlights
  const guitarHighlights = useMemo(() => {
    if (viewType === 'scales') {
      return getGuitarScaleHighlights(selectedRoot, selectedScaleQualityId);
    } else if (viewType === 'chords') {
      return activeChord.guitarVoicing.map((f, i) => ({
        stringNum: f.stringNum,
        fret: f.fret,
        label: f.finger === 'open' ? 'O' : f.finger,
        isRoot: i === 0 || (f.finger === 'open' && f.fret === 0),
      }));
    } else {
      return activeDiatonicChord.guitarVoicing.map((f, i) => ({
        stringNum: f.stringNum,
        fret: f.fret,
        label: f.finger === 'open' ? 'O' : f.finger,
        isRoot: i === 0,
      }));
    }
  }, [viewType, selectedRoot, selectedScaleQualityId, activeChord, activeDiatonicChord]);

  // Piano highlighted keys
  const pianoHighlightedNotes = useMemo(() => {
    if (viewType === 'scales') {
      return activeScale.pianoKeys;
    } else if (viewType === 'chords') {
      return activeChord.pianoKeys;
    } else {
      return activeDiatonicChord.pianoKeys;
    }
  }, [viewType, activeScale, activeChord, activeDiatonicChord]);

  // Filtered scale qualities for organized view
  const visibleScales = useMemo(() => {
    if (scaleCategoryFilter === 'all') return SCALE_QUALITIES;
    return SCALE_QUALITIES.filter((q) => q.category === scaleCategoryFilter);
  }, [scaleCategoryFilter]);

  // Filtered chord qualities
  const visibleChords = useMemo(() => {
    if (chordCategoryFilter === 'all') return CHORD_QUALITIES;
    if (chordCategoryFilter === 'triads') {
      return CHORD_QUALITIES.filter((q) =>
        ['major', 'minor', 'diminished', 'augmented', 'sus4'].includes(q.id)
      );
    }
    return CHORD_QUALITIES.filter((q) =>
      ['dom7', 'maj7', 'm7', 'm7b5', 'dim7'].includes(q.id)
    );
  }, [chordCategoryFilter]);

  // External piano key animation trigger for visual synchronization
  const [externalActivePianoNotes, setExternalActivePianoNotes] = useState<Set<string>>(new Set());

  const triggerPianoKeyAnimation = (notes: string[], sequential = false, intervalMs = 280) => {
    if (notes.length === 0) return;
    if (sequential) {
      notes.forEach((note, idx) => {
        setTimeout(() => {
          setExternalActivePianoNotes(new Set([normalizeToPianoKey(note)]));
          setTimeout(() => {
            setExternalActivePianoNotes(new Set());
          }, intervalMs - 40);
        }, idx * intervalMs);
      });
    } else {
      setExternalActivePianoNotes(new Set(notes.map(normalizeToPianoKey)));
      setTimeout(() => {
        setExternalActivePianoNotes(new Set());
      }, 450);
    }
  };

  // Audio Playback
  const handlePlayAudio = () => {
    if (viewType === 'scales') {
      audioEngine.playScale(activeScale.notes, instrument);
      if (instrument === 'piano') {
        triggerPianoKeyAnimation(activeScale.notes, true, 280);
      }
    } else if (viewType === 'chords') {
      audioEngine.playChord(activeChord.notes, instrument);
      if (instrument === 'piano') {
        triggerPianoKeyAnimation(activeChord.notes, false);
      }
    } else {
      audioEngine.playChord(activeDiatonicChord.notes, instrument);
      if (instrument === 'piano') {
        triggerPianoKeyAnimation(activeDiatonicChord.notes, false);
      }
    }
  };

  // Play Full Diatonic Cadence (I -> IV -> V -> I)
  const handlePlayProgression = () => {
    const progressionIndices = [0, 3, 4, 0]; // I - IV - V - I
    progressionIndices.forEach((degIdx, step) => {
      if (step === 0) {
        const chord = diatonicChords[degIdx];
        if (chord) {
          audioEngine.playChord(chord.notes, instrument, 0.04);
          setSelectedDiatonicIndex(degIdx);
          if (instrument === 'piano') {
            triggerPianoKeyAnimation(chord.notes, false);
          }
        }
      } else {
        setTimeout(() => {
          const chord = diatonicChords[degIdx];
          if (chord) {
            audioEngine.playChord(chord.notes, instrument, 0.04);
            setSelectedDiatonicIndex(degIdx);
            if (instrument === 'piano') {
              triggerPianoKeyAnimation(chord.notes, false);
            }
          }
        }, step * 850);
      }
    });
  };

  // Play single note preview
  const handlePlaySingleNote = (note: string) => {
    if (instrument === 'piano') {
      audioEngine.playPianoNote(note, 1.4, 0.85);
    } else {
      audioEngine.playGuitarNote(note, 1.8, 0.85);
    }
  };

  // Helper formatting for notes & intervals
  const activeNotesList =
    viewType === 'diatonic'
      ? activeDiatonicChord.notes
      : viewType === 'scales'
      ? activeScale.notes
      : activeChord.notes;

  const activeIntervalsList =
    viewType === 'diatonic'
      ? ['1 Root', '3rd', '5th', activeDiatonicChord.notes.length > 3 ? '7th' : '']
          .filter(Boolean)
      : viewType === 'scales'
      ? activeScale.intervals
      : activeChord.intervals;

  const activeHarmonicRole =
    keyMode === 'major'
      ? HARMONIC_ROLES_MAJOR[activeDiatonicChord.degree] || {
          role: 'Diatonic Degree',
          tag: 'Diatonic',
          color: 'text-amber-300 bg-amber-500/10 border-amber-500/30',
        }
      : HARMONIC_ROLES_MINOR[activeDiatonicChord.degree] || {
          role: 'Diatonic Degree',
          tag: 'Diatonic',
          color: 'text-amber-300 bg-amber-500/10 border-amber-500/30',
        };

  return (
    <div className="flex flex-col gap-6 max-w-7xl mx-auto w-full">
      {/* =========================================================================
          SECTION 1: STUDIO COMMAND DECK (Clean, Atmospheric, Luxury Conservatory)
          ========================================================================= */}
      <div className="relative overflow-hidden bg-slate-900/95 dark:bg-musician-charcoal/90 border border-slate-800/90 dark:border-amber-900/30 rounded-2xl p-5 sm:p-7 shadow-2xl backdrop-blur-xl transition-all">
        {/* Subtle Ambient Gold Glow in Top-Right Corner */}
        <div
          className="absolute -top-24 -right-24 w-80 h-80 rounded-full bg-amber-500/5 blur-3xl pointer-events-none"
          aria-hidden="true"
        />

        {/* Top Header Row: Title & Studio Quick Controls */}
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-5 pb-6 border-b border-slate-800/80">
          <div>
            <div className="flex flex-wrap items-center gap-2.5">
              <div className="p-2 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400">
                <Compass className="w-5 h-5" />
              </div>
              <h2 className="text-2xl sm:text-3xl font-serif font-bold text-slate-100 tracking-tight">
                Chord & Scale Theory Explorer
              </h2>
              <span className="inline-flex items-center gap-1 text-[11px] font-mono px-2.5 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30 font-semibold shadow-sm">
                <Sparkles className="w-3 h-3 text-amber-400" />
                Universal 12 Keys
              </span>
            </div>
            <p className="text-xs sm:text-sm text-slate-400 mt-1.5 max-w-2xl leading-relaxed">
              Master harmony, modal scales, and chord voicings across all 12 musical keys with
              instant real-time acoustic synthesis and interactive instrument fretboards.
            </p>
          </div>

          {/* Quick Segmented Controls */}
          <div className="flex flex-wrap items-center gap-3">
            {/* Instrument Segmented Switcher */}
            <div className="bg-slate-950/90 p-1 rounded-xl border border-slate-800/90 flex shadow-inner">
              <button
                data-testid="toggle-piano"
                onClick={() => setInstrument('piano')}
                aria-label="Switch to Grand Piano view"
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  instrument === 'piano'
                    ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-extrabold shadow-md'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <span>🎹 Piano</span>
              </button>
              <button
                data-testid="toggle-guitar"
                onClick={() => setInstrument('guitar')}
                aria-label="Switch to Guitar Fretboard view"
                className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  instrument === 'guitar'
                    ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-extrabold shadow-md'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <span>🎸 Guitar</span>
              </button>
            </div>

            {/* Circle of Fifths Compass Toggle */}
            <button
              data-testid="toggle-circle-of-fifths"
              onClick={() => setShowCircleOfFifths(!showCircleOfFifths)}
              aria-label="Toggle Circle of Fifths Harmonic Compass"
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold border flex items-center gap-2 transition-all ${
                showCircleOfFifths
                  ? 'bg-amber-500/15 text-amber-300 border-amber-500/40 shadow-sm ring-1 ring-amber-500/20'
                  : 'bg-slate-950/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
              }`}
            >
              <Compass className={`w-3.5 h-3.5 ${showCircleOfFifths ? 'text-amber-400' : 'text-slate-500'}`} />
              <span>{showCircleOfFifths ? 'Circle: ON' : 'Circle: OFF'}</span>
            </button>
          </div>
        </div>

        {/* 12-Key Chromatic Selector Ribbon */}
        <div className="pt-5 pb-2">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-3">
            <span className="text-[11px] font-mono uppercase tracking-wider text-amber-400 font-semibold flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" />
              Select Root Key Center:
            </span>
            <div className="flex items-center gap-2 text-xs font-mono">
              <span className="text-slate-400">Active Key:</span>
              <strong className="text-amber-300 font-serif text-sm">
                {activeKeyInfo.name}
              </strong>
              <span className="px-2 py-0.5 rounded bg-slate-800/80 text-slate-300 border border-slate-700 text-[11px]">
                {activeKeyInfo.keySignatureDesc}
              </span>
              <span className="hidden sm:inline-block px-2 py-0.5 rounded bg-purple-950/40 text-purple-300 border border-purple-800/40 text-[11px]">
                Rel. Minor: {activeKeyInfo.relativeMinor}
              </span>
            </div>
          </div>

          {/* 12 Tactile Key Buttons */}
          <div className="grid grid-cols-4 sm:grid-cols-6 lg:grid-cols-12 gap-2">
            {CHROMATIC_ROOTS.map((root) => {
              const isSelected = selectedRoot === root;
              const kInfo = getKeyInfo(root);
              const displayLabel = root.replace('b', '♭').replace('#', '♯');

              return (
                <button
                  key={root}
                  data-testid={`root-select-${root}`}
                  onClick={() => {
                    setSelectedRoot(root);
                    setSelectedDiatonicIndex(0);
                  }}
                  aria-label={`Select key of ${root}`}
                  className={`relative py-2.5 px-1 rounded-xl text-xs font-bold transition-all text-center border flex flex-col items-center justify-center gap-0.5 ${
                    isSelected
                      ? 'bg-gradient-to-b from-amber-400 to-amber-500 text-slate-950 font-extrabold border-amber-300 shadow-glow-gold scale-105 ring-2 ring-amber-400/50 z-10'
                      : 'bg-slate-950/80 text-slate-300 border-slate-800/90 hover:border-amber-500/50 hover:bg-slate-900 hover:text-white'
                  }`}
                >
                  <span className="font-serif text-base tracking-wide leading-none">{displayLabel}</span>
                  <span
                    className={`text-[9px] font-mono leading-none ${
                      isSelected ? 'text-slate-900 font-extrabold' : 'text-slate-500'
                    }`}
                  >
                    {kInfo.accidentalType === 'natural'
                      ? '♮'
                      : kInfo.accidentalType === 'sharp'
                      ? `${kInfo.sharpsCount}♯`
                      : `${kInfo.flatsCount}♭`}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* =========================================================================
            SECTION 2: HARMONIC MODE DECK (Diatonic Suite / Scales / Chords)
            ========================================================================= */}
        <div className="mt-5 pt-5 border-t border-slate-800/80">
          {/* Mode Switcher Tabs */}
          <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
            <div className="bg-slate-950/90 p-1 rounded-xl border border-slate-800/90 flex gap-1 shadow-inner">
              <button
                data-testid="toggle-diatonic"
                onClick={() => setViewType('diatonic')}
                aria-label="View Diatonic Chords Suite"
                className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                  viewType === 'diatonic'
                    ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40 shadow-sm'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Layers className="w-3.5 h-3.5" />
                <span>Diatonic Suite</span>
              </button>
              <button
                data-testid="toggle-scales"
                onClick={() => setViewType('scales')}
                aria-label="View Scales & Modes"
                className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                  viewType === 'scales'
                    ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Music2 className="w-3.5 h-3.5" />
                <span>Scales & Modes</span>
              </button>
              <button
                data-testid="toggle-chords"
                onClick={() => setViewType('chords')}
                aria-label="View Chord Library"
                className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                  viewType === 'chords'
                    ? 'bg-sky-500/20 text-sky-300 border border-sky-500/40 shadow-sm'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Sparkles className="w-3.5 h-3.5" />
                <span>Chord Voicings</span>
              </button>
            </div>

            {/* Diatonic Cadence Audio CTA (if Diatonic View) */}
            {viewType === 'diatonic' && (
              <button
                data-testid="play-progression-btn"
                onClick={handlePlayProgression}
                aria-label="Play I - IV - V - I Cadence Progression"
                className="px-4 py-1.5 rounded-xl bg-amber-500/15 hover:bg-amber-500/25 border border-amber-500/40 text-amber-300 font-bold text-xs flex items-center gap-2 transition-all shadow-sm hover:shadow"
              >
                <Play className="w-3.5 h-3.5 fill-current" />
                <span>Play I – IV – V – I Cadence</span>
              </button>
            )}
          </div>

          {/* MODE CONTENT: DIATONIC SUITE */}
          {viewType === 'diatonic' && (
            <div className="space-y-3">
              {/* Key Center Quality Toggle */}
              <div className="flex items-center gap-3 text-xs">
                <span className="font-semibold text-slate-400">Mode Center:</span>
                <div className="bg-slate-950 p-0.5 rounded-lg border border-slate-800 flex">
                  <button
                    onClick={() => {
                      setKeyMode('major');
                      setSelectedDiatonicIndex(0);
                    }}
                    className={`px-3 py-1 rounded text-xs font-bold transition-all ${
                      keyMode === 'major'
                        ? 'bg-amber-500 text-slate-950 font-extrabold shadow-sm'
                        : 'text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    Major Key ({activeKeyInfo.name})
                  </button>
                  <button
                    onClick={() => {
                      setKeyMode('minor');
                      setSelectedDiatonicIndex(0);
                    }}
                    className={`px-3 py-1 rounded text-xs font-bold transition-all ${
                      keyMode === 'minor'
                        ? 'bg-amber-500 text-slate-950 font-extrabold shadow-sm'
                        : 'text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    Natural Minor ({activeKeyInfo.relativeMinor})
                  </button>
                </div>
              </div>

              {/* 7 Diatonic Chords Strip */}
              <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-2.5 pt-1">
                {diatonicChords.map((chord, idx) => {
                  const isSelected = selectedDiatonicIndex === idx;
                  const roleData =
                    keyMode === 'major'
                      ? HARMONIC_ROLES_MAJOR[chord.degree]
                      : HARMONIC_ROLES_MINOR[chord.degree];

                  return (
                    <button
                      key={`${chord.degree}-${chord.root}`}
                      data-testid={`diatonic-chord-${chord.degree}`}
                      onClick={() => {
                        setSelectedDiatonicIndex(idx);
                        audioEngine.playChord(chord.notes, instrument, 0.04);
                      }}
                      aria-label={`Diatonic chord ${chord.degree}: ${chord.root} ${chord.quality}`}
                      className={`p-3 rounded-xl border text-left transition-all flex flex-col justify-between gap-2 ${
                        isSelected
                          ? 'bg-amber-500/20 border-amber-400 text-amber-200 ring-2 ring-amber-400/40 shadow-lg scale-[1.02]'
                          : chord.isTonic
                          ? 'bg-amber-950/20 border-amber-500/30 text-slate-300 hover:border-amber-400 hover:bg-amber-950/30'
                          : chord.isDominant
                          ? 'bg-sky-950/20 border-sky-500/30 text-slate-300 hover:border-sky-400 hover:bg-sky-950/30'
                          : 'bg-slate-950/80 border-slate-800 text-slate-400 hover:text-slate-200 hover:border-slate-700'
                      }`}
                    >
                      <div className="flex items-center justify-between text-[11px] font-mono">
                        <span className="font-serif font-bold text-sm text-amber-400">{chord.degree}</span>
                        <span className="text-[10px] text-slate-400 uppercase font-semibold">{chord.quality}</span>
                      </div>
                      <div className="font-serif font-bold text-base text-slate-100 truncate">
                        {chord.root} {chord.quality}
                      </div>
                      {roleData && (
                        <div
                          className={`text-[9px] font-mono px-1.5 py-0.5 rounded border truncate ${roleData.color}`}
                        >
                          {roleData.tag}
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* MODE CONTENT: SCALES & MODES */}
          {viewType === 'scales' && (
            <div className="space-y-3">
              {/* Clean Luxury Studio Selector Strip */}
              <div className="flex flex-wrap items-center justify-between gap-3 p-2.5 rounded-xl bg-slate-950/80 border border-slate-800/90 shadow-inner">
                {/* Left: Dropdown with optgroups & Steppers */}
                <div className="flex flex-wrap items-center gap-2.5 flex-1 min-w-[280px]">
                  <span className="text-xs font-semibold text-emerald-400 shrink-0 flex items-center gap-1.5 font-mono">
                    <Music2 className="w-3.5 h-3.5" />
                    Scale:
                  </span>

                  {/* Dropdown Select Box */}
                  <div className="relative flex-1 min-w-[210px] max-w-xs">
                    <select
                      id="scale-quality-select"
                      data-testid="select-scale-quality"
                      value={selectedScaleQualityId}
                      onChange={(e) => setSelectedScaleQualityId(e.target.value)}
                      className="w-full appearance-none bg-slate-900/95 text-slate-100 text-xs sm:text-sm font-semibold rounded-lg border border-emerald-500/40 hover:border-emerald-400 focus:border-emerald-400 focus:ring-2 focus:ring-emerald-500/20 pl-3 pr-8 py-2 shadow-inner transition-all cursor-pointer font-serif tracking-wide"
                    >
                      <optgroup label="🌟 Diatonic Modes (Western Harmony)">
                        <option value="major">Major Scale (Ionian)</option>
                        <option value="dorian">Dorian Mode</option>
                        <option value="phrygian">Phrygian Mode</option>
                        <option value="lydian">Lydian Mode</option>
                        <option value="mixolydian">Mixolydian Mode</option>
                        <option value="natural_minor">Natural Minor (Aeolian)</option>
                      </optgroup>
                      <optgroup label="🎷 Classical & Jazz Minor">
                        <option value="harmonic_minor">Harmonic Minor</option>
                        <option value="melodic_minor">Melodic Minor (Jazz)</option>
                      </optgroup>
                      <optgroup label="🎸 Pentatonic & Blues Soloing">
                        <option value="major_pentatonic">Major Pentatonic</option>
                        <option value="minor_pentatonic">Minor Pentatonic</option>
                        <option value="blues">Blues Scale</option>
                      </optgroup>
                    </select>
                    <ChevronDown className="w-4 h-4 text-emerald-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  {/* Audition Steppers */}
                  <div className="flex items-center gap-0.5 bg-slate-900 p-0.5 rounded-lg border border-slate-800">
                    <button
                      type="button"
                      onClick={handlePrevScale}
                      title="Previous scale (audition step)"
                      className="p-1.5 rounded hover:bg-slate-800 text-slate-400 hover:text-emerald-300 transition-colors"
                    >
                      <ChevronLeft className="w-3.5 h-3.5" />
                    </button>
                    <span className="text-[10px] font-mono text-slate-500 px-1 select-none">
                      {currentScaleIdx + 1}/{SCALE_QUALITIES.length}
                    </span>
                    <button
                      type="button"
                      onClick={handleNextScale}
                      title="Next scale (audition step)"
                      className="p-1.5 rounded hover:bg-slate-800 text-slate-400 hover:text-emerald-300 transition-colors"
                    >
                      <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                {/* Right: Curated Hero Quick-Pills & View Toggle */}
                <div className="flex flex-wrap items-center gap-1.5">
                  <span className="text-[11px] text-slate-500 font-mono hidden md:inline mr-1">Quick:</span>
                  {[
                    { id: 'major', label: 'Major' },
                    { id: 'natural_minor', label: 'Natural Minor' },
                    { id: 'blues', label: 'Blues' },
                    { id: 'dorian', label: 'Dorian' },
                  ].map((hero) => {
                    const isSelected = selectedScaleQualityId === hero.id;
                    return (
                      <button
                        key={hero.id}
                        data-testid={`scale-quality-${hero.id}`}
                        onClick={() => setSelectedScaleQualityId(hero.id)}
                        className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all border ${
                          isSelected
                            ? 'bg-emerald-500/20 text-emerald-200 border-emerald-400/80 ring-1 ring-emerald-400/40 shadow-sm font-bold'
                            : 'bg-slate-900/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                        }`}
                      >
                        {hero.label}
                      </button>
                    );
                  })}

                  {/* Dynamic Active Chip if not in the 4 hero chips */}
                  {![
                    'major',
                    'natural_minor',
                    'blues',
                    'dorian',
                  ].includes(selectedScaleQualityId) && (
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-500/25 text-emerald-200 border border-emerald-400 ring-1 ring-emerald-400/30 flex items-center gap-1 shadow-sm">
                      <span>{activeScale.qualityName}</span>
                    </span>
                  )}

                  {/* Grid View Toggle */}
                  <button
                    type="button"
                    onClick={() => setShowAllScalesGrid(!showAllScalesGrid)}
                    title={showAllScalesGrid ? 'Switch to compact view' : 'Browse all 11 scales in grid'}
                    className={`px-2 py-1 rounded-lg text-xs font-medium border transition-colors flex items-center gap-1 ml-1 ${
                      showAllScalesGrid
                        ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/50'
                        : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-slate-200'
                    }`}
                  >
                    <Grid className="w-3 h-3" />
                    <span className="text-[11px]">{showAllScalesGrid ? 'Compact' : 'All (11)'}</span>
                  </button>
                </div>
              </div>

              {/* Optional Expanded Grid View */}
              {showAllScalesGrid && (
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 space-y-3 animate-fadeIn">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="text-xs font-semibold text-slate-400">Filter By Category:</span>
                    <div className="flex flex-wrap gap-1 text-xs">
                      {(
                        [
                          { id: 'all', label: 'All Scales (11)' },
                          { id: 'mode', label: 'Diatonic Modes' },
                          { id: 'minor', label: 'Minor Variations' },
                          { id: 'pentatonic', label: 'Pentatonic & Blues' },
                        ] as const
                      ).map((cat) => (
                        <button
                          key={cat.id}
                          onClick={() => setScaleCategoryFilter(cat.id)}
                          className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
                            scaleCategoryFilter === cat.id
                              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40'
                              : 'text-slate-400 hover:text-slate-200 bg-slate-900/80'
                          }`}
                        >
                          {cat.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 pt-1">
                    {visibleScales.map((sq) => {
                      const isSelected = selectedScaleQualityId === sq.id;
                      return (
                        <button
                          key={sq.id}
                          data-testid={`scale-quality-${sq.id}`}
                          onClick={() => setSelectedScaleQualityId(sq.id)}
                          aria-label={`Select scale ${sq.name}`}
                          className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border flex items-center gap-1.5 ${
                            isSelected
                              ? 'bg-emerald-500/25 text-emerald-200 border-emerald-400 ring-2 ring-emerald-400/40 shadow-md font-bold'
                              : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                          }`}
                        >
                          <span>{sq.name}</span>
                          <span className="text-[10px] font-mono px-1 py-0.2 rounded bg-slate-950 text-slate-400 border border-slate-800">
                            {sq.category}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* MODE CONTENT: CHORD VOICINGS */}
          {viewType === 'chords' && (
            <div className="space-y-3">
              {/* Clean Luxury Studio Selector Strip */}
              <div className="flex flex-wrap items-center justify-between gap-3 p-2.5 rounded-xl bg-slate-950/80 border border-slate-800/90 shadow-inner">
                {/* Left: Dropdown with optgroups & Steppers */}
                <div className="flex flex-wrap items-center gap-2.5 flex-1 min-w-[280px]">
                  <span className="text-xs font-semibold text-sky-400 shrink-0 flex items-center gap-1.5 font-mono">
                    <Sparkles className="w-3.5 h-3.5" />
                    Chord:
                  </span>

                  {/* Dropdown Select Box */}
                  <div className="relative flex-1 min-w-[210px] max-w-xs">
                    <select
                      id="chord-quality-select"
                      data-testid="select-chord-quality"
                      value={selectedChordQualityId}
                      onChange={(e) => setSelectedChordQualityId(e.target.value)}
                      className="w-full appearance-none bg-slate-900/95 text-slate-100 text-xs sm:text-sm font-semibold rounded-lg border border-sky-500/40 hover:border-sky-400 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20 pl-3 pr-8 py-2 shadow-inner transition-all cursor-pointer font-serif tracking-wide"
                    >
                      <optgroup label="Triads & Suspended">
                        <option value="major">Major Triad</option>
                        <option value="minor">Minor Triad</option>
                        <option value="diminished">Diminished Triad</option>
                        <option value="augmented">Augmented Triad</option>
                        <option value="sus4">Suspended 4th (Sus4)</option>
                      </optgroup>
                      <optgroup label="7th & Extended Chords">
                        <option value="dom7">Dominant 7th (7)</option>
                        <option value="maj7">Major 7th (maj7)</option>
                        <option value="m7">Minor 7th (m7)</option>
                        <option value="m7b5">Half-Diminished (m7b5)</option>
                        <option value="dim7">Diminished 7th (dim7)</option>
                      </optgroup>
                    </select>
                    <ChevronDown className="w-4 h-4 text-sky-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  {/* Audition Steppers */}
                  <div className="flex items-center gap-0.5 bg-slate-900 p-0.5 rounded-lg border border-slate-800">
                    <button
                      type="button"
                      onClick={handlePrevChord}
                      title="Previous chord (audition step)"
                      className="p-1.5 rounded hover:bg-slate-800 text-slate-400 hover:text-sky-300 transition-colors"
                    >
                      <ChevronLeft className="w-3.5 h-3.5" />
                    </button>
                    <span className="text-[10px] font-mono text-slate-500 px-1 select-none">
                      {currentChordIdx + 1}/{CHORD_QUALITIES.length}
                    </span>
                    <button
                      type="button"
                      onClick={handleNextChord}
                      title="Next chord (audition step)"
                      className="p-1.5 rounded hover:bg-slate-800 text-slate-400 hover:text-sky-300 transition-colors"
                    >
                      <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                {/* Right: Curated Hero Quick-Pills & View Toggle */}
                <div className="flex flex-wrap items-center gap-1.5">
                  <span className="text-[11px] text-slate-500 font-mono hidden md:inline mr-1">Quick:</span>
                  {[
                    { id: 'major', label: 'Major' },
                    { id: 'minor', label: 'Minor' },
                    { id: 'dom7', label: 'Dom 7' },
                    { id: 'maj7', label: 'Maj 7' },
                    { id: 'm7', label: 'Min 7' },
                  ].map((hero) => {
                    const isSelected = selectedChordQualityId === hero.id;
                    return (
                      <button
                        key={hero.id}
                        data-testid={`chord-quality-${hero.id}`}
                        onClick={() => setSelectedChordQualityId(hero.id)}
                        className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all border ${
                          isSelected
                            ? 'bg-sky-500/20 text-sky-200 border-sky-400/80 ring-1 ring-sky-400/40 shadow-sm font-bold'
                            : 'bg-slate-900/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                        }`}
                      >
                        {hero.label}
                      </button>
                    );
                  })}

                  {/* Dynamic Active Chip if not in the 5 hero chips */}
                  {![
                    'major',
                    'minor',
                    'dom7',
                    'maj7',
                    'm7',
                  ].includes(selectedChordQualityId) && (
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-sky-500/25 text-sky-200 border border-sky-400 ring-1 ring-sky-400/30 flex items-center gap-1 shadow-sm">
                      <span>{activeChord.qualityName}</span>
                    </span>
                  )}

                  {/* Grid View Toggle */}
                  <button
                    type="button"
                    onClick={() => setShowAllChordsGrid(!showAllChordsGrid)}
                    title={showAllChordsGrid ? 'Switch to compact view' : 'Browse all 10 chords in grid'}
                    className={`px-2 py-1 rounded-lg text-xs font-medium border transition-colors flex items-center gap-1 ml-1 ${
                      showAllChordsGrid
                        ? 'bg-sky-500/20 text-sky-300 border-sky-500/50'
                        : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-slate-200'
                    }`}
                  >
                    <Grid className="w-3 h-3" />
                    <span className="text-[11px]">{showAllChordsGrid ? 'Compact' : 'All (10)'}</span>
                  </button>
                </div>
              </div>

              {/* Optional Expanded Grid View */}
              {showAllChordsGrid && (
                <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 space-y-3 animate-fadeIn">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="text-xs font-semibold text-slate-400">Filter By Type:</span>
                    <div className="flex flex-wrap gap-1 text-xs">
                      {(
                        [
                          { id: 'all', label: 'All Chords (10)' },
                          { id: 'triads', label: 'Triads & Suspended' },
                          { id: 'sevenths', label: '7th & Diminished' },
                        ] as const
                      ).map((cat) => (
                        <button
                          key={cat.id}
                          onClick={() => setChordCategoryFilter(cat.id)}
                          className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
                            chordCategoryFilter === cat.id
                              ? 'bg-sky-500/20 text-sky-300 border border-sky-500/40'
                              : 'text-slate-400 hover:text-slate-200 bg-slate-900/80'
                          }`}
                        >
                          {cat.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 pt-1">
                    {visibleChords.map((cq) => {
                      const isSelected = selectedChordQualityId === cq.id;
                      return (
                        <button
                          key={cq.id}
                          data-testid={`chord-quality-${cq.id}`}
                          onClick={() => setSelectedChordQualityId(cq.id)}
                          aria-label={`Select chord quality ${cq.name}`}
                          className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border flex items-center gap-1.5 ${
                            isSelected
                              ? 'bg-sky-500/25 text-sky-200 border-sky-400 ring-2 ring-sky-400/40 shadow-md font-bold'
                              : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                          }`}
                        >
                          <span>{cq.name}</span>
                          <span className="text-[10px] font-mono px-1 py-0.2 rounded bg-slate-950 text-slate-400 border border-slate-800">
                            {cq.symbol}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* =========================================================================
            SECTION 3: VOICING & PEDAGOGY BAR (Direct Proximity to Instruments)
            ========================================================================= */}
        <div className="mt-6 p-4 sm:p-5 rounded-xl bg-slate-950/90 border border-slate-800/90 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-inner">
          <div className="space-y-2">
            <div className="flex flex-wrap items-center gap-2.5">
              <h3 className="text-xl sm:text-2xl font-serif font-bold text-slate-100">
                {viewType === 'diatonic'
                  ? activeDiatonicChord.fullName
                  : viewType === 'scales'
                  ? activeScale.name
                  : activeChord.name}
              </h3>
              <span className="text-xs font-mono px-2.5 py-0.5 rounded-full bg-amber-500/10 text-amber-300 border border-amber-500/30 font-semibold">
                {viewType === 'diatonic'
                  ? `Degree ${activeDiatonicChord.degree} (${activeHarmonicRole.tag})`
                  : viewType === 'scales'
                  ? activeScale.qualityName
                  : activeChord.qualityName}
              </span>
            </div>

            <p className="text-xs sm:text-sm text-slate-400 max-w-2xl leading-relaxed">
              {viewType === 'diatonic'
                ? `${activeHarmonicRole.role} in the key of ${activeKeyInfo.name}. Relative minor: ${activeKeyInfo.relativeMinor}.`
                : viewType === 'scales'
                ? activeScale.description
                : activeChord.description}
            </p>

            {/* Note & Interval Degree Badges (Interactive Click-to-Play) */}
            <div className="flex flex-wrap items-center gap-1.5 pt-1">
              <span className="text-[11px] font-mono text-slate-500 uppercase tracking-wider font-semibold mr-1">
                Tones:
              </span>
              {activeNotesList.map((note, idx) => {
                const interval = activeIntervalsList[idx] || `${idx + 1}`;
                return (
                  <button
                    key={`${note}-${idx}`}
                    onClick={() => handlePlaySingleNote(note)}
                    title={`Click to preview ${note}`}
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-800 hover:border-amber-400 hover:text-amber-300 text-xs font-mono transition-all group"
                  >
                    <span className="text-amber-300 font-bold">{note}</span>
                    <span className="text-[10px] text-slate-500 group-hover:text-amber-400/80">
                      ({interval})
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Primary Audio Action Button */}
          <button
            data-testid="play-audio-btn"
            onClick={handlePlayAudio}
            aria-label="Play scale or chord audio"
            className="px-6 py-3 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-extrabold text-xs uppercase tracking-wider flex items-center justify-center gap-2.5 shadow-lg shadow-amber-950/50 hover:shadow-amber-500/20 shrink-0 self-start md:self-auto transition-all active:scale-95"
          >
            <Play className="w-4 h-4 fill-current" />
            <span>{viewType === 'scales' ? 'Play Scale' : 'Play Voicing'}</span>
          </button>
        </div>
      </div>

      {/* =========================================================================
          SECTION 4: INTERACTIVE INSTRUMENT STAGE (Direct Visual Feedback)
          ========================================================================= */}
      <div className="w-full">
        {instrument === 'piano' ? (
          <InteractivePiano
            highlightedNotes={pianoHighlightedNotes}
            rootNote={viewType === 'diatonic' ? activeDiatonicChord.root : selectedRoot}
            intervals={activeIntervalsList}
            preferFlat={activeKeyInfo.accidentalType === 'flat' || selectedRoot.includes('b')}
            externalActiveNotes={externalActivePianoNotes}
            title={`Piano Voicing: ${
              viewType === 'diatonic'
                ? activeDiatonicChord.fullName
                : viewType === 'scales'
                ? activeScale.name
                : activeChord.name
            }`}
            subtitle={`Virtual Grand Piano highlights corresponding to ${selectedRoot} in ${viewType} mode.`}
          />
        ) : (
          <InteractiveFretboard
            highlights={guitarHighlights}
            title={`Guitar Fretboard Pattern: ${
              viewType === 'diatonic'
                ? activeDiatonicChord.fullName
                : viewType === 'scales'
                ? activeScale.name
                : activeChord.name
            }`}
            subtitle={`6-String Fretboard in Standard Tuning (EADGBE). Gold dots indicate roots; green dots denote chord/scale degrees.`}
          />
        )}
      </div>

      {/* =========================================================================
          SECTION 5: CIRCLE OF FIFTHS HARMONIC COMPASS (Expandable Astrolabe)
          ========================================================================= */}
      {showCircleOfFifths && (
        <CircleOfFifths
          selectedRoot={selectedRoot}
          onSelectKey={(newRoot) => {
            setSelectedRoot(newRoot);
            setSelectedDiatonicIndex(0);
          }}
        />
      )}
    </div>
  );
};
