import React, { useState } from 'react';
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

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<ActiveTab>('tips');
  const [isIvoryTheme, setIsIvoryTheme] = useState(false);

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
          <div className="space-y-8">
            <InteractivePiano
              title="Full Concert Grand Piano (2 Octaves)"
              subtitle="Use your computer keyboard (A to K keys) or click to play notes. Real-time physical resonance modeled in Web Audio."
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
          <div className="space-y-8">
            <InteractiveFretboard
              title="6-String Guitar Fretboard (Frets 0 - 15)"
              subtitle="Standard Tuning (E-A-D-G-B-E). Click any fret to hear the plucked string tone."
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
