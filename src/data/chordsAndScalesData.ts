import { ChordDefinition, ScaleDefinition } from '../types';

export const CHORDS_DATA: ChordDefinition[] = [
  // --- PIANO CHORDS ---
  {
    root: 'C',
    quality: 'Major',
    name: 'C Major',
    instrument: 'piano',
    notes: ['C4', 'E4', 'G4'],
    intervals: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)'],
    pianoKeys: ['C4', 'E4', 'G4'],
    description: 'The foundation of Western music. Pure, consonant, and bright.'
  },
  {
    root: 'C',
    quality: 'Minor',
    name: 'C Minor',
    instrument: 'piano',
    notes: ['C4', 'D#4', 'G4'],
    intervals: ['Root (1)', 'Minor 3rd (b3)', 'Perfect 5th (5)'],
    pianoKeys: ['C4', 'D#4', 'G4'],
    description: 'Somber, dramatic, and emotionally deep.'
  },
  {
    root: 'C',
    quality: '7th (Dominant)',
    name: 'C Dominant 7th (C7)',
    instrument: 'piano',
    notes: ['C4', 'E4', 'G4', 'A#4'],
    intervals: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)', 'Minor 7th (b7)'],
    pianoKeys: ['C4', 'E4', 'G4', 'A#4'],
    description: 'Bluesy and tense, yearning to resolve to F Major.'
  },
  {
    root: 'C',
    quality: 'Major 7th',
    name: 'C Major 7th (Cmaj7)',
    instrument: 'piano',
    notes: ['C4', 'E4', 'G4', 'B4'],
    intervals: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)', 'Major 7th (7)'],
    pianoKeys: ['C4', 'E4', 'G4', 'B4'],
    description: 'Lush, nostalgic, and dreamy. A staple of jazz and neo-soul.'
  },
  {
    root: 'D',
    quality: 'Minor 7th',
    name: 'D Minor 7th (Dm7)',
    instrument: 'piano',
    notes: ['D4', 'F4', 'A4', 'C5'],
    intervals: ['Root (1)', 'Minor 3rd (b3)', 'Perfect 5th (5)', 'Minor 7th (b7)'],
    pianoKeys: ['D4', 'F4', 'A4', 'C5'],
    description: 'The quintessential ii chord in C major jazz progressions.'
  },
  {
    root: 'G',
    quality: '7th (Dominant)',
    name: 'G Dominant 7th (G7)',
    instrument: 'piano',
    notes: ['G3', 'B3', 'D4', 'F4'],
    intervals: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)', 'Minor 7th (b7)'],
    pianoKeys: ['G3', 'B3', 'D4', 'F4'],
    description: 'The primary dominant V chord in C major.'
  },
  {
    root: 'A',
    quality: 'Minor',
    name: 'A Minor (Am)',
    instrument: 'piano',
    notes: ['A3', 'C4', 'E4'],
    intervals: ['Root (1)', 'Minor 3rd (b3)', 'Perfect 5th (5)'],
    pianoKeys: ['A3', 'C4', 'E4'],
    description: 'The relative minor of C major, classic and melancholic.'
  },
  {
    root: 'F',
    quality: 'Major',
    name: 'F Major',
    instrument: 'piano',
    notes: ['F3', 'A3', 'C4'],
    intervals: ['Root (1)', 'Major 3rd (3)', 'Perfect 5th (5)'],
    pianoKeys: ['F3', 'A3', 'C4'],
    description: 'The IV chord in C major, uplifting and expansive.'
  },

  // --- GUITAR CHORDS ---
  {
    root: 'C',
    quality: 'Major',
    name: 'C Major (Open)',
    instrument: 'guitar',
    notes: ['C3', 'E3', 'G3', 'C4', 'E4'],
    intervals: ['Root (1)', 'Major 3rd (3)', '5th (5)', 'Root (1)', '3rd (3)'],
    guitarFrets: [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 3, finger: '3' },
    ],
    description: 'Classic open chord shape with ringing top E string.'
  },
  {
    root: 'G',
    quality: 'Major',
    name: 'G Major (Open)',
    instrument: 'guitar',
    notes: ['G2', 'B2', 'D3', 'G3', 'D4', 'G4'],
    intervals: ['Root', '3rd', '5th', 'Root', '5th', 'Root'],
    guitarFrets: [
      { stringNum: 1, fret: 3, finger: '4' },
      { stringNum: 2, fret: 3, finger: '3' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 0, finger: 'open' },
      { stringNum: 5, fret: 2, finger: '1' },
      { stringNum: 6, fret: 3, finger: '2' },
    ],
    description: 'The powerful 4-finger rock/folk G chord with ringing high D and G.'
  },
  {
    root: 'D',
    quality: 'Major',
    name: 'D Major (Open)',
    instrument: 'guitar',
    notes: ['D3', 'A3', 'D4', 'F#4'],
    intervals: ['Root', '5th', 'Root', 'Major 3rd'],
    guitarFrets: [
      { stringNum: 1, fret: 2, finger: '2' },
      { stringNum: 2, fret: 3, finger: '3' },
      { stringNum: 3, fret: 2, finger: '1' },
      { stringNum: 4, fret: 0, finger: 'open' },
    ],
    description: 'Bright, triangular open shape across top 4 strings.'
  },
  {
    root: 'E',
    quality: 'Minor',
    name: 'E Minor (Open)',
    instrument: 'guitar',
    notes: ['E2', 'B2', 'E3', 'G3', 'B3', 'E4'],
    intervals: ['Root', '5th', 'Root', 'Minor 3rd', '5th', 'Root'],
    guitarFrets: [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 0, finger: 'open' },
      { stringNum: 3, fret: 0, finger: 'open' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 2, finger: '1' },
      { stringNum: 6, fret: 0, finger: 'open' },
    ],
    description: 'Rich, full 6-string open chord. The easiest and fullest chord on guitar.'
  },
  {
    root: 'A',
    quality: 'Minor',
    name: 'A Minor (Open)',
    instrument: 'guitar',
    notes: ['A2', 'E3', 'A3', 'C4', 'E4'],
    intervals: ['Root', '5th', 'Root', 'Minor 3rd', '5th'],
    guitarFrets: [
      { stringNum: 1, fret: 0, finger: 'open' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 2, finger: '3' },
      { stringNum: 4, fret: 2, finger: '2' },
      { stringNum: 5, fret: 0, finger: 'open' },
    ],
    description: 'Standard open minor chord, identical finger shape to E major shifted down.'
  },
  {
    root: 'F',
    quality: 'Major',
    name: 'F Major (Barre)',
    instrument: 'guitar',
    notes: ['F2', 'C3', 'F3', 'A3', 'C4', 'F4'],
    intervals: ['Root', '5th', 'Root', '3rd', '5th', 'Root'],
    guitarFrets: [
      { stringNum: 1, fret: 1, finger: '1' },
      { stringNum: 2, fret: 1, finger: '1' },
      { stringNum: 3, fret: 2, finger: '2' },
      { stringNum: 4, fret: 3, finger: '4' },
      { stringNum: 5, fret: 3, finger: '3' },
      { stringNum: 6, fret: 1, finger: '1' },
    ],
    description: 'The iconic 1st-fret full barre chord based on the E-shape.'
  },
  {
    root: 'B',
    quality: 'Minor 7th',
    name: 'B Minor 7th (Bm7)',
    instrument: 'guitar',
    notes: ['B2', 'F#3', 'A3', 'D4', 'F#4'],
    intervals: ['Root', '5th', 'b7', 'b3', '5th'],
    guitarFrets: [
      { stringNum: 1, fret: 2, finger: '1' },
      { stringNum: 2, fret: 3, finger: '2' },
      { stringNum: 3, fret: 2, finger: '1' },
      { stringNum: 4, fret: 4, finger: '3' },
      { stringNum: 5, fret: 2, finger: '1' },
    ],
    description: 'A-shape barre chord at the 2nd fret with an open, mellow voice.'
  }
];

export const SCALES_DATA: ScaleDefinition[] = [
  {
    root: 'C',
    quality: 'Major (Ionian)',
    name: 'C Major Scale',
    notes: ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'],
    intervals: ['1', '2', '3', '4', '5', '6', '7', '8'],
    description: 'The mother of all Western scales. Formula: W-W-H-W-W-W-H (Whole & Half steps).',
    pianoKeys: ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'],
    guitarPattern: [
      { stringNum: 6, frets: [8, 10] },
      { stringNum: 5, frets: [7, 8, 10] },
      { stringNum: 4, frets: [7, 9, 10] },
      { stringNum: 3, frets: [7, 9, 10] },
      { stringNum: 2, frets: [8, 10] },
      { stringNum: 1, frets: [7, 8, 10] },
    ]
  },
  {
    root: 'A',
    quality: 'Minor Pentatonic',
    name: 'A Minor Pentatonic',
    notes: ['A3', 'C4', 'D4', 'E4', 'G4', 'A4'],
    intervals: ['1', 'b3', '4', '5', 'b7', '8'],
    description: 'The quintessential rock, blues, and pop soloing scale. Contains zero clashing half-steps.',
    pianoKeys: ['A3', 'C4', 'D4', 'E4', 'G4', 'A4'],
    guitarPattern: [
      { stringNum: 6, frets: [5, 8] },
      { stringNum: 5, frets: [5, 7] },
      { stringNum: 4, frets: [5, 7] },
      { stringNum: 3, frets: [5, 7] },
      { stringNum: 2, frets: [5, 8] },
      { stringNum: 1, frets: [5, 8] },
    ]
  },
  {
    root: 'A',
    quality: 'Blues Scale',
    name: 'A Blues Scale',
    notes: ['A3', 'C4', 'D4', 'D#4', 'E4', 'G4', 'A4'],
    intervals: ['1', 'b3', '4', 'b5 (Blue Note)', '5', 'b7', '8'],
    description: 'Minor pentatonic plus the crying "Blue Note" (flattened 5th / D#4).',
    pianoKeys: ['A3', 'C4', 'D4', 'D#4', 'E4', 'G4', 'A4'],
    guitarPattern: [
      { stringNum: 6, frets: [5, 8] },
      { stringNum: 5, frets: [5, 6, 7] },
      { stringNum: 4, frets: [5, 7] },
      { stringNum: 3, frets: [5, 7, 8] },
      { stringNum: 2, frets: [5, 8] },
      { stringNum: 1, frets: [5, 8] },
    ]
  },
  {
    root: 'D',
    quality: 'Dorian Mode',
    name: 'D Dorian Mode',
    notes: ['D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5', 'D5'],
    intervals: ['1', '2', 'b3', '4', '5', '6 (Characteristic)', 'b7', '8'],
    description: 'The Santana/Kind of Blue sound: minor scale with an uplifting, sweet natural 6th.',
    pianoKeys: ['D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5', 'D5'],
    guitarPattern: [
      { stringNum: 6, frets: [10, 12, 13] },
      { stringNum: 5, frets: [10, 12] },
      { stringNum: 4, frets: [9, 10, 12] },
      { stringNum: 3, frets: [9, 10, 12] },
      { stringNum: 2, frets: [10, 12, 13] },
      { stringNum: 1, frets: [10, 12, 13] },
    ]
  },
  {
    root: 'A',
    quality: 'Harmonic Minor',
    name: 'A Harmonic Minor',
    notes: ['A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G#4', 'A4'],
    intervals: ['1', '2', 'b3', '4', '5', 'b6', '7 (Leading Tone)', '8'],
    description: 'Neoclassical and Spanish flavor with an exotic 1.5-step leap between F and G#.',
    pianoKeys: ['A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G#4', 'A4'],
    guitarPattern: [
      { stringNum: 6, frets: [5, 7, 8] },
      { stringNum: 5, frets: [5, 7, 8] },
      { stringNum: 4, frets: [6, 7] },
      { stringNum: 3, frets: [4, 5, 7] },
      { stringNum: 2, frets: [5, 6] },
      { stringNum: 1, frets: [4, 5, 7, 8] },
    ]
  }
];
