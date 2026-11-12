// 12-TET Music Theory & Harmonization Engine for Ivory & Steel

export interface KeyInfo {
  root: string;
  name: string;
  pitchClass: number; // 0 = C, 1 = C#/Db, ..., 11 = B
  sharpsCount: number;
  flatsCount: number;
  accidentalType: 'natural' | 'sharp' | 'flat';
  keySignatureDesc: string;
  relativeMinor: string;
  relativeMinorRoot: string;
  majorScaleNotes: string[];
}

export interface ScaleQualityInfo {
  id: string;
  name: string;
  category: 'major' | 'minor' | 'mode' | 'pentatonic';
  semitones: number[];
  intervalLabels: string[];
  description: string;
}

export interface ChordQualityInfo {
  id: string;
  name: string;
  symbol: string;
  semitones: number[];
  intervalLabels: string[];
  description: string;
}

export interface DiatonicChord {
  degree: string; // e.g. "I", "ii", "V7"
  root: string;
  quality: string;
  fullName: string;
  notes: string[];
  pianoKeys: string[];
  guitarVoicing: { stringNum: number; fret: number; finger?: string }[];
  isDominant?: boolean;
  isTonic?: boolean;
}

export const CIRCLE_OF_FIFTHS_KEYS: KeyInfo[] = [
  {
    root: 'C',
    name: 'C Major',
    pitchClass: 0,
    sharpsCount: 0,
    flatsCount: 0,
    accidentalType: 'natural',
    keySignatureDesc: 'Natural (No sharps or flats)',
    relativeMinor: 'A Minor',
    relativeMinorRoot: 'A',
    majorScaleNotes: ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
  },
  {
    root: 'G',
    name: 'G Major',
    pitchClass: 7,
    sharpsCount: 1,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '1 Sharp (F♯)',
    relativeMinor: 'E Minor',
    relativeMinorRoot: 'E',
    majorScaleNotes: ['G', 'A', 'B', 'C', 'D', 'E', 'F#'],
  },
  {
    root: 'D',
    name: 'D Major',
    pitchClass: 2,
    sharpsCount: 2,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '2 Sharps (F♯, C♯)',
    relativeMinor: 'B Minor',
    relativeMinorRoot: 'B',
    majorScaleNotes: ['D', 'E', 'F#', 'G', 'A', 'B', 'C#'],
  },
  {
    root: 'A',
    name: 'A Major',
    pitchClass: 9,
    sharpsCount: 3,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '3 Sharps (F♯, C♯, G♯)',
    relativeMinor: 'F# Minor',
    relativeMinorRoot: 'F#',
    majorScaleNotes: ['A', 'B', 'C#', 'D', 'E', 'F#', 'G#'],
  },
  {
    root: 'E',
    name: 'E Major',
    pitchClass: 4,
    sharpsCount: 4,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '4 Sharps (F♯, C♯, G♯, D♯)',
    relativeMinor: 'C# Minor',
    relativeMinorRoot: 'C#',
    majorScaleNotes: ['E', 'F#', 'G#', 'A', 'B', 'C#', 'D#'],
  },
  {
    root: 'B',
    name: 'B Major',
    pitchClass: 11,
    sharpsCount: 5,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '5 Sharps (F♯, C♯, G♯, D♯, A♯)',
    relativeMinor: 'G# Minor',
    relativeMinorRoot: 'G#',
    majorScaleNotes: ['B', 'C#', 'D#', 'E', 'F#', 'G#', 'A#'],
  },
  {
    root: 'F#',
    name: 'F# Major',
    pitchClass: 6,
    sharpsCount: 6,
    flatsCount: 0,
    accidentalType: 'sharp',
    keySignatureDesc: '6 Sharps (F♯, C♯, G♯, D♯, A♯, E♯)',
    relativeMinor: 'D# Minor',
    relativeMinorRoot: 'D#',
    majorScaleNotes: ['F#', 'G#', 'A#', 'B', 'C#', 'D#', 'F'],
  },
  {
    root: 'Db',
    name: 'D♭ Major',
    pitchClass: 1,
    sharpsCount: 0,
    flatsCount: 5,
    accidentalType: 'flat',
    keySignatureDesc: '5 Flats (B♭, E♭, A♭, D♭, G♭)',
    relativeMinor: 'B♭ Minor',
    relativeMinorRoot: 'Bb',
    majorScaleNotes: ['Db', 'Eb', 'F', 'Gb', 'Ab', 'Bb', 'C'],
  },
  {
    root: 'Ab',
    name: 'A♭ Major',
    pitchClass: 8,
    sharpsCount: 0,
    flatsCount: 4,
    accidentalType: 'flat',
    keySignatureDesc: '4 Flats (B♭, E♭, A♭, D♭)',
    relativeMinor: 'F Minor',
    relativeMinorRoot: 'F',
    majorScaleNotes: ['Ab', 'Bb', 'C', 'Db', 'Eb', 'F', 'G'],
  },
  {
    root: 'Eb',
    name: 'E♭ Major',
    pitchClass: 3,
    sharpsCount: 0,
    flatsCount: 3,
    accidentalType: 'flat',
    keySignatureDesc: '3 Flats (B♭, E♭, A♭)',
    relativeMinor: 'C Minor',
    relativeMinorRoot: 'C',
    majorScaleNotes: ['Eb', 'F', 'G', 'Ab', 'Bb', 'C', 'D'],
  },
  {
    root: 'Bb',
    name: 'B♭ Major',
    pitchClass: 10,
    sharpsCount: 0,
    flatsCount: 2,
    accidentalType: 'flat',
    keySignatureDesc: '2 Flats (B♭, E♭)',
    relativeMinor: 'G Minor',
    relativeMinorRoot: 'G',
    majorScaleNotes: ['Bb', 'C', 'D', 'Eb', 'F', 'G', 'A'],
  },
  {
    root: 'F',
    name: 'F Major',
    pitchClass: 5,
    sharpsCount: 0,
    flatsCount: 1,
    accidentalType: 'flat',
    keySignatureDesc: '1 Flat (B♭)',
    relativeMinor: 'D Minor',
    relativeMinorRoot: 'D',
    majorScaleNotes: ['F', 'G', 'A', 'Bb', 'C', 'D', 'E'],
  },
];

// Chromatic ordering for linear root selectors
export const CHROMATIC_ROOTS = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'
];

export const ROOT_PITCH_MAP: Record<string, number> = {
  'C': 0, 'C#': 1, 'DB': 1,
  'D': 2, 'D#': 3, 'EB': 3,
  'E': 4, 'FB': 4,
  'F': 5, 'E#': 5,
  'F#': 6, 'GB': 6,
  'G': 7, 'G#': 8, 'AB': 8,
  'A': 9, 'A#': 10, 'BB': 10,
  'B': 11, 'CB': 11,
};

export const STANDARD_SHARP_PITCH_NAMES = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

export const STANDARD_FLAT_PITCH_NAMES = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
];

export const SCALE_QUALITIES: ScaleQualityInfo[] = [
  {
    id: 'major',
    name: 'Major Scale (Ionian)',
    category: 'major',
    semitones: [0, 2, 4, 5, 7, 9, 11],
    intervalLabels: ['1', '2', '3', '4', '5', '6', '7', '8'],
    description: 'The primary diatonic major scale. Formula: W-W-H-W-W-W-H. Bright, consonant, and foundational.',
  },
  {
    id: 'natural_minor',
    name: 'Natural Minor (Aeolian)',
    category: 'minor',
    semitones: [0, 2, 3, 5, 7, 8, 10],
    intervalLabels: ['1', '2', 'b3', '4', '5', 'b6', 'b7', '8'],
    description: 'The natural minor scale. Formula: W-H-W-W-H-W-W. Melancholic, dramatic, and emotionally resonant.',
  },
  {
    id: 'harmonic_minor',
    name: 'Harmonic Minor',
    category: 'minor',
    semitones: [0, 2, 3, 5, 7, 8, 11],
    intervalLabels: ['1', '2', 'b3', '4', '5', 'b6', '7', '8'],
    description: 'Natural minor with a raised 7th (leading tone). Creates an exotic 1.5-step leap between ♭6 and 7.',
  },
  {
    id: 'melodic_minor',
    name: 'Melodic Minor (Jazz)',
    category: 'minor',
    semitones: [0, 2, 3, 5, 7, 9, 11],
    intervalLabels: ['1', '2', 'b3', '4', '5', '6', '7', '8'],
    description: 'Minor third with natural 6th and 7th. The essential parent scale for modern jazz improvisation.',
  },
  {
    id: 'major_pentatonic',
    name: 'Major Pentatonic',
    category: 'pentatonic',
    semitones: [0, 2, 4, 7, 9],
    intervalLabels: ['1', '2', '3', '5', '6', '8'],
    description: '5-note pure major scale with no clashing semitones. Ubiquitous in country, pop, and blues solos.',
  },
  {
    id: 'minor_pentatonic',
    name: 'Minor Pentatonic',
    category: 'pentatonic',
    semitones: [0, 3, 5, 7, 10],
    intervalLabels: ['1', 'b3', '4', '5', 'b7', '8'],
    description: 'The ultimate rock and blues soloing scale. Contains degrees 1, ♭3, 4, 5, ♭7.',
  },
  {
    id: 'blues',
    name: 'Blues Scale',
    category: 'pentatonic',
    semitones: [0, 3, 5, 6, 7, 10],
    intervalLabels: ['1', 'b3', '4', 'b5', '5', 'b7', '8'],
    description: 'Minor pentatonic amplified with the crying "Blue Note" (diminished 5th / ♭5).',
  },
  {
    id: 'dorian',
    name: 'Dorian Mode',
    category: 'mode',
    semitones: [0, 2, 3, 5, 7, 9, 10],
    intervalLabels: ['1', '2', 'b3', '4', '5', '6', 'b7', '8'],
    description: 'The 2nd mode of the major scale. Minor with a sweet, raised natural 6th (Santana / So What).',
  },
  {
    id: 'mixolydian',
    name: 'Mixolydian Mode',
    category: 'mode',
    semitones: [0, 2, 4, 5, 7, 9, 10],
    intervalLabels: ['1', '2', '3', '4', '5', '6', 'b7', '8'],
    description: 'The 5th mode of the major scale. Major with a bluesy flattened 7th. Southern rock and funk staple.',
  },
  {
    id: 'phrygian',
    name: 'Phrygian Mode',
    category: 'mode',
    semitones: [0, 1, 3, 5, 7, 8, 10],
    intervalLabels: ['1', 'b2', 'b3', '4', '5', 'b6', 'b7', '8'],
    description: 'The 3rd mode of the major scale. Features a dark, immediate half-step ♭2. Spanish and metal flavor.',
  },
  {
    id: 'lydian',
    name: 'Lydian Mode',
    category: 'mode',
    semitones: [0, 2, 4, 6, 7, 9, 11],
    intervalLabels: ['1', '2', '3', '#4', '5', '6', '7', '8'],
    description: 'The 4th mode of the major scale. Major with an ethereal raised 4th (♯4). Dreamy and cinematic.',
  },
];

export const CHORD_QUALITIES: ChordQualityInfo[] = [
  {
    id: 'major',
    name: 'Major Triad',
    symbol: '',
    semitones: [0, 4, 7],
    intervalLabels: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)'],
    description: 'Pure, consonant, and uplifting foundation of Western harmony.',
  },
  {
    id: 'minor',
    name: 'Minor Triad',
    symbol: 'm',
    semitones: [0, 3, 7],
    intervalLabels: ['Root (1)', 'Minor 3rd (b3)', 'Perfect 5th (5)'],
    description: 'Somber, dramatic, and emotionally profound.',
  },
  {
    id: 'dom7',
    name: 'Dominant 7th',
    symbol: '7',
    semitones: [0, 4, 7, 10],
    intervalLabels: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)', 'Minor 7th (b7)'],
    description: 'Tense and bluesy, possessing a powerful tritone yearning to resolve.',
  },
  {
    id: 'maj7',
    name: 'Major 7th',
    symbol: 'maj7',
    semitones: [0, 4, 7, 11],
    intervalLabels: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)', 'Major 7th (7)'],
    description: 'Lush, nostalgic, and sophisticated. Hallmark of jazz and neo-soul.',
  },
  {
    id: 'min7',
    name: 'Minor 7th',
    symbol: 'm7',
    semitones: [0, 3, 7, 10],
    intervalLabels: ['Root (1)', 'Minor 3rd (b3)', 'Perfect 5th (5)', 'Minor 7th (b7)'],
    description: 'Mellow, introspective, and smooth. The definitive ii chord in jazz.',
  },
  {
    id: 'dim',
    name: 'Diminished Triad',
    symbol: 'dim',
    semitones: [0, 3, 6],
    intervalLabels: ['Root (1)', 'Minor 3rd (b3)', 'Diminished 5th (b5)'],
    description: 'High dissonance and tension, leading strongly back to tonic.',
  },
  {
    id: 'm7b5',
    name: 'Half-Diminished (m7♭5)',
    symbol: 'm7b5',
    semitones: [0, 3, 6, 10],
    intervalLabels: ['Root (1)', 'Minor 3rd (b3)', 'Dim 5th (b5)', 'Minor 7th (b7)'],
    description: 'The quintessential ii chord in minor key jazz cadences.',
  },
  {
    id: 'dim7',
    name: 'Diminished 7th',
    symbol: 'dim7',
    semitones: [0, 3, 6, 9],
    intervalLabels: ['Root (1)', 'Minor 3rd (b3)', 'Dim 5th (b5)', 'Dim 7th (bb7)'],
    description: 'Symmetrical stack of minor thirds; acts as a master harmonic pivot.',
  },
  {
    id: 'aug',
    name: 'Augmented Triad',
    symbol: 'aug',
    semitones: [0, 4, 8],
    intervalLabels: ['Root (1)', 'Major 3rd (3)', 'Augmented 5th (#5)'],
    description: 'Suspended, mysterious, and dreamlike with symmetrical major thirds.',
  },
  {
    id: 'sus4',
    name: 'Suspended 4th (sus4)',
    symbol: 'sus4',
    semitones: [0, 5, 7],
    intervalLabels: ['Root (1)', 'Perfect 4th (4)', 'Perfect 5th (5)'],
    description: 'Open and ambiguous, replacing the 3rd with a 4th anticipating resolution.',
  },
  {
    id: 'sus2',
    name: 'Suspended 2nd (sus2)',
    symbol: 'sus2',
    semitones: [0, 2, 7],
    intervalLabels: ['Root (1)', 'Major 2nd (2)', 'Perfect 5th (5)'],
    description: 'Airy, expansive, and gentle modern acoustic pop accompaniment.',
  },
];

/**
 * Normalizes any note name to its corresponding piano key id on the 25-key virtual piano (C4 to C6).
 * Sharp convention is used on physical keys (e.g. Eb4 -> D#4).
 */
export function normalizeToPianoKey(noteWithOctave: string): string {
  const match = noteWithOctave.trim().match(/^([A-Ga-g][b#]?)(-?\d+)$/);
  if (!match) return noteWithOctave;

  let pitch = match[1].toUpperCase();
  const octave = parseInt(match[2], 10);

  const flatToSharp: Record<string, string> = {
    'DB': 'C#',
    'EB': 'D#',
    'GB': 'F#',
    'AB': 'G#',
    'BB': 'A#',
    'CB': 'B', // note: octave might shift if needed, but in standard octave
    'E#': 'F',
    'B#': 'C',
  };

  if (flatToSharp[pitch]) {
    pitch = flatToSharp[pitch];
  }

  return `${pitch}${octave}`;
}

/**
 * Returns the KeyInfo for a given root note, matching either root name or pitch class
 */
export function getKeyInfo(root: string): KeyInfo {
  const upper = root.trim().toUpperCase();
  const direct = CIRCLE_OF_FIFTHS_KEYS.find(
    (k) => k.root.toUpperCase() === upper || k.name.toUpperCase().startsWith(upper)
  );
  if (direct) return direct;

  const pitch = ROOT_PITCH_MAP[upper];
  if (pitch !== undefined) {
    const match = CIRCLE_OF_FIFTHS_KEYS.find((k) => k.pitchClass === pitch);
    if (match) return match;
  }

  return CIRCLE_OF_FIFTHS_KEYS[0]; // fallback to C Major
}

/**
 * Format note names using preferred accidental style (# or b)
 */
export function formatPitchName(pitchClass: number, preferFlat = false): string {
  const normalized = ((pitchClass % 12) + 12) % 12;
  return preferFlat
    ? STANDARD_FLAT_PITCH_NAMES[normalized]
    : STANDARD_SHARP_PITCH_NAMES[normalized];
}

/**
 * Generate notes for any scale in scientific pitch notation (octave 4 to 5)
 */
export function getScaleNotes(
  root: string,
  qualityId: string,
  startOctave = 4
): { notes: string[]; pianoKeys: string[]; intervals: string[]; displayPitchNames: string[] } {
  const key = getKeyInfo(root);
  const rootPitch = ROOT_PITCH_MAP[root.toUpperCase()] ?? key.pitchClass;
  const quality = SCALE_QUALITIES.find((q) => q.id === qualityId) || SCALE_QUALITIES[0];
  const preferFlat = key.accidentalType === 'flat' || root.includes('b') || root.includes('B');

  const notes: string[] = [];
  const pianoKeys: string[] = [];
  const displayPitchNames: string[] = [];

  quality.semitones.forEach((st) => {
    const notePitch = (rootPitch + st) % 12;
    const octaveOffset = Math.floor((rootPitch + st) / 12);
    const octave = startOctave + octaveOffset;
    const pitchName = formatPitchName(notePitch, preferFlat);

    const scientificNote = `${pitchName}${octave}`;
    notes.push(scientificNote);
    pianoKeys.push(normalizeToPianoKey(scientificNote));
    displayPitchNames.push(pitchName);
  });

  // Complete the octave resolution note
  const finalScientific = `${notes[0].replace(/\d+$/, '')}${startOctave + 1}`;
  notes.push(finalScientific);
  pianoKeys.push(normalizeToPianoKey(finalScientific));
  displayPitchNames.push(displayPitchNames[0]);

  return {
    notes,
    pianoKeys,
    intervals: quality.intervalLabels,
    displayPitchNames,
  };
}

/**
 * Generate notes for any chord quality with comfortable keyboard voicing in C4-C5
 */
export function getChordNotes(
  root: string,
  qualityId: string
): {
  name: string;
  notes: string[];
  pianoKeys: string[];
  intervals: string[];
  displayPitchNames: string[];
} {
  const key = getKeyInfo(root);
  const rootPitch = ROOT_PITCH_MAP[root.toUpperCase()] ?? key.pitchClass;
  const quality = CHORD_QUALITIES.find((q) => q.id === qualityId) || CHORD_QUALITIES[0];
  const preferFlat = key.accidentalType === 'flat' || root.includes('b') || root.includes('B');

  // Choose starting octave so chord sits comfortably between C4 and C5
  const startOctave = rootPitch >= 7 ? 3 : 4;

  const notes: string[] = [];
  const pianoKeys: string[] = [];
  const displayPitchNames: string[] = [];

  quality.semitones.forEach((st) => {
    const notePitch = (rootPitch + st) % 12;
    const octaveOffset = Math.floor((rootPitch + st) / 12);
    const octave = startOctave + octaveOffset;
    const pitchName = formatPitchName(notePitch, preferFlat);

    const scientific = `${pitchName}${octave}`;
    notes.push(scientific);
    pianoKeys.push(normalizeToPianoKey(scientific));
    displayPitchNames.push(pitchName);
  });

  const rootDisplayName = formatPitchName(rootPitch, preferFlat);
  const chordName = `${rootDisplayName} ${quality.name}`;

  return {
    name: chordName,
    notes,
    pianoKeys,
    intervals: quality.intervalLabels,
    displayPitchNames,
  };
}

/**
 * Generate guitar fret highlights across frets 0-15 for any scale
 */
export function getGuitarScaleHighlights(
  root: string,
  qualityId: string
): { stringNum: number; fret: number; label?: string; isRoot?: boolean }[] {
  const key = getKeyInfo(root);
  const rootPitch = ROOT_PITCH_MAP[root.toUpperCase()] ?? key.pitchClass;
  const quality = SCALE_QUALITIES.find((q) => q.id === qualityId) || SCALE_QUALITIES[0];
  const preferFlat = key.accidentalType === 'flat' || root.includes('b') || root.includes('B');

  // Standard tuning open MIDI pitches: [E4=64, B3=59, G3=55, D3=50, A2=45, E2=40]
  const stringBaseMidi = [64, 59, 55, 50, 45, 40];

  const scalePitchClasses = new Set(
    quality.semitones.map((st) => (rootPitch + st) % 12)
  );

  const highlights: { stringNum: number; fret: number; label?: string; isRoot?: boolean }[] = [];

  stringBaseMidi.forEach((baseMidi, strIdx) => {
    const stringNum = strIdx + 1; // 1 to 6
    for (let fret = 0; fret <= 15; fret++) {
      const midi = baseMidi + fret;
      const pitchClass = midi % 12;

      if (scalePitchClasses.has(pitchClass)) {
        const isRoot = pitchClass === rootPitch;
        const pitchName = formatPitchName(pitchClass, preferFlat);

        // Find interval degree label
        const semitoneFromRoot = (pitchClass - rootPitch + 12) % 12;
        const semitoneIdx = quality.semitones.indexOf(semitoneFromRoot);
        const intervalLabel = semitoneIdx !== -1 ? quality.intervalLabels[semitoneIdx] : pitchName;

        highlights.push({
          stringNum,
          fret,
          label: isRoot ? 'R' : intervalLabel,
          isRoot,
        });
      }
    }
  });

  return highlights;
}

/**
 * Standard guitar chord shapes (Open & Movable CAGED / Barre) for all 12 keys
 */
export function getGuitarChordVoicing(
  root: string,
  qualityId = 'major'
): { stringNum: number; fret: number; finger?: string }[] {
  const upper = root.trim().toUpperCase();
  const pitch = ROOT_PITCH_MAP[upper] ?? 0;

  // Open chords dictionary when applicable
  const openVoicings: Record<string, { stringNum: number; fret: number; finger?: string }[]> = {
    // C Major open
    '0-major': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 3, finger: '3' },
    ],
    // C7 open
    '0-dom7': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 3, finger: '4' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 3, finger: '3' },
    ],
    // D Major open
    '2-major': [
      { stringNum: 1, fret: 2, finger: '2' },
      { stringNum: 2, fret: 3, finger: '3' },
      { stringNum: 3, fret: 2, finger: '1' },
      { stringNum: 4, fret: 0, finger: 'open' },
    ],
    // D Minor open
    '2-minor': [
      { stringNum: 1, fret: 1, finger: '1' },
      { stringNum: 2, fret: 3, finger: '3' },
      { stringNum: 3, fret: 2, finger: '2' },
      { stringNum: 4, fret: 0, finger: 'open' },
    ],
    // E Major open
    '4-major': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 0, finger: 'open' },
      { stringNum: 3, fret: 1, finger: '1' },
      { stringNum: 4, fret: 2, finger: '3' },
      { stringNum: 5, fret: 2, finger: '2' },
      { stringNum: 6, fret: 0, finger: 'open' },
    ],
    // E Minor open
    '4-minor': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 0, finger: 'open' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 2, finger: '3' },
      { stringNum: 5, fret: 2, finger: '2' },
      { stringNum: 6, fret: 0, finger: 'open' },
    ],
    // G Major open
    '7-major': [
      { stringNum: 1, fret: 3, finger: '4' },
      { stringNum: 2, fret: 3, finger: '3' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 0, finger: 'open' },
      { stringNum: 5, fret: 2, finger: '1' },
      { stringNum: 6, fret: 3, finger: '2' },
    ],
    // A Major open
    '9-major': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 2, finger: '3' },
      { stringNum: 3, fret: 2, finger: '2' },
      { stringNum: 4, fret: 2, finger: '1' },
      { stringNum: 5, fret: 0, finger: 'open' },
    ],
    // A Minor open
    '9-minor': [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 2, finger: '3' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 0, finger: 'open' },
    ],
  };

  const openKey = `${pitch}-${qualityId}`;
  if (openVoicings[openKey]) {
    return openVoicings[openKey];
  }

  // Movable barre chord generator:
  // Use E-shape if root is on string 6 (Low E = MIDI 40)
  // Low E frets: E=0, F=1, F#=2, G=3, Ab=4, A=5, Bb=6, B=7, C=8, Db=9, D=10, Eb=11
  const root6Fret = (pitch - 4 + 12) % 12; // string 6 is E (pitch 4)
  const root5Fret = (pitch - 9 + 12) % 12; // string 5 is A (pitch 9)

  // Prefer the shape that sits comfortably within frets 1-12
  if (root6Fret >= 1 && root6Fret <= 7) {
    const f = root6Fret;
    if (qualityId === 'minor' || qualityId === 'min7') {
      return [
        { stringNum: 1, fret: f, finger: '1' },
        { stringNum: 2, fret: f, finger: '1' },
        { stringNum: 3, fret: f, finger: '1' },
        { stringNum: 4, fret: f + 2, finger: '4' },
        { stringNum: 5, fret: f + 2, finger: '3' },
        { stringNum: 6, fret: f, finger: '1' },
      ];
    }
    if (qualityId === 'dom7') {
      return [
        { stringNum: 1, fret: f, finger: '1' },
        { stringNum: 2, fret: f, finger: '1' },
        { stringNum: 3, fret: f + 1, finger: '2' },
        { stringNum: 4, fret: f, finger: '1' },
        { stringNum: 5, fret: f + 2, finger: '3' },
        { stringNum: 6, fret: f, finger: '1' },
      ];
    }
    // Default Major E-shape barre
    return [
      { stringNum: 1, fret: f, finger: '1' },
      { stringNum: 2, fret: f, finger: '1' },
      { stringNum: 3, fret: f + 1, finger: '2' },
      { stringNum: 4, fret: f + 2, finger: '4' },
      { stringNum: 5, fret: f + 2, finger: '3' },
      { stringNum: 6, fret: f, finger: '1' },
    ];
  } else {
    // A-shape barre on string 5
    const f = root5Fret;
    if (qualityId === 'minor' || qualityId === 'min7') {
      return [
        { stringNum: 1, fret: f, finger: '1' },
        { stringNum: 2, fret: f + 1, finger: '2' },
        { stringNum: 3, fret: f + 2, finger: '4' },
        { stringNum: 4, fret: f + 2, finger: '3' },
        { stringNum: 5, fret: f, finger: '1' },
      ];
    }
    if (qualityId === 'maj7') {
      return [
        { stringNum: 1, fret: f, finger: '1' },
        { stringNum: 2, fret: f + 2, finger: '4' },
        { stringNum: 3, fret: f + 1, finger: '2' },
        { stringNum: 4, fret: f + 2, finger: '3' },
        { stringNum: 5, fret: f, finger: '1' },
      ];
    }
    // Default Major A-shape barre
    return [
      { stringNum: 1, fret: f, finger: '1' },
      { stringNum: 2, fret: f + 2, finger: '4' },
      { stringNum: 3, fret: f + 2, finger: '3' },
      { stringNum: 4, fret: f + 2, finger: '2' },
      { stringNum: 5, fret: f, finger: '1' },
    ];
  }
}

/**
 * Generates the full 7 diatonic chords for any key center (Major or Minor)
 */
export function getDiatonicChords(
  root: string,
  mode: 'major' | 'minor' = 'major'
): DiatonicChord[] {
  const key = getKeyInfo(root);
  const rootPitch = ROOT_PITCH_MAP[root.toUpperCase()] ?? key.pitchClass;
  const preferFlat = key.accidentalType === 'flat' || root.includes('b') || root.includes('B');

  if (mode === 'major') {
    // Major Key: I (Maj7), ii (m7), iii (m7), IV (Maj7), V (7), vi (m7), vii° (m7b5)
    const scaleDegrees = [
      { degree: 'I', semitone: 0, quality: 'maj7', roman: 'I (Tonic)', isTonic: true },
      { degree: 'ii', semitone: 2, quality: 'min7', roman: 'ii (Supertonic)' },
      { degree: 'iii', semitone: 4, quality: 'min7', roman: 'iii (Mediant)' },
      { degree: 'IV', semitone: 5, quality: 'maj7', roman: 'IV (Subdominant)' },
      { degree: 'V', semitone: 7, quality: 'dom7', roman: 'V (Dominant)', isDominant: true },
      { degree: 'vi', semitone: 9, quality: 'min7', roman: 'vi (Submediant - Rel. Minor)' },
      { degree: 'vii°', semitone: 11, quality: 'm7b5', roman: 'vii° (Leading Tone)' },
    ];

    return scaleDegrees.map((deg) => {
      const chordRootPitch = (rootPitch + deg.semitone) % 12;
      const chordRootName = formatPitchName(chordRootPitch, preferFlat);
      const chordData = getChordNotes(chordRootName, deg.quality);
      const guitarVoicing = getGuitarChordVoicing(chordRootName, deg.quality);

      return {
        degree: deg.degree,
        root: chordRootName,
        quality: deg.quality,
        fullName: `${chordRootName} ${deg.degree} (${chordData.name})`,
        notes: chordData.notes,
        pianoKeys: chordData.pianoKeys,
        guitarVoicing,
        isDominant: deg.isDominant,
        isTonic: deg.isTonic,
      };
    });
  } else {
    // Minor Key: i (m7), ii° (m7b5), III (Maj7), iv (m7), V (7 - Harmonic), VI (Maj7), VII (7)
    const scaleDegrees = [
      { degree: 'i', semitone: 0, quality: 'min7', roman: 'i (Tonic Minor)', isTonic: true },
      { degree: 'ii°', semitone: 2, quality: 'm7b5', roman: 'ii° (Supertonic)' },
      { degree: 'III', semitone: 3, quality: 'maj7', roman: 'III (Rel. Major)' },
      { degree: 'iv', semitone: 5, quality: 'min7', roman: 'iv (Subdominant)' },
      { degree: 'V', semitone: 7, quality: 'dom7', roman: 'V (Harmonic Dominant)', isDominant: true },
      { degree: 'VI', semitone: 8, quality: 'maj7', roman: 'VI (Submediant)' },
      { degree: 'VII', semitone: 10, quality: 'dom7', roman: 'VII (Subtonic)' },
    ];

    return scaleDegrees.map((deg) => {
      const chordRootPitch = (rootPitch + deg.semitone) % 12;
      const chordRootName = formatPitchName(chordRootPitch, preferFlat);
      const chordData = getChordNotes(chordRootName, deg.quality);
      const guitarVoicing = getGuitarChordVoicing(chordRootName, deg.quality);

      return {
        degree: deg.degree,
        root: chordRootName,
        quality: deg.quality,
        fullName: `${chordRootName} ${deg.degree} (${chordData.name})`,
        notes: chordData.notes,
        pianoKeys: chordData.pianoKeys,
        guitarVoicing,
        isDominant: deg.isDominant,
        isTonic: deg.isTonic,
      };
    });
  }
}
