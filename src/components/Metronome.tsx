import React, { useState, useEffect, useRef, useCallback } from 'react';
import { audioEngine } from '../utils/audio';
import { Play, Square, Plus, Minus, Disc, Sliders } from 'lucide-react';

const TEMPO_PRESETS = [
  { name: 'Largo', bpm: 48 },
  { name: 'Adagio', bpm: 66 },
  { name: 'Andante', bpm: 76 },
  { name: 'Moderato', bpm: 108 },
  { name: 'Allegro', bpm: 132 },
  { name: 'Presto', bpm: 168 },
];

export const Metronome: React.FC = () => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [bpm, setBpm] = useState(100);
  const [beatsPerMeasure, setBeatsPerMeasure] = useState(4);
  const [currentBeat, setCurrentBeat] = useState(0);

  // Tap tempo state
  const tapTimesRef = useRef<number[]>([]);
  const timerRef = useRef<number | null>(null);

  const tick = useCallback(() => {
    setCurrentBeat((prev) => {
      const nextBeat = (prev + 1) % beatsPerMeasure;
      const isAccent = nextBeat === 0;
      audioEngine.playMetronomeClick(isAccent);
      return nextBeat;
    });
  }, [beatsPerMeasure]);

  useEffect(() => {
    if (isPlaying) {
      const intervalMs = (60 / bpm) * 1000;
      // Play initial click immediately
      audioEngine.playMetronomeClick(true);
      setCurrentBeat(0);

      timerRef.current = window.setInterval(tick, intervalMs);
    } else {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      setCurrentBeat(0);
    }

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [isPlaying, bpm, tick]);

  const togglePlay = () => {
    setIsPlaying(!isPlaying);
  };

  const handleBpmChange = (newBpm: number) => {
    const clamped = Math.max(30, Math.min(260, newBpm));
    setBpm(clamped);
  };

  const handleTapTempo = () => {
    const now = performance.now();
    const taps = tapTimesRef.current;

    // Reset if last tap was more than 2.5 seconds ago
    if (taps.length > 0 && now - taps[taps.length - 1] > 2500) {
      tapTimesRef.current = [];
    }

    tapTimesRef.current.push(now);

    if (tapTimesRef.current.length > 4) {
      tapTimesRef.current.shift();
    }

    if (tapTimesRef.current.length >= 2) {
      const intervals: number[] = [];
      for (let i = 1; i < tapTimesRef.current.length; i++) {
        intervals.push(tapTimesRef.current[i] - tapTimesRef.current[i - 1]);
      }
      const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
      const calculatedBpm = Math.round(60000 / avgInterval);
      handleBpmChange(calculatedBpm);
    }
  };

  return (
    <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-6 shadow-2xl backdrop-blur-md">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <Disc className={`w-5 h-5 ${isPlaying ? 'text-amber-400 animate-spin' : 'text-slate-400'}`} />
          <h3 className="text-xl font-serif font-bold text-slate-100">Precision Metronome</h3>
        </div>
        <span className="text-xs font-mono px-2.5 py-1 rounded bg-amber-500/10 text-amber-300 border border-amber-500/30">
          Audio Clave / Click
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-center">
        {/* Main BPM Display & Big Play Button */}
        <div className="flex flex-col items-center justify-center bg-slate-950/70 rounded-xl p-5 border border-slate-800">
          <div className="text-6xl font-black font-mono tracking-tighter text-amber-400 flex items-baseline gap-1">
            <span data-testid="metronome-bpm-display">{bpm}</span>
            <span className="text-sm font-sans font-medium text-slate-500 uppercase">BPM</span>
          </div>

          <div className="flex items-center gap-2 mt-4">
            <button
              data-testid="metronome-decrement"
              onClick={() => handleBpmChange(bpm - 5)}
              className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center justify-center font-bold text-sm"
              title="-5 BPM"
            >
              -5
            </button>
            <button
              onClick={() => handleBpmChange(bpm - 1)}
              className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center justify-center font-bold text-sm"
              title="-1 BPM"
            >
              <Minus className="w-4 h-4" />
            </button>
            <button
              onClick={() => handleBpmChange(bpm + 1)}
              className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center justify-center font-bold text-sm"
              title="+1 BPM"
            >
              <Plus className="w-4 h-4" />
            </button>
            <button
              data-testid="metronome-increment"
              onClick={() => handleBpmChange(bpm + 5)}
              className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center justify-center font-bold text-sm"
              title="+5 BPM"
            >
              +5
            </button>
          </div>

          <div className="mt-5 w-full flex gap-3">
            <button
              data-testid="metronome-toggle"
              onClick={togglePlay}
              className={`flex-1 py-3 px-4 rounded-xl font-bold flex items-center justify-center gap-2 shadow-lg transition-all ${
                isPlaying
                  ? 'bg-rose-600 hover:bg-rose-500 text-white shadow-rose-900/30'
                  : 'bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 shadow-amber-900/30 font-extrabold'
              }`}
            >
              {isPlaying ? <Square className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current" />}
              {isPlaying ? 'STOP' : 'START'}
            </button>

            <button
              data-testid="metronome-tap"
              onClick={handleTapTempo}
              className="px-4 py-3 bg-slate-800 hover:bg-slate-700 text-amber-300 font-bold text-xs uppercase tracking-wider rounded-xl border border-slate-700 transition-colors"
            >
              Tap
            </button>
          </div>
        </div>

        {/* Beats Visualizer & Time Signature */}
        <div className="flex flex-col gap-5 bg-slate-950/70 rounded-xl p-5 border border-slate-800">
          <div>
            <label className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-2 block">
              Time Signature
            </label>
            <div className="flex gap-2">
              {[2, 3, 4, 6].map((ts) => (
                <button
                  key={ts}
                  onClick={() => setBeatsPerMeasure(ts)}
                  className={`flex-1 py-1.5 rounded-lg text-sm font-mono font-bold border transition-colors ${
                    beatsPerMeasure === ts
                      ? 'bg-amber-500 text-slate-950 border-amber-400 shadow'
                      : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-slate-200'
                  }`}
                >
                  {ts}/4
                </button>
              ))}
            </div>
          </div>

          {/* Visual Beat Indicator Dots */}
          <div>
            <label className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-2 block">
              Beat Pulse
            </label>
            <div className="flex gap-2 items-center justify-center p-3 bg-slate-900 rounded-lg border border-slate-800">
              {Array.from({ length: beatsPerMeasure }).map((_, idx) => {
                const isActive = isPlaying && currentBeat === idx;
                const isAccent = idx === 0;

                return (
                  <div
                    key={idx}
                    className={`flex-1 h-8 rounded-md flex items-center justify-center font-mono font-bold text-xs transition-all duration-75 ${
                      isActive
                        ? isAccent
                          ? 'bg-amber-400 text-slate-950 scale-105 shadow-lg shadow-amber-500/50 ring-2 ring-white'
                          : 'bg-emerald-400 text-slate-950 scale-105 shadow-md ring-1 ring-white'
                        : 'bg-slate-800 text-slate-500'
                    }`}
                  >
                    {idx + 1}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Slider */}
          <div>
            <div className="flex justify-between text-xs text-slate-400 mb-1">
              <span>30 BPM</span>
              <span className="text-amber-400 font-semibold">{bpm} BPM</span>
              <span>260 BPM</span>
            </div>
            <input
              type="range"
              min="30"
              max="260"
              value={bpm}
              onChange={(e) => handleBpmChange(Number(e.target.value))}
              className="w-full accent-amber-500 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
          </div>
        </div>

        {/* Classical / Modern Tempo Presets */}
        <div className="bg-slate-950/70 rounded-xl p-5 border border-slate-800 flex flex-col justify-between h-full">
          <div>
            <label className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-2 block flex items-center gap-1.5">
              <Sliders className="w-3.5 h-3.5 text-amber-400" />
              Tempo Markings
            </label>
            <div className="grid grid-cols-2 gap-2">
              {TEMPO_PRESETS.map((preset) => (
                <button
                  key={preset.name}
                  onClick={() => handleBpmChange(preset.bpm)}
                  className={`px-3 py-2 rounded-lg text-left text-xs transition-all border ${
                    bpm === preset.bpm
                      ? 'bg-amber-500/20 text-amber-300 border-amber-500/60 font-bold'
                      : 'bg-slate-800/80 text-slate-300 border-slate-700/60 hover:bg-slate-700 hover:text-white'
                  }`}
                >
                  <div className="font-semibold">{preset.name}</div>
                  <div className="text-[10px] text-slate-400 font-mono">{preset.bpm} BPM</div>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-4 pt-3 border-t border-slate-800/80 text-[11px] text-slate-400">
            <span className="text-amber-300 font-medium">Practice tip:</span> For rock/funk pocket, set metronome to half speed and feel clicks on beats 2 & 4.
          </div>
        </div>
      </div>
    </div>
  );
};
