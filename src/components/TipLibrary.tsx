import React, { useState, useEffect, useMemo } from 'react';
import { Instrument, DifficultyLevel, TipCategory } from '../types';
import { TIPS_DATA } from '../data/tipsData';
import {
  Search,
  Bookmark,
  BookmarkCheck,
  BookOpen,
  CheckCircle2,
  AlertTriangle,
  Lightbulb,
  Music,
  Shuffle,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';

const LEVEL_COLORS: Record<DifficultyLevel, { badge: string; text: string; border: string }> = {
  beginner: {
    badge: 'bg-emerald-500/15',
    text: 'text-emerald-400',
    border: 'border-emerald-500/30',
  },
  intermediate: {
    badge: 'bg-cyan-500/15',
    text: 'text-cyan-400',
    border: 'border-cyan-500/30',
  },
  advanced: {
    badge: 'bg-violet-500/15',
    text: 'text-violet-400',
    border: 'border-violet-500/30',
  },
  mastery: {
    badge: 'bg-amber-500/15',
    text: 'text-amber-300',
    border: 'border-amber-500/40',
  },
};

const CATEGORIES: { id: TipCategory | 'all'; label: string }[] = [
  { id: 'all', label: 'All Topics' },
  { id: 'technique', label: 'Technique' },
  { id: 'theory', label: 'Music Theory' },
  { id: 'practice', label: 'Practice Hacks' },
  { id: 'tone', label: 'Tone & Touch' },
  { id: 'ergonomics', label: 'Ergonomics' },
  { id: 'repertoire', label: 'Repertoire' },
];

export const TipLibrary: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedInstrument, setSelectedInstrument] = useState<Instrument | 'all'>('all');
  const [selectedLevel, setSelectedLevel] = useState<DifficultyLevel | 'all'>('all');
  const [selectedCategory, setSelectedCategory] = useState<TipCategory | 'all'>('all');
  const [bookmarkedIds, setBookmarkedIds] = useState<string[]>([]);
  const [showBookmarksOnly, setShowBookmarksOnly] = useState(false);
  const [expandedTipId, setExpandedTipId] = useState<string | null>(null);

  // Load bookmarks from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem('ivory_steel_bookmarks');
      if (saved) {
        setBookmarkedIds(JSON.parse(saved));
      }
    } catch {
      // LocalStorage access fallback
    }
  }, []);

  const toggleBookmark = (id: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setBookmarkedIds((prev) => {
      const next = prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id];
      try {
        localStorage.setItem('ivory_steel_bookmarks', JSON.stringify(next));
      } catch {
        // fallback
      }
      return next;
    });
  };

  const filteredTips = useMemo(() => {
    return TIPS_DATA.filter((tip) => {
      // Search filter
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const matchesQuery =
          tip.title.toLowerCase().includes(query) ||
          tip.summary.toLowerCase().includes(query) ||
          tip.detailedExplanation.toLowerCase().includes(query) ||
          tip.tags.some((tag) => tag.toLowerCase().includes(query)) ||
          tip.proSecret.toLowerCase().includes(query);
        if (!matchesQuery) return false;
      }

      // Instrument filter
      if (selectedInstrument !== 'all') {
        if (tip.instrument !== 'both' && tip.instrument !== selectedInstrument) {
          return false;
        }
      }

      // Level filter
      if (selectedLevel !== 'all' && tip.level !== selectedLevel) {
        return false;
      }

      // Category filter
      if (selectedCategory !== 'all' && tip.category !== selectedCategory) {
        return false;
      }

      // Bookmarks filter
      if (showBookmarksOnly && !bookmarkedIds.includes(tip.id)) {
        return false;
      }

      return true;
    });
  }, [searchQuery, selectedInstrument, selectedLevel, selectedCategory, showBookmarksOnly, bookmarkedIds]);

  const handleRandomTip = () => {
    if (TIPS_DATA.length > 0) {
      const randomIndex = Math.floor(Math.random() * TIPS_DATA.length);
      const chosen = TIPS_DATA[randomIndex];
      setExpandedTipId(chosen.id);
      setSelectedInstrument('all');
      setSelectedLevel('all');
      setSelectedCategory('all');
      setShowBookmarksOnly(false);
      setSearchQuery('');
      // Scroll to tip card
      setTimeout(() => {
        const el = document.getElementById(`tip-${chosen.id}`);
        el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }, 100);
    }
  };

  return (
    <div className="flex flex-col gap-8">
      {/* Search and Filters Hub */}
      <div className="bg-slate-900/90 border border-amber-900/40 rounded-2xl p-6 shadow-xl backdrop-blur-md">
        <div className="flex flex-col md:flex-row gap-4 items-center justify-between mb-6">
          <div className="relative w-full md:w-96">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              data-testid="search-input"
              type="text"
              placeholder="Search tips (e.g. thumb-under, barre, Chopin, CAGED)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-slate-950/80 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:border-amber-500/80 focus:ring-1 focus:ring-amber-500/80"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto justify-end">
            <button
              data-testid="random-tip-btn"
              onClick={handleRandomTip}
              className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-amber-300 border border-amber-500/30 text-xs font-bold flex items-center gap-1.5 transition-all shadow"
            >
              <Shuffle className="w-3.5 h-3.5" />
              Inspire Me (Random)
            </button>

            <button
              data-testid="toggle-bookmarks-btn"
              onClick={() => setShowBookmarksOnly(!showBookmarksOnly)}
              className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all border ${
                showBookmarksOnly
                  ? 'bg-amber-500 text-slate-950 border-amber-400 shadow-lg'
                  : 'bg-slate-800 text-slate-300 border-slate-700 hover:text-white'
              }`}
            >
              <Bookmark className={`w-3.5 h-3.5 ${showBookmarksOnly ? 'fill-current' : ''}`} />
              Saved ({bookmarkedIds.length})
            </button>
          </div>
        </div>

        {/* Filter Badges Row 1: Instrument */}
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400 mr-2">
              Instrument:
            </span>
            {(['all', 'piano', 'guitar', 'both'] as const).map((inst) => (
              <button
                key={inst}
                data-testid={`filter-inst-${inst}`}
                onClick={() => setSelectedInstrument(inst)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all border ${
                  selectedInstrument === inst
                    ? 'bg-amber-500 text-slate-950 border-amber-400 shadow'
                    : 'bg-slate-950/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                }`}
              >
                {inst === 'both' ? 'Universal' : inst}
              </button>
            ))}
          </div>

          {/* Filter Badges Row 2: Difficulty Level */}
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400 mr-2">
              Level:
            </span>
            {(['all', 'beginner', 'intermediate', 'advanced', 'mastery'] as const).map((lvl) => (
              <button
                key={lvl}
                data-testid={`filter-level-${lvl}`}
                onClick={() => setSelectedLevel(lvl)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all border ${
                  selectedLevel === lvl
                    ? 'bg-amber-500 text-slate-950 border-amber-400 shadow'
                    : 'bg-slate-950/80 text-slate-400 border-slate-800 hover:text-slate-200 hover:border-slate-700'
                }`}
              >
                {lvl}
              </button>
            ))}
          </div>

          {/* Filter Badges Row 3: Category */}
          <div className="flex flex-wrap items-center gap-2 pt-1 border-t border-slate-800/80">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-400 mr-2">
              Topic:
            </span>
            {CATEGORIES.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-semibold transition-all border ${
                  selectedCategory === cat.id
                    ? 'bg-amber-500/20 text-amber-300 border-amber-500/60'
                    : 'bg-slate-950/40 text-slate-400 border-slate-800/80 hover:text-slate-200'
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Tip List Counter */}
      <div className="flex items-center justify-between text-xs text-slate-400 px-1">
        <span>
          Showing <strong className="text-amber-400">{filteredTips.length}</strong> musician guides
        </span>
        {(selectedInstrument !== 'all' ||
          selectedLevel !== 'all' ||
          selectedCategory !== 'all' ||
          searchQuery ||
          showBookmarksOnly) && (
          <button
            onClick={() => {
              setSelectedInstrument('all');
              setSelectedLevel('all');
              setSelectedCategory('all');
              setShowBookmarksOnly(false);
              setSearchQuery('');
            }}
            className="text-amber-400 hover:underline"
          >
            Reset Filters
          </button>
        )}
      </div>

      {/* Tips Cards Grid */}
      {filteredTips.length === 0 ? (
        <div className="text-center py-16 bg-slate-900/40 border border-dashed border-slate-800 rounded-2xl">
          <BookOpen className="w-12 h-12 text-slate-600 mx-auto mb-3" />
          <h4 className="text-lg font-bold text-slate-300">No master tips found</h4>
          <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
            Try adjusting your search keywords or switching instrument/level filter toggles.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {filteredTips.map((tip) => {
            const isBookmarked = bookmarkedIds.includes(tip.id);
            const isExpanded = expandedTipId === tip.id;
            const levelStyle = LEVEL_COLORS[tip.level];

            return (
              <div
                key={tip.id}
                id={`tip-${tip.id}`}
                data-testid={`tip-card-${tip.id}`}
                className={`bg-slate-900/90 border transition-all duration-200 rounded-2xl p-6 shadow-xl backdrop-blur-md ${
                  isExpanded
                    ? 'border-amber-500/70 ring-1 ring-amber-500/30'
                    : 'border-slate-800/80 hover:border-slate-700'
                }`}
              >
                {/* Card Header */}
                <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
                  <div className="space-y-2 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      {/* Instrument Badge */}
                      <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider bg-slate-800 text-amber-300 border border-amber-500/20">
                        {tip.instrument === 'both' ? 'Piano & Guitar' : tip.instrument}
                      </span>

                      {/* Difficulty Level Badge */}
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider border ${levelStyle.badge} ${levelStyle.text} ${levelStyle.border}`}
                      >
                        {tip.level}
                      </span>

                      {/* Category Badge */}
                      <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-slate-950/80 text-slate-400 border border-slate-800">
                        {tip.category}
                      </span>
                    </div>

                    <h3
                      onClick={() => setExpandedTipId(isExpanded ? null : tip.id)}
                      className="text-xl font-serif font-bold text-slate-100 hover:text-amber-300 cursor-pointer transition-colors pt-1"
                    >
                      {tip.title}
                    </h3>
                  </div>

                  {/* Bookmark Button */}
                  <div className="flex items-center gap-2 self-end sm:self-start">
                    <button
                      data-testid={`bookmark-btn-${tip.id}`}
                      onClick={(e) => toggleBookmark(tip.id, e)}
                      title={isBookmarked ? 'Remove from saved' : 'Save tip'}
                      className={`p-2 rounded-xl border transition-all ${
                        isBookmarked
                          ? 'bg-amber-500/20 text-amber-400 border-amber-500/50'
                          : 'bg-slate-800/80 text-slate-400 border-slate-700 hover:text-slate-200 hover:bg-slate-700'
                      }`}
                    >
                      {isBookmarked ? (
                        <BookmarkCheck className="w-4 h-4 fill-current" />
                      ) : (
                        <Bookmark className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>

                {/* Summary */}
                <p className="text-sm text-slate-300/90 mt-3 leading-relaxed">{tip.summary}</p>

                {/* Tags */}
                <div className="flex flex-wrap gap-1.5 mt-4">
                  {tip.tags.map((tag) => (
                    <span
                      key={tag}
                      className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-950/60 text-slate-400 border border-slate-800/80"
                    >
                      #{tag}
                    </span>
                  ))}
                </div>

                {/* Expand / Collapse Button */}
                <div className="mt-5 pt-4 border-t border-slate-800/80 flex items-center justify-between">
                  <button
                    data-testid={`expand-tip-${tip.id}`}
                    onClick={() => setExpandedTipId(isExpanded ? null : tip.id)}
                    className="text-xs font-bold text-amber-400 hover:text-amber-300 flex items-center gap-1.5 transition-colors"
                  >
                    {isExpanded ? (
                      <>
                        <span>Show Less</span>
                        <ChevronUp className="w-4 h-4" />
                      </>
                    ) : (
                      <>
                        <span>Read Full Masterclass & Drills</span>
                        <ChevronDown className="w-4 h-4" />
                      </>
                    )}
                  </button>

                  <span className="text-[11px] text-slate-500">
                    Est. Drill: {tip.practicalExercise.recommendedDurationMinutes || 10} min
                  </span>
                </div>

                {/* Expanded In-Depth Musician Masterclass */}
                {isExpanded && (
                  <div className="mt-6 pt-6 border-t border-amber-900/30 space-y-6 animate-fadeIn">
                    {/* Deep Explanation */}
                    <div className="bg-slate-950/60 rounded-xl p-5 border border-slate-800">
                      <div className="flex items-center gap-2 text-amber-400 mb-2">
                        <BookOpen className="w-4 h-4" />
                        <h4 className="text-sm font-bold uppercase tracking-wider">
                          Musician Mechanics & Theoretical Breakdown
                        </h4>
                      </div>
                      <p className="text-sm text-slate-300 leading-relaxed whitespace-pre-line">
                        {tip.detailedExplanation}
                      </p>
                    </div>

                    {/* Musical Example / Notation / Tab */}
                    {tip.musicalExample && (
                      <div className="bg-[#0b0d11] rounded-xl p-5 border border-amber-950/60">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-2 text-slate-300 text-xs font-bold uppercase tracking-wider">
                            <Music className="w-4 h-4 text-amber-400" />
                            <span>Musical Diagram ({tip.musicalExample.type.toUpperCase()})</span>
                          </div>
                          <span className="text-[11px] text-slate-400 italic">
                            {tip.musicalExample.caption}
                          </span>
                        </div>
                        <pre className="p-4 rounded-lg bg-black/60 border border-slate-800 font-mono text-xs text-amber-200/95 overflow-x-auto whitespace-pre leading-relaxed">
                          {tip.musicalExample.content}
                        </pre>
                      </div>
                    )}

                    {/* Step-by-Step Practical Drill */}
                    <div className="bg-slate-950/60 rounded-xl p-5 border border-emerald-900/30">
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-2 text-emerald-400">
                          <CheckCircle2 className="w-4 h-4" />
                          <h4 className="text-sm font-bold uppercase tracking-wider">
                            Daily Practice Drill: {tip.practicalExercise.title}
                          </h4>
                        </div>
                        {tip.practicalExercise.tempoBpm && (
                          <span className="text-xs font-mono px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-300 border border-emerald-500/30">
                            Metronome: {tip.practicalExercise.tempoBpm} BPM
                          </span>
                        )}
                      </div>

                      <ol className="space-y-2 text-xs sm:text-sm text-slate-300">
                        {tip.practicalExercise.steps.map((step, idx) => (
                          <li key={idx} className="flex items-start gap-2.5">
                            <span className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 font-bold text-xs flex items-center justify-center shrink-0 mt-0.5">
                              {idx + 1}
                            </span>
                            <span className="leading-relaxed">{step}</span>
                          </li>
                        ))}
                      </ol>
                    </div>

                    {/* Pro Musician Secret & Common Mistake Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {/* Pro Secret */}
                      <div className="bg-amber-950/20 border border-amber-600/30 rounded-xl p-4">
                        <div className="flex items-center gap-2 text-amber-400 mb-1.5 font-bold text-xs uppercase tracking-wider">
                          <Lightbulb className="w-4 h-4" />
                          <span>Pro Musician Secret</span>
                        </div>
                        <p className="text-xs text-amber-100/90 leading-relaxed font-serif italic">
                          "{tip.proSecret}"
                        </p>
                      </div>

                      {/* Common Pitfall */}
                      <div className="bg-rose-950/20 border border-rose-600/30 rounded-xl p-4">
                        <div className="flex items-center gap-2 text-rose-400 mb-1.5 font-bold text-xs uppercase tracking-wider">
                          <AlertTriangle className="w-4 h-4" />
                          <span>Amateur Pitfall to Avoid</span>
                        </div>
                        <p className="text-xs text-rose-100/90 leading-relaxed">
                          {tip.commonMistake}
                        </p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
