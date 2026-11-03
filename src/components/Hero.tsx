import React from 'react';
import { ActiveTab } from './Navbar';
import { Sparkles, Music, Play, Layers, HelpCircle } from 'lucide-react';

interface HeroProps {
  setActiveTab: (tab: ActiveTab) => void;
}

export const Hero: React.FC<HeroProps> = ({ setActiveTab }) => {
  return (
    <div className="relative overflow-hidden pt-8 pb-12 sm:pt-14 sm:pb-16 border-b border-amber-900/30">
      {/* Background Decorative Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-gradient-to-tr from-amber-500/10 via-amber-700/10 to-transparent blur-3xl pointer-events-none rounded-full" />

      <div className="max-w-5xl mx-auto px-4 text-center relative z-10">
        {/* Sub-badge */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs font-semibold mb-6 shadow-sm">
          <Sparkles className="w-3.5 h-3.5" />
          <span>The Musician's Masterclass & Interactive Toolkit</span>
        </div>

        {/* Fancy Catchy Title */}
        <h1 className="text-4xl sm:text-6xl lg:text-7xl font-serif font-black tracking-tight text-white leading-tight">
          Master the <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600">Ivory</span>.
          <br className="hidden sm:inline" /> Conquer the <span className="text-transparent bg-clip-text bg-gradient-to-r from-slate-200 via-slate-400 to-amber-200">Steel</span>.
        </h1>

        {/* Narrative Description */}
        <p className="mt-5 text-base sm:text-lg text-slate-300 max-w-3xl mx-auto leading-relaxed">
          From the foundational "curved dome" hand posture and anchor chord transitions, all the way to Bill Evans rootless voicings, Allan Holdsworth legato, and concert hall rubato. Everything you need to transcend your musical plateau.
        </p>

        {/* Action Buttons */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <button
            data-testid="hero-explore-tips"
            onClick={() => setActiveTab('tips')}
            className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-extrabold text-sm uppercase tracking-wider flex items-center gap-2 shadow-xl shadow-amber-950/50 hover:scale-[1.02] transition-all"
          >
            <Music className="w-4 h-4 fill-current" />
            Explore All Tips & Drills
          </button>

          <button
            data-testid="hero-open-piano"
            onClick={() => setActiveTab('piano')}
            className="px-5 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-100 font-bold text-sm border border-slate-700 hover:border-amber-500/40 flex items-center gap-2 transition-all"
          >
            <Play className="w-4 h-4 text-amber-400" />
            Interactive Piano
          </button>

          <button
            data-testid="hero-open-guitar"
            onClick={() => setActiveTab('guitar')}
            className="px-5 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-100 font-bold text-sm border border-slate-700 hover:border-amber-500/40 flex items-center gap-2 transition-all"
          >
            <Layers className="w-4 h-4 text-emerald-400" />
            Guitar Fretboard
          </button>

          <button
            data-testid="hero-open-quiz"
            onClick={() => setActiveTab('quiz')}
            className="px-5 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-100 font-bold text-sm border border-slate-700 hover:border-amber-500/40 flex items-center gap-2 transition-all"
          >
            <HelpCircle className="w-4 h-4 text-purple-400" />
            Level Quiz
          </button>
        </div>

        {/* Highlights Bar */}
        <div className="mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 max-w-4xl mx-auto pt-8 border-t border-slate-800/80">
          <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800/60">
            <div className="text-xl font-bold font-mono text-amber-400">4 Tiers</div>
            <div className="text-xs text-slate-400 mt-0.5">Beginner to Virtuoso</div>
          </div>
          <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800/60">
            <div className="text-xl font-bold font-mono text-emerald-400">Web Audio</div>
            <div className="text-xs text-slate-400 mt-0.5">100% Real Synthesis</div>
          </div>
          <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800/60">
            <div className="text-xl font-bold font-mono text-cyan-400">Interactive</div>
            <div className="text-xs text-slate-400 mt-0.5">Keys, Fretboard & Click</div>
          </div>
          <div className="p-3 rounded-xl bg-slate-950/40 border border-slate-800/60">
            <div className="text-xl font-bold font-mono text-purple-400">Zero Server</div>
            <div className="text-xs text-slate-400 mt-0.5">GitHub Pages Ready</div>
          </div>
        </div>
      </div>
    </div>
  );
};
