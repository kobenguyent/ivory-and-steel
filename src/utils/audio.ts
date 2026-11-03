// Web Audio API engine for Piano, Guitar, and Metronome synthesis

const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

const ENHARMONIC_MAP: Record<string, string> = {
  'DB': 'C#',
  'EB': 'D#',
  'GB': 'F#',
  'AB': 'G#',
  'BB': 'A#',
  'E#': 'F',
  'B#': 'C',
  'CB': 'B',
};

/**
 * Convert standard scientific pitch notation (e.g. "C4", "F#3", "Bb5") to MIDI note number
 */
export function noteToMidi(noteStr: string): number {
  const match = noteStr.trim().match(/^([A-Ga-g][b#]?)(-?\d+)$/);
  if (!match) return 60; // Default to Middle C (C4)

  let note = match[1].toUpperCase();
  const octave = parseInt(match[2], 10);

  if (ENHARMONIC_MAP[note]) {
    note = ENHARMONIC_MAP[note];
  }

  const noteIndex = NOTE_NAMES.indexOf(note);
  if (noteIndex === -1) return 60;

  // MIDI note 60 is C4 (octave 4, index 0 -> (4 + 1) * 12 + 0 = 60)
  return (octave + 1) * 12 + noteIndex;
}

/**
 * Convert MIDI note number to frequency in Hertz (A4 = 440Hz)
 */
export function midiToFrequency(midi: number): number {
  return 440 * Math.pow(2, (midi - 69) / 12);
}

/**
 * Convert note name to frequency in Hertz
 */
export function noteToFrequency(noteStr: string): number {
  return midiToFrequency(noteToMidi(noteStr));
}

class SoundEngine {
  private ctx: AudioContext | null = null;
  private isMuted: boolean = false;

  private getContext(): AudioContext {
    if (!this.ctx) {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioContextClass();
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
    return this.ctx;
  }

  public setMuted(muted: boolean) {
    this.isMuted = muted;
  }

  public getMuted(): boolean {
    return this.isMuted;
  }

  /**
   * Play an acoustic piano tone with harmonic richness and realistic decay
   */
  public playPianoNote(noteStr: string, duration = 1.6, velocity = 0.8) {
    if (this.isMuted) return;
    try {
      const ctx = this.getContext();
      const freq = noteToFrequency(noteStr);
      const now = ctx.currentTime;

      // Master gain for this note
      const masterGain = ctx.createGain();
      masterGain.gain.setValueAtTime(0.0001, now);
      masterGain.gain.linearRampToValueAtTime(velocity * 0.45, now + 0.008); // Crisp attack
      masterGain.gain.exponentialRampToValueAtTime(velocity * 0.18, now + 0.25);
      masterGain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

      // Lowpass filter for natural acoustic dampening
      const filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(Math.min(freq * 6, 8000), now);
      filter.frequency.exponentialRampToValueAtTime(Math.min(freq * 2, 2500), now + duration);

      masterGain.connect(filter);
      filter.connect(ctx.destination);

      // Fundamental and harmonic overtones (1x, 2x, 3x, 4x)
      const harmonics = [
        { mult: 1, gain: 0.6, type: 'sine' as OscillatorType },
        { mult: 2, gain: 0.25, type: 'sine' as OscillatorType },
        { mult: 3, gain: 0.1, type: 'triangle' as OscillatorType },
        { mult: 4, gain: 0.05, type: 'sine' as OscillatorType },
      ];

      harmonics.forEach(h => {
        const osc = ctx.createOscillator();
        osc.type = h.type;
        osc.frequency.setValueAtTime(freq * h.mult, now);

        const hGain = ctx.createGain();
        hGain.gain.setValueAtTime(h.gain, now);

        osc.connect(hGain);
        hGain.connect(masterGain);

        osc.start(now);
        osc.stop(now + duration + 0.05);
      });
    } catch {
      // Audio fallback in non-supported environments
    }
  }

  /**
   * Play an acoustic guitar plucked string tone
   */
  public playGuitarNote(noteStr: string, duration = 1.8, velocity = 0.85) {
    if (this.isMuted) return;
    try {
      const ctx = this.getContext();
      const freq = noteToFrequency(noteStr);
      const now = ctx.currentTime;

      const masterGain = ctx.createGain();
      // Fast plucking attack
      masterGain.gain.setValueAtTime(0.0001, now);
      masterGain.gain.linearRampToValueAtTime(velocity * 0.5, now + 0.004);
      masterGain.gain.exponentialRampToValueAtTime(velocity * 0.22, now + 0.15);
      masterGain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

      // Body acoustic filter
      const filter = ctx.createBiquadFilter();
      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(freq * 1.5, now);
      filter.Q.value = 1.2;

      const lowpass = ctx.createBiquadFilter();
      lowpass.type = 'lowpass';
      lowpass.frequency.setValueAtTime(5000, now);
      lowpass.frequency.exponentialRampToValueAtTime(600, now + duration);

      masterGain.connect(filter);
      masterGain.connect(lowpass);
      filter.connect(ctx.destination);
      lowpass.connect(ctx.destination);

      // Pluck combination: triangle for woody pluck + saw for string metallic edge
      const osc1 = ctx.createOscillator();
      osc1.type = 'triangle';
      osc1.frequency.setValueAtTime(freq, now);

      const osc2 = ctx.createOscillator();
      osc2.type = 'sawtooth';
      osc2.frequency.setValueAtTime(freq, now);

      const osc2Gain = ctx.createGain();
      osc2Gain.gain.setValueAtTime(0.18, now);
      osc2Gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08); // String ping dies quickly

      osc1.connect(masterGain);
      osc2.connect(osc2Gain);
      osc2Gain.connect(masterGain);

      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + duration + 0.05);
      osc2.stop(now + duration + 0.05);
    } catch {
      // Audio fallback
    }
  }

  /**
   * Play metronome click (high click on beat 1, lower woodblock click on other beats)
   */
  public playMetronomeClick(isAccent = false) {
    if (this.isMuted) return;
    try {
      const ctx = this.getContext();
      const now = ctx.currentTime;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      const baseFreq = isAccent ? 1600 : 1000;
      osc.type = 'sine';
      osc.frequency.setValueAtTime(baseFreq, now);
      osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.4, now + 0.04);

      gain.gain.setValueAtTime(isAccent ? 0.8 : 0.45, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.045);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.05);
    } catch {
      // Audio fallback
    }
  }

  /**
   * Play a chord as an arpeggiated strum or simultaneous notes
   */
  public playChord(
    notes: string[],
    instrument: 'piano' | 'guitar' = 'piano',
    strumInterval = 0.045
  ) {
    if (this.isMuted) return;
    notes.forEach((note, index) => {
      setTimeout(() => {
        if (instrument === 'piano') {
          this.playPianoNote(note, 2.2, 0.7);
        } else {
          this.playGuitarNote(note, 2.0, 0.75);
        }
      }, index * (strumInterval * 1000));
    });
  }

  /**
   * Play a musical scale in sequence
   */
  public playScale(
    notes: string[],
    instrument: 'piano' | 'guitar' = 'piano',
    noteDurationMs = 280
  ) {
    if (this.isMuted) return;
    notes.forEach((note, index) => {
      setTimeout(() => {
        if (instrument === 'piano') {
          this.playPianoNote(note, 0.8, 0.75);
        } else {
          this.playGuitarNote(note, 0.8, 0.8);
        }
      }, index * noteDurationMs);
    });
  }
}

export const audioEngine = new SoundEngine();
