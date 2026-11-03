import { describe, it, expect } from 'vitest';
import { noteToMidi, midiToFrequency, noteToFrequency, audioEngine } from '../utils/audio';

describe('Web Audio Engine & Pitch Mathematics', () => {
  it('converts scientific pitch notation to accurate MIDI numbers', () => {
    expect(noteToMidi('C4')).toBe(60); // Middle C
    expect(noteToMidi('A4')).toBe(69); // Concert pitch A4
    expect(noteToMidi('C#4')).toBe(61);
    expect(noteToMidi('Db4')).toBe(61); // Enharmonic equivalent
    expect(noteToMidi('A3')).toBe(57);
    expect(noteToMidi('E2')).toBe(40); // Guitar low E
    expect(noteToMidi('E4')).toBe(64); // Guitar high E
  });

  it('calculates equal temperament frequencies accurately (A4 = 440 Hz)', () => {
    expect(Math.round(midiToFrequency(69))).toBe(440); // A4
    expect(Math.round(midiToFrequency(57))).toBe(220); // A3
    expect(Math.round(midiToFrequency(81))).toBe(880); // A5
    expect(Math.round(midiToFrequency(60))).toBe(262); // Middle C ~261.63 Hz
  });

  it('converts note names directly to frequency', () => {
    expect(Math.round(noteToFrequency('A4'))).toBe(440);
    expect(Math.round(noteToFrequency('A3'))).toBe(220);
  });

  it('manages audio mute toggle state safely', () => {
    expect(audioEngine.getMuted()).toBe(false);
    audioEngine.setMuted(true);
    expect(audioEngine.getMuted()).toBe(true);
    audioEngine.setMuted(false);
    expect(audioEngine.getMuted()).toBe(false);
  });

  it('executes tone generators without throwing errors', () => {
    expect(() => {
      audioEngine.playPianoNote('C4');
      audioEngine.playGuitarNote('E2');
      audioEngine.playMetronomeClick(true);
      audioEngine.playMetronomeClick(false);
      audioEngine.playChord(['C4', 'E4', 'G4'], 'piano');
      audioEngine.playScale(['C4', 'D4', 'E4'], 'guitar');
    }).not.toThrow();
  });
});
