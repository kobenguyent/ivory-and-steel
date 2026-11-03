import { QuizQuestion } from '../types';

export const QUIZ_QUESTIONS: QuizQuestion[] = [
  // --- PIANO QUESTIONS ---
  {
    id: 'quiz-p-1',
    instrument: 'piano',
    level: 'beginner',
    question: 'When striking piano keys, which knuckle joint should you strictly prevent from collapsing backward?',
    options: [
      'The wrist joint',
      'The distal joint (the knuckle closest to your fingernail)',
      'The thumb carpometacarpal joint',
      'The shoulder socket'
    ],
    correctIndex: 1,
    explanation: 'Collapsing the distal knuckle (fingertip joint) prevents weight transfer and can cause long-term strain. Keep knuckles gently curved outward.',
    relatedTipId: 'piano-beg-01'
  },
  {
    id: 'quiz-p-2',
    instrument: 'piano',
    level: 'beginner',
    question: 'What is the correct timing for "syncopated pedaling" on piano?',
    options: [
      'Press the pedal down 2 beats before playing the chord',
      'Press the pedal down at the exact millisecond the fingers strike the keys',
      'Strike the new chord first, then quickly lift and re-press the pedal while keys are still held',
      'Hold the pedal down continuously throughout the entire piece'
    ],
    correctIndex: 2,
    explanation: 'Syncopated pedaling (late pedaling) clears the previous harmony while the keys physically sustain the new chord, preventing muddy bleed.',
    relatedTipId: 'piano-beg-05'
  },
  {
    id: 'quiz-p-3',
    instrument: 'piano',
    level: 'intermediate',
    question: 'In a jazz ii-V-I progression in C major (Dm7 -> G7 -> Cmaj7), what does the 7th of Dm7 (note C) resolve down to in the G7 chord?',
    options: [
      'The root G',
      'The 5th D',
      'The 3rd B',
      'The 9th A'
    ],
    correctIndex: 2,
    explanation: 'In smooth jazz voice leading, the 7th of the ii chord (C) steps down a half step to become the 3rd of the V7 chord (B).',
    relatedTipId: 'piano-int-02'
  },
  {
    id: 'quiz-p-4',
    instrument: 'piano',
    level: 'intermediate',
    question: 'What is the rhythmic subdivision composite for playing a 3:2 polyrhythm?',
    options: [
      'Both -> Triple -> Duple -> Triple ("Not Dif-fi-cult")',
      'Both -> Duple -> Duple -> Triple',
      'Triple -> Triple -> Duple -> Both',
      'Duple -> Triple -> Both -> Rest'
    ],
    correctIndex: 0,
    explanation: 'A 3 against 2 polyrhythm creates a composite pattern of: Both together, then triplet note, then duplet note, then triplet note.',
    relatedTipId: 'piano-int-04'
  },
  {
    id: 'quiz-p-5',
    instrument: 'piano',
    level: 'advanced',
    question: 'In Bill Evans-style rootless voicings, which notes are typically omitted by the pianist?',
    options: [
      'The 3rd and 7th',
      'The Root and the 5th',
      'The 9th and 13th',
      'The melody notes'
    ],
    correctIndex: 1,
    explanation: 'The bass player covers the root, and the pure 5th provides no harmonic color. Removing them frees fingers for extensions like 9ths and 13ths.',
    relatedTipId: 'piano-adv-01'
  },
  {
    id: 'quiz-p-6',
    instrument: 'piano',
    level: 'mastery',
    question: 'What is the physical mechanism behind "half-pedaling" on an acoustic grand piano?',
    options: [
      'Pressing the middle sostenuto pedal instead of the sustain pedal',
      'Depressing the pedal halfway so dampers lightly skim treble strings to silence clutter while heavy bass strings continue ringing',
      'Playing with the left soft pedal locked down permanently',
      'Pumping the pedal on every sixteenth note'
    ],
    correctIndex: 1,
    explanation: 'Grand piano dampers on treble strings are lighter than bass dampers. Micro-pedal depth dampens treble dissonance while letting deep bass fundamentals sing.',
    relatedTipId: 'piano-mst-01'
  },

  // --- GUITAR QUESTIONS ---
  {
    id: 'quiz-g-1',
    instrument: 'guitar',
    level: 'beginner',
    question: 'Where should your fretting fingertip be placed to eliminate fret buzz with minimal pressure?',
    options: [
      'Directly on top of the metal fret wire',
      'In the exact center between two fret wires',
      'Right behind the metal fret wire (towards the headstock edge)',
      'Close to the bridge saddles'
    ],
    correctIndex: 2,
    explanation: 'Placing your fingertip right behind the fret wire provides the cleanest mechanical leverage, stopping buzz with light pressure.',
    relatedTipId: 'gtr-beg-01'
  },
  {
    id: 'quiz-g-2',
    instrument: 'guitar',
    level: 'beginner',
    question: 'When transitioning between G, Cadd9, and D chords, which finger serves as the stationary anchor finger on fret 3?',
    options: [
      'Index finger on G string',
      'Ring finger on B string',
      'Fretting thumb',
      'Pinky on Low E'
    ],
    correctIndex: 1,
    explanation: 'Your ring finger remains anchored on the 3rd fret of the B string, acting as a geometric pivot for lightning-fast transitions.',
    relatedTipId: 'gtr-beg-02'
  },
  {
    id: 'quiz-g-3',
    instrument: 'guitar',
    level: 'intermediate',
    question: 'What body mechanic should power the F-major barre chord to avoid burning thumb fatigue?',
    options: [
      'Pinching the neck as hard as humanly possible with the thumb pad',
      'Pulling back slightly from the left shoulder and arm using guitar body leverage',
      'Resting your elbow on your knee',
      'Fretting with the soft palm pad'
    ],
    correctIndex: 1,
    explanation: 'Leverage from the shoulder and arm weight pulls the strings onto the frets, allowing the thumb to remain relaxed with zero pinch strain.',
    relatedTipId: 'gtr-int-01'
  },
  {
    id: 'quiz-g-4',
    instrument: 'guitar',
    level: 'intermediate',
    question: 'What is the characteristic color tone that distinguishes the Dorian mode from the standard Natural Minor (Aeolian) scale?',
    options: [
      'The Flattened 2nd (b2)',
      'The Natural (Raised) 6th',
      'The Diminished 5th (b5)',
      'The Major 3rd'
    ],
    correctIndex: 1,
    explanation: 'Dorian contains a natural 6th (e.g., B natural in D Dorian), which gives it that signature bright, jazzy, Santana minor sound.',
    relatedTipId: 'gtr-adv-03'
  },
  {
    id: 'quiz-g-5',
    instrument: 'guitar',
    level: 'advanced',
    question: 'In sweep picking, what is the most critical factor preventing notes from bleeding into a messy chord strum?',
    options: [
      'Picking as loudly as possible with a thick pick',
      'Fretting-hand micro-muting (rolling pressure release as soon as the note is struck)',
      'Using high action on your guitar neck',
      'Keeping your right palm completely off the bridge'
    ],
    correctIndex: 1,
    explanation: 'Sweep picking requires each finger to release pressure the instant the next string is picked so only one note rings at any given instant.',
    relatedTipId: 'gtr-adv-02'
  },
  {
    id: 'quiz-g-6',
    instrument: 'guitar',
    level: 'mastery',
    question: 'How did Allan Holdsworth approach fretting hand mechanics for his liquid legato velocity?',
    options: [
      'Heavy blunt force tapping with stiff forearm muscles',
      'Ultra-light hammer-ons from nowhere with minimal finger lift (<3mm) and low action',
      'Picking every single note with aggressive alternate downstrokes',
      'Resting the guitar neck flat on his lap'
    ],
    correctIndex: 1,
    explanation: 'Holdsworth used low action, light gauge strings, and minimal finger motion with rapid finger snap and immediate release for violin-like fluid runs.',
    relatedTipId: 'gtr-mst-01'
  }
];
