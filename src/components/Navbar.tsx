import React, { useState } from 'react';
import { Volume2, VolumeX, Sun, Moon, Music } from 'lucide-react';
import { audioEngine } from '../utils/audio';

export type ActiveTab = 'tips' | 'piano' | 'guitar' | 'explorer' | 'metronome' | 'routine' | 'quiz';

interface NavbarProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  isIvoryTheme: boolean;
  setIsIvoryTheme: (val: boolean) => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  activeTab,
  setActiveTab,
  isIvoryTheme,
  setIsIvoryTheme,
}) => {
  const [isMuted, setIsMuted] = useState(false);

  const toggleMute = () => {
    const next = !isMuted;
    setIsMuted(next);
    audioEngine.setMuted(next);
  };

  const navLinks: { id: ActiveTab; label: string }[] = [
    { id: 'tips', label: 'Master Tips' },
    { id: 'piano', label: 'Virtual Piano' },
    { id: 'guitar', label: 'Guitar Fretboard' },
    { id: 'explorer', label: 'Chord & Scales' },
    { id: 'metronome', label: 'Metronome' },
    { id: 'routine', label: 'Practice Routine' },
    { id: 'quiz', label: 'Level Quiz' },
  ];

  return (
    <header className="sticky top-0 z-50 backdrop-blur-xl bg-[#0c0e12]/85 border-b border-amber-900/40">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Brand Logo & Catchy Fancy Name */}
          <div
            onClick={() => setActiveTab('tips')}
            className="flex items-center gap-3 cursor-pointer group"
          >
            <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-amber-400 via-amber-600 to-amber-800 p-0.5 shadow-lg shadow-amber-900/30 group-hover:scale-105 transition-transform">
              <div className="w-full h-full bg-[#0e1118] rounded-[10px] flex items-center justify-center">
                <Music className="w-6 h-6 text-amber-400 group-hover:rotate-12 transition-transform" />
              </div>
            </div>

            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-serif font-black text-2xl tracking-tight text-white group-hover:text-amber-300 transition-colors">
                  Ivory & Steel
                </span>
                <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-300 border border-amber-500/40 uppercase">
                  Pro
                </span>
              </div>
              <p className="text-[11px] font-medium text-slate-400 tracking-wide">
                Piano & Guitar Masterclass • Beginner to Virtuoso
              </p>
            </div>
          </div>

          {/* Navigation Links (Desktop) */}
          <nav className="hidden lg:flex items-center gap-1 bg-slate-950/60 p-1 rounded-xl border border-slate-800/80">
            {navLinks.map((link) => (
              <button
                key={link.id}
                data-testid={`nav-${link.id}`}
                onClick={() => setActiveTab(link.id)}
                className={`px-3.5 py-2 rounded-lg text-xs font-bold transition-all ${
                  activeTab === link.id
                    ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-950/30'
                    : 'text-slate-300 hover:text-white hover:bg-slate-800/60'
                }`}
              >
                {link.label}
              </button>
            ))}
          </nav>

          {/* Right Action Controls */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Audio Mute/Unmute */}
            <button
              data-testid="audio-mute-toggle"
              onClick={toggleMute}
              className={`p-2.5 rounded-xl border text-xs font-bold flex items-center gap-1.5 transition-all ${
                isMuted
                  ? 'bg-rose-950/30 text-rose-400 border-rose-800/40 hover:bg-rose-950/50'
                  : 'bg-slate-800/80 text-amber-300 border-amber-500/30 hover:bg-slate-700'
              }`}
              title={isMuted ? 'Unmute Web Audio' : 'Mute Web Audio'}
            >
              {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
              <span className="hidden sm:inline">{isMuted ? 'Muted' : 'Sound ON'}</span>
            </button>

            {/* Theme Toggle (Dark vs Ivory Classic) */}
            <button
              data-testid="theme-toggle"
              onClick={() => setIsIvoryTheme(!isIvoryTheme)}
              className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700 text-slate-300 hover:text-white hover:bg-slate-700 transition-all"
              title="Toggle Color Theme"
            >
              {isIvoryTheme ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-slate-400" />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation Scrollbar */}
        <div className="lg:hidden flex gap-2 overflow-x-auto py-2.5 border-t border-slate-800/60 scrollbar-none">
          {navLinks.map((link) => (
            <button
              key={link.id}
              onClick={() => setActiveTab(link.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-all border ${
                activeTab === link.id
                  ? 'bg-amber-500 text-slate-950 border-amber-400 shadow'
                  : 'bg-slate-900 text-slate-300 border-slate-800'
              }`}
            >
              {link.label}
            </button>
          ))}
        </div>
      </div>
    </header>
  );
};
