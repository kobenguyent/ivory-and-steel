export type Instrument = 'piano' | 'guitar' | 'both';

export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced' | 'mastery';

export type TipCategory =
  | 'technique'
  | 'theory'
  | 'practice'
  | 'tone'
  | 'ergonomics'
  | 'repertoire';

export interface Tip {
  id: string;
  slug: string;
  title: string;
  instrument: Instrument;
  level: DifficultyLevel;
  category: TipCategory;
  summary: string;
  detailedExplanation: string;
  practicalExercise: {
    title: string;
    steps: string[];
    tempoBpm?: number;
    recommendedDurationMinutes?: number;
  };
  proSecret: string;
  commonMistake: string;
  musicalExample?: {
    type: 'tab' | 'notes' | 'chord_progression' | 'fingering';
    content: string;
    caption: string;
    interactiveNotes?: string[];
  };
  tags: string[];
}

export interface ChordDefinition {
  root: string;
  quality: string;
  name: string;
  instrument: 'piano' | 'guitar';
  notes: string[]; // e.g. ["C4", "E4", "G4"]
  intervals: string[]; // e.g. ["R", "3", "5"]
  pianoKeys?: string[]; // keys to highlight e.g. ["C4", "E4", "G4"]
  guitarFrets?: { stringNum: number; fret: number; finger?: string }[]; // strings 1 (high E) to 6 (low E)
  description: string;
}

export interface ScaleDefinition {
  root: string;
  quality: string;
  name: string;
  notes: string[];
  intervals: string[];
  description: string;
  pianoKeys?: string[];
  guitarPattern?: { stringNum: number; frets: number[] }[];
}

export interface PracticeRoutineBlock {
  id: string;
  title: string;
  category: TipCategory;
  durationMinutes: number;
  description: string;
  instrument: Instrument;
  targetLevel: DifficultyLevel;
  recommendedBpm?: number;
}

export interface QuizQuestion {
  id: string;
  instrument: 'piano' | 'guitar';
  level: DifficultyLevel;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  relatedTipId?: string;
}
