import React from 'react';
import { Music } from 'lucide-react';
import { ActiveTab } from './Navbar';

interface FooterProps {
  setActiveTab: (tab: ActiveTab) => void;
}

export const Footer: React.FC<FooterProps> = ({ setActiveTab }) => {
  return (
    <footer className="mt-20 border-t border-amber-900/30 bg-[#090b0e] text-slate-400 text-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Brand Info */}
          <div className="space-y-3 md:col-span-1">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-400">
                <Music className="w-4 h-4" />
              </div>
              <span className="font-serif font-black text-lg text-white">Ivory & Steel</span>
            </div>
            <p className="text-slate-400 leading-relaxed text-xs">
              The premier interactive companion for pianists and guitarists. Built by musicians, for musicians, with 100% client-side Web Audio synthesis.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-200 mb-3">
              Interactive Tools
            </h4>
            <ul className="space-y-2">
              <li>
                <button
                  onClick={() => setActiveTab('piano')}
                  className="hover:text-amber-300 transition-colors"
                >
                  Grand Piano Keyboard (Web Audio)
                </button>
              </li>
              <li>
                <button
                  onClick={() => setActiveTab('guitar')}
                  className="hover:text-amber-300 transition-colors"
                >
                  6-String Acoustic Fretboard
                </button>
              </li>
              <li>
                <button
                  onClick={() => setActiveTab('explorer')}
                  className="hover:text-amber-300 transition-colors"
                >
                  Chord & Scale Explorer
                </button>
              </li>
              <li>
                <button
                  onClick={() => setActiveTab('metronome')}
                  className="hover:text-amber-300 transition-colors"
                >
                  Precision Backbeat Metronome
                </button>
              </li>
            </ul>
          </div>

          {/* Practice & Curriculum */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-200 mb-3">
              Learning Curriculum
            </h4>
            <ul className="space-y-2">
              <li>
                <button
                  onClick={() => setActiveTab('tips')}
                  className="hover:text-amber-300 transition-colors"
                >
                  All Tips & Drills Library
                </button>
              </li>
              <li>
                <button
                  onClick={() => setActiveTab('routine')}
                  className="hover:text-amber-300 transition-colors"
                >
                  Deliberate Practice Routine
                </button>
              </li>
              <li>
                <button
                  onClick={() => setActiveTab('quiz')}
                  className="hover:text-amber-300 transition-colors"
                >
                  Musician Skill Level Quiz
                </button>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-12 pt-6 border-t border-slate-800/80 flex flex-col sm:flex-row items-center justify-between gap-4 text-slate-500 text-[11px]">
          <div>
            &copy; {new Date().getFullYear()} Ivory & Steel. Handcrafted with passion for music makers worldwide.
          </div>
          <div className="flex items-center gap-1">
            <span>Play with intention, listen with reverence.</span>
          </div>
        </div>
      </div>
    </footer>
  );
};
