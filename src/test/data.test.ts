import { describe, it, expect } from 'vitest';
import { TIPS_DATA } from '../data/tipsData';
import { CHORDS_DATA, SCALES_DATA } from '../data/chordsAndScalesData';
import { QUIZ_QUESTIONS } from '../data/quizData';

describe('Musician Curriculum Data Integrity', () => {
  it('covers all 4 difficulty levels: beginner, intermediate, advanced, mastery', () => {
    const levels = new Set(TIPS_DATA.map((t) => t.level));
    expect(levels.has('beginner')).toBe(true);
    expect(levels.has('intermediate')).toBe(true);
    expect(levels.has('advanced')).toBe(true);
    expect(levels.has('mastery')).toBe(true);
  });

  it('covers piano, guitar, and universal instrument categories', () => {
    const instruments = new Set(TIPS_DATA.map((t) => t.instrument));
    expect(instruments.has('piano')).toBe(true);
    expect(instruments.has('guitar')).toBe(true);
    expect(instruments.has('both')).toBe(true);
  });

  it('ensures every tip includes practical exercises and pro secrets', () => {
    TIPS_DATA.forEach((tip) => {
      expect(tip.title).toBeTruthy();
      expect(tip.summary).toBeTruthy();
      expect(tip.detailedExplanation.length).toBeGreaterThan(50);
      expect(tip.practicalExercise.title).toBeTruthy();
      expect(tip.practicalExercise.steps.length).toBeGreaterThanOrEqual(3);
      expect(tip.proSecret.length).toBeGreaterThan(10);
      expect(tip.commonMistake.length).toBeGreaterThan(10);
      expect(tip.tags.length).toBeGreaterThanOrEqual(2);
    });
  });

  it('provides valid chords and scales definitions', () => {
    expect(CHORDS_DATA.length).toBeGreaterThanOrEqual(8);
    expect(SCALES_DATA.length).toBeGreaterThanOrEqual(4);

    CHORDS_DATA.forEach((chord) => {
      expect(chord.name).toBeTruthy();
      expect(chord.notes.length).toBeGreaterThanOrEqual(3);
      expect(chord.intervals.length).toBeGreaterThanOrEqual(3);
    });

    SCALES_DATA.forEach((scale) => {
      expect(scale.name).toBeTruthy();
      expect(scale.notes.length).toBeGreaterThanOrEqual(5);
    });
  });

  it('validates quiz questions structure and option bounds', () => {
    expect(QUIZ_QUESTIONS.length).toBeGreaterThanOrEqual(10);
    QUIZ_QUESTIONS.forEach((q) => {
      expect(q.options.length).toBeGreaterThanOrEqual(4);
      expect(q.correctIndex).toBeGreaterThanOrEqual(0);
      expect(q.correctIndex).toBeLessThan(q.options.length);
      expect(q.explanation.length).toBeGreaterThan(15);
    });
  });
});
