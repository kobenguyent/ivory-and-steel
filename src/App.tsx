import React, { useState, useMemo } from 'react';
import { Navbar, ActiveTab } from './components/Navbar';
import { Hero } from './components/Hero';
import { TipLibrary } from './components/TipLibrary';
import { InteractivePiano } from './components/InteractivePiano';
import { InteractiveFretboard } from './components/InteractiveFretboard';
import { ChordScaleExplorer } from './components/ChordScaleExplorer';
import { Metronome } from './components/Metronome';
import { PracticeRoutine } from './components/PracticeRoutine';
import { MusicianQuiz } from './components/MusicianQuiz';
import { Footer } from './components/Footer';
import {
  CHROMATIC_ROOTS,
  SCALE_QUALITIES,
  getScaleNotes,
  getGuitarScaleHighlights,
} from './utils/musicTheory';
import { Sparkles, Sliders } from 'lucide-react';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<ActiveTab>('tips');
  const [isIvoryTheme, setIsIvoryTheme] = useState(false);

  // Standalone practice guides across all 12 keys
  const [pianoGuideRoot, setPianoGuideRoot] = useState<string>('none');
  const [pianoGuideScale, setPianoGuideScale] = useState<string>('major');

  const [guitarGuideRoot, setGuitarGuideRoot] = useState<string>('none');
  const [guitarGuideScale, setGuitarGuideScale] = useState<string>('minor_pentatonic');

  const pianoHighlightedNotes = useMemo(() => {
    if (pianoGuideRoot === 'none') return [];
    return getScaleNotes(pianoGuideRoot, pianoGuideScale).pianoKeys;
  }, [pianoGuideRoot, pianoGuideScale]);

  const guitarHighlights = useMemo(() => {
    if (guitarGuideRoot === 'none') return [];
    return getGuitarScaleHighlights(guitarGuideRoot, guitarGuideScale);
  }, [guitarGuideRoot, guitarGuideScale]);

  return (
    <div
      className={`min-h-screen flex flex-col font-sans transition-colors duration-300 ${
        isIvoryTheme
          ? 'bg-[#15171e] text-[#f2efe9]'
          : 'bg-[#0a0c10] text-slate-100'
      }`}
    >
      <Navbar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        isIvoryTheme={isIvoryTheme}
        setIsIvoryTheme={setIsIvoryTheme}
      />

      {/* Hero Header */}
      <Hero setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        {activeTab === 'tips' && <TipLibrary />}

        {activeTab === 'piano' && (
          <div className="space-y-6">
            {/* 12-Key Practice Guide Bar */}
            <div className="p-4 rounded-xl bg-slate-900/80 border border-amber-900/30 flex flex-wrap items-center justify-between gap-3 text-xs">
              <div className="flex items-center gap-2 text-slate-300">
                <Sliders className="w-4 h-4 text-amber-400" />
                <span className="font-bold font-serif text-sm text-slate-100">12-Key Practice Guide:</span>
                <span className="text-slate-400">Light up scale degrees across any key while jamming</span>
              </div>
              <div className="flex items-center gap-2">
                <select
                  data-testid="piano-guide-root"
                  value={pianoGuideRoot}
                  onChange={(e) => setPianoGuideRoot(e.target.value)}
                  className="bg-slate-950 text-amber-300 border border-slate-700 rounded-lg px-3 py-1.5 font-mono text-xs focus:ring-1 focus:ring-amber-400"
                >
                  <option value="none">Guide: Off (Free Play)</option>
                  {CHROMATIC_ROOTS.map((r) => (
                    <option key={r} value={r}>Key of {r}</option>
                  ))}
                </select>

                {pianoGuideRoot !== 'none' && (
                  <select
                    data-testid="piano-guide-scale"
                    value={pianoGuideScale}
                    onChange={(e) => setPianoGuideScale(e.target.value)}
                    className="bg-slate-950 text-slate-200 border border-slate-700 rounded-lg px-3 py-1.5 text-xs focus:ring-1 focus:ring-amber-400"
                  >
                    {SCALE_QUALITIES.map((sq) => (
                      <option key={sq.id} value={sq.id}>{sq.name}</option>
                    ))}
                  </select>
                )}
              </div>
            </div>

            <InteractivePiano
              title="Full Concert Grand Piano (2 Octaves)"
              subtitle={
                pianoGuideRoot !== 'none'
                  ? `Active Scale Guide: ${pianoGuideRoot} ${SCALE_QUALITIES.find(q => q.id === pianoGuideScale)?.name}`
                  : "Use your computer keyboard (A to K keys) or click to play notes. Real-time physical resonance modeled in Web Audio."
              }
              highlightedNotes={pianoHighlightedNotes}
              rootNote={pianoGuideRoot !== 'none' ? pianoGuideRoot : undefined}
              preferFlat={pianoGuideRoot.includes('b') || pianoGuideRoot === 'F'}
            />
            <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 text-sm text-slate-300 space-y-2">
              <h4 className="font-bold text-amber-300 font-serif text-base">
                Keyboard Controls Quick Guide:
              </h4>
              <p>
                • White keys: <span className="font-mono text-amber-400">A, S, D, F, G, H, J, K, L, ;</span>
              </p>
              <p>
                • Black keys (sharps & flats): <span className="font-mono text-amber-400">W, E, T, Y, U, O, P</span>
              </p>
              <p className="text-xs text-slate-400 pt-2">
                Tip: Combine with the Metronome tab to practice 2-octave scales and arpeggios at consistent tempos.
              </p>
            </div>
          </div>
        )}

        {activeTab === 'guitar' && (
          <div className="space-y-6">
            {/* 12-Key Practice Guide Bar */}
            <div className="p-4 rounded-xl bg-slate-900/80 border border-emerald-900/30 flex flex-wrap items-center justify-between gap-3 text-xs">
              <div className="flex items-center gap-2 text-slate-300">
                <Sliders className="w-4 h-4 text-emerald-400" />
                <span className="font-bold font-serif text-sm text-slate-100">12-Key Fretboard Guide:</span>
                <span className="text-slate-400">Highlight scale boxes & root anchors across all 15 frets</span>
              </div>
              <div className="flex items-center gap-2">
                <select
                  data-testid="guitar-guide-root"
                  value={guitarGuideRoot}
                  onChange={(e) => setGuitarGuideRoot(e.target.value)}
                  className="bg-slate-950 text-emerald-300 border border-slate-700 rounded-lg px-3 py-1.5 font-mono text-xs focus:ring-1 focus:ring-emerald-400"
                >
                  <option value="none">Guide: Off (Free Play)</option>
                  {CHROMATIC_ROOTS.map((r) => (
                    <option key={r} value={r}>Key of {r}</option>
                  ))}
                </select>

                {guitarGuideRoot !== 'none' && (
                  <select
                    data-testid="guitar-guide-scale"
                    value={guitarGuideScale}
                    onChange={(e) => setGuitarGuideScale(e.target.value)}
                    className="bg-slate-950 text-slate-200 border border-slate-700 rounded-lg px-3 py-1.5 text-xs focus:ring-1 focus:ring-emerald-400"
                  >
                    {SCALE_QUALITIES.map((sq) => (
                      <option key={sq.id} value={sq.id}>{sq.name}</option>
                    ))}
                  </select>
                )}
              </div>
            </div>

            <InteractiveFretboard
              title="6-String Guitar Fretboard (Frets 0 - 15)"
              subtitle={
                guitarGuideRoot !== 'none'
                  ? `Active Fretboard Guide: ${guitarGuideRoot} ${SCALE_QUALITIES.find(q => q.id === guitarGuideScale)?.name}`
                  : "Standard Tuning (E-A-D-G-B-E). Click any fret to hear the plucked string tone."
              }
              highlights={guitarHighlights}
            />
            <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 text-sm text-slate-300 space-y-2">
              <h4 className="font-bold text-emerald-300 font-serif text-base">
                Fretboard Visual Landmarks:
              </h4>
              <p>
                • Pearloid markers at frets <strong className="text-white">3, 5, 7, 9</strong> and double dot at <strong className="text-amber-400">12 (the octave harmonic center)</strong>.
              </p>
              <p>
                • Nut (0) buttons represent open ringing strings.
              </p>
              <p className="text-xs text-slate-400 pt-2">
                Tip: Practice identifying note names along the 6th string (Low E) and 5th string (A) to anchor your barre chords and pentatonic boxes.
              </p>
            </div>
          </div>
        )}

        {activeTab === 'explorer' && <ChordScaleExplorer />}

        {activeTab === 'metronome' && <Metronome />}

        {activeTab === 'routine' && <PracticeRoutine />}

        {activeTab === 'quiz' && <MusicianQuiz />}
      </main>

      <Footer setActiveTab={setActiveTab} />
    </div>
  );
};

export default App;
