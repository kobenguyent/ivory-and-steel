import { describe, it, expect } from 'vitest';
import {
  CIRCLE_OF_FIFTHS_KEYS,
  CHROMATIC_ROOTS,
  getKeyInfo,
  getScaleNotes,
  getChordNotes,
  getGuitarScaleHighlights,
  getGuitarChordVoicing,
  getDiatonicChords,
  normalizeToPianoKey,
} from '../utils/musicTheory';

describe('Music Theory 12-TET Engine', () => {
  it('covers all 12 keys in the Circle of Fifths with accurate accidentals', () => {
    expect(CIRCLE_OF_FIFTHS_KEYS.length).toBe(12);

    const pitchClasses = new Set(CIRCLE_OF_FIFTHS_KEYS.map((k) => k.pitchClass));
    expect(pitchClasses.size).toBe(12);

    const cKey = getKeyInfo('C');
    expect(cKey.sharpsCount).toBe(0);
    expect(cKey.flatsCount).toBe(0);
    expect(cKey.relativeMinor).toBe('A Minor');

    const ebKey = getKeyInfo('Eb');
    expect(ebKey.flatsCount).toBe(3);
    expect(ebKey.relativeMinor).toBe('C Minor');

    const aKey = getKeyInfo('A');
    expect(aKey.sharpsCount).toBe(3);
    expect(aKey.relativeMinor).toBe('F# Minor');
  });

  it('normalizes flat pitches to virtual piano keys without error', () => {
    expect(normalizeToPianoKey('C4')).toBe('C4');
    expect(normalizeToPianoKey('Eb4')).toBe('D#4');
    expect(normalizeToPianoKey('Bb4')).toBe('A#4');
    expect(normalizeToPianoKey('F#4')).toBe('F#4');
    expect(normalizeToPianoKey('Ab5')).toBe('G#5');
  });

  it('generates scales across any key center correctly', () => {
    // C Major Scale
    const cMajor = getScaleNotes('C', 'major');
    expect(cMajor.notes.length).toBe(8); // 7 degrees + octave root
    expect(cMajor.pianoKeys[0]).toBe('C4');
    expect(cMajor.pianoKeys[7]).toBe('C5');

    // Eb Minor Pentatonic
    const ebPentatonic = getScaleNotes('Eb', 'minor_pentatonic');
    expect(ebPentatonic.notes.length).toBe(6); // 5 notes + octave
    expect(ebPentatonic.notes[0]).toBe('Eb4');

    // F# Blues Scale
    const fSharpBlues = getScaleNotes('F#', 'blues');
    expect(fSharpBlues.notes.length).toBe(7); // 6 notes + octave
  });

  it('generates chords for any root note with valid piano voicings', () => {
    const gDom7 = getChordNotes('G', 'dom7');
    expect(gDom7.name).toContain('G Dominant 7th');
    expect(gDom7.notes.length).toBe(4);
    expect(gDom7.pianoKeys.length).toBe(4);

    const ebMaj7 = getChordNotes('Eb', 'maj7');
    expect(ebMaj7.notes.length).toBe(4);
    expect(ebMaj7.pianoKeys[0]).toBe('D#4'); // Eb4 normalized to D#4 on piano
  });

  it('generates complete 7-chord diatonic harmonization for Major and Minor keys', () => {
    const cMajorDiatonic = getDiatonicChords('C', 'major');
    expect(cMajorDiatonic.length).toBe(7);
    expect(cMajorDiatonic[0].degree).toBe('I');
    expect(cMajorDiatonic[0].root).toBe('C');
    expect(cMajorDiatonic[3].degree).toBe('IV');
    expect(cMajorDiatonic[4].degree).toBe('V');
    expect(cMajorDiatonic[4].isDominant).toBe(true);

    const aMinorDiatonic = getDiatonicChords('A', 'minor');
    expect(aMinorDiatonic.length).toBe(7);
    expect(aMinorDiatonic[0].degree).toBe('i');
    expect(aMinorDiatonic[0].root).toBe('A');
    expect(aMinorDiatonic[2].degree).toBe('III');
  });

  it('calculates guitar fret highlights bounded within frets 0-15 and strings 1-6', () => {
    const highlights = getGuitarScaleHighlights('A', 'minor_pentatonic');
    expect(highlights.length).toBeGreaterThan(15);

    highlights.forEach((h) => {
      expect(h.stringNum).toBeGreaterThanOrEqual(1);
      expect(h.stringNum).toBeLessThanOrEqual(6);
      expect(h.fret).toBeGreaterThanOrEqual(0);
      expect(h.fret).toBeLessThanOrEqual(15);
    });

    const rootHits = highlights.filter((h) => h.isRoot);
    expect(rootHits.length).toBeGreaterThanOrEqual(3);
  });

  it('provides playable guitar chord voicings across open and barre positions', () => {
    const openG = getGuitarChordVoicing('G', 'major');
    expect(openG.length).toBeGreaterThanOrEqual(4);
    expect(openG.some((f) => f.fret === 0)).toBe(true);

    const barreF = getGuitarChordVoicing('F', 'major');
    expect(barreF.length).toBe(6);
    expect(barreF.every((f) => f.fret >= 1)).toBe(true);
  });
});

