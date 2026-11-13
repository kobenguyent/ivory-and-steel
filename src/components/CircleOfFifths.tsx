import React, { useState, useEffect } from 'react';
import { CIRCLE_OF_FIFTHS_KEYS, getKeyInfo } from '../utils/musicTheory';
import { audioEngine } from '../utils/audio';
import { Compass, ArrowRight, ArrowLeft, Home, Volume2 } from 'lucide-react';

interface CircleOfFifthsProps {
  selectedRoot: string;
  onSelectKey: (root: string) => void;
  isCompact?: boolean;
}

export const CircleOfFifths: React.FC<CircleOfFifthsProps> = ({
  selectedRoot,
  onSelectKey,
  isCompact = false,
}) => {
  const currentKey = getKeyInfo(selectedRoot);
  const currentIndex = CIRCLE_OF_FIFTHS_KEYS.findIndex((k) => k.root === currentKey.root);

  // Neighbor indices in Circle of Fifths
  const dominantIndex = (currentIndex + 1) % 12; // +1 step clockwise (V chord)
  const subdominantIndex = (currentIndex + 11) % 12; // -1 step counter-clockwise (IV chord)
  const dominantKey = CIRCLE_OF_FIFTHS_KEYS[dominantIndex];
  const subdominantKey = CIRCLE_OF_FIFTHS_KEYS[subdominantIndex];

  // Dynamic shortest-path smooth rotation state for astrolabe compass needle & harmonic triad sector
  const [rotationAngle, setRotationAngle] = useState(currentIndex * 30);
  const [rippleKey, setRippleKey] = useState(0);

  useEffect(() => {
    const targetAngle = currentIndex * 30;
    setRotationAngle((prev) => {
      const normalizedPrev = ((prev % 360) + 360) % 360;
      let delta = targetAngle - normalizedPrev;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      return prev + delta;
    });
    setRippleKey((k) => k + 1);
  }, [currentIndex]);

  const handleSelect = (root: string) => {
    onSelectKey(root);
    try {
      audioEngine.playPianoNote(root + '4', 1.0, 0.65);
    } catch {
      // Audio fallback safe
    }
  };

  const handlePreviewTone = (note: string) => {
    try {
      audioEngine.playPianoNote(note + '4', 0.9, 0.55);
    } catch {
      // Audio fallback safe
    }
  };

  // Wheel geometry: 12 keys spaced around 360 degrees (radius R)
  // 12 o'clock (0 deg) = C
  // Clockwise step = 30 deg
  const radius = 132;
  const innerRadius = 88;
  const center = 175;

  // Accidental label for each key node
  const getAccidentalShortBadge = (index: number) => {
    if (index === 0) return '♮';
    if (index >= 1 && index <= 6) return `${index}♯`;
    return `${12 - index}♭`;
  };

  return (
    <div className="relative overflow-hidden bg-slate-900/95 dark:bg-musician-charcoal/90 border border-slate-800/90 dark:border-amber-900/30 rounded-2xl p-5 sm:p-7 shadow-2xl backdrop-blur-xl transition-all">
      {/* Background ambient lighting */}
      <div
        className="absolute -bottom-24 -left-24 w-80 h-80 rounded-full bg-amber-500/5 blur-3xl pointer-events-none"
        aria-hidden="true"
      />

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5 border-b border-slate-800/80 pb-4">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400">
            <Compass className="w-5 h-5 animate-spin-slow" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xl sm:text-2xl font-serif font-bold text-slate-100">
                Circle of Fifths
              </h3>
            </div>
            <p className="text-xs text-slate-400 mt-0.5">
              Key signatures, relative minors, and dominant–tonic relationships.
            </p>
          </div>
        </div>

        <div className="text-xs text-slate-400 self-start sm:self-auto bg-slate-950/80 px-3 py-1.5 rounded-xl border border-slate-800">
          Click any key to transpose
        </div>
      </div>

      <div className="flex flex-col lg:flex-row items-center justify-between gap-8">
        {/* Interactive SVG Circular Wheel (Precision Musical Astrolabe) */}
        <div className="relative w-[320px] h-[320px] sm:w-[350px] sm:h-[350px] shrink-0 select-none">
          <svg
            viewBox="0 0 350 350"
            className="w-full h-full drop-shadow-2xl overflow-visible"
            role="region"
            aria-label="Circle of Fifths Wheel"
          >
            <defs>
              {/* Radial gradient for center obsidian medallion */}
              <radialGradient id="cof-center-bg" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stopColor="#1e2230" />
                <stop offset="70%" stopColor="#0b0d13" />
                <stop offset="100%" stopColor="#05070a" />
              </radialGradient>

              {/* Astrolabe Pointer Golden Metallic Gradient */}
              <linearGradient id="cof-needle-gold" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#fef08a" />
                <stop offset="45%" stopColor="#f59e0b" />
                <stop offset="100%" stopColor="#b45309" />
              </linearGradient>

              {/* Harmonic Triad Arc: Subdominant (Emerald) -> Tonic (Gold) -> Dominant (Sky) */}
              <linearGradient id="cof-triad-arc" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#10b981" />
                <stop offset="50%" stopColor="#f59e0b" />
                <stop offset="100%" stopColor="#0284c7" />
              </linearGradient>

              {/* Soft luminous filters */}
              <filter id="glow-gold" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="3.5" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="glow-emerald" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="3.5" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="glow-sky" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="3.5" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="arc-blur" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="5" />
              </filter>
            </defs>

            {/* Background Astrolabe Concentric Housing Rings */}
            <circle
              cx={center}
              cy={center}
              r={radius + 36}
              className="fill-slate-950/95 stroke-amber-900/30"
              strokeWidth="1.5"
            />
            <circle
              cx={center}
              cy={center}
              r={radius + 20}
              className="fill-none stroke-slate-800/60"
              strokeWidth="1"
            />
            <circle
              cx={center}
              cy={center}
              r={radius - 17}
              className="fill-slate-900/60 stroke-amber-500/15"
              strokeWidth="1"
            />
            <circle
              cx={center}
              cy={center}
              r={innerRadius - 18}
              className="fill-slate-950/90 stroke-amber-500/20"
              strokeWidth="1"
            />

            {/* Astrolabe Fine Perimeter Degree Tick Marks (every 10 degrees) */}
            {Array.from({ length: 36 }).map((_, idx) => {
              const tickAngleRad = (idx * 10 - 90) * (Math.PI / 180);
              const isMajor = idx % 3 === 0;
              const rStart = radius + 30;
              const rEnd = isMajor ? radius + 36 : radius + 33;
              const x1 = center + rStart * Math.cos(tickAngleRad);
              const y1 = center + rStart * Math.sin(tickAngleRad);
              const x2 = center + rEnd * Math.cos(tickAngleRad);
              const y2 = center + rEnd * Math.sin(tickAngleRad);

              return (
                <line
                  key={`tick-${idx}`}
                  x1={x1}
                  y1={y1}
                  x2={x2}
                  y2={y2}
                  className={isMajor ? 'stroke-amber-500/40' : 'stroke-slate-800'}
                  strokeWidth={isMajor ? 1.2 : 0.75}
                />
              );
            })}

            {/* Cardinal Compass Diamonds (12, 3, 6, 9 o'clock) */}
            {[0, 90, 180, 270].map((deg) => {
              const rad = (deg - 90) * (Math.PI / 180);
              const cdX = center + (radius + 28) * Math.cos(rad);
              const cdY = center + (radius + 28) * Math.sin(rad);
              return (
                <rect
                  key={`cardinal-${deg}`}
                  x={cdX - 2.5}
                  y={cdY - 2.5}
                  width="5"
                  height="5"
                  transform={`rotate(45 ${cdX} ${cdY})`}
                  className="fill-amber-400/60"
                />
              );
            })}

            {/* Connecting Radial Spokes */}
            {CIRCLE_OF_FIFTHS_KEYS.map((k, i) => {
              const angleRad = (i * 30 - 90) * (Math.PI / 180);
              const xOuter = center + (radius + 18) * Math.cos(angleRad);
              const yOuter = center + (radius + 18) * Math.sin(angleRad);
              const xInner = center + (innerRadius - 16) * Math.cos(angleRad);
              const yInner = center + (innerRadius - 16) * Math.sin(angleRad);

              return (
                <line
                  key={`spoke-${k.root}`}
                  x1={xInner}
                  y1={yInner}
                  x2={xOuter}
                  y2={yOuter}
                  className="stroke-slate-800/70"
                  strokeWidth="1"
                  strokeDasharray="2,2"
                />
              );
            })}

            {/* =========================================================================
                DYNAMIC ROTATING HARMONIC ASTROLABE (Pointer Needle + Reticle Lens + Triad Sector Arc)
                ========================================================================= */}
            <g
              style={{
                transform: `rotate(${rotationAngle}deg)`,
                transformOrigin: `${center}px ${center}px`,
                transition: 'transform 0.7s cubic-bezier(0.16, 1, 0.3, 1)',
              }}
            >
              {/* Luminous Harmonic Beam / Arc (Subdominant IV -> Tonic I -> Dominant V) */}
              {/* Arc from -32 deg to +32 deg at radius 132 */}
              <path
                d="M 105.15 63.15 A 132 132 0 0 1 244.85 63.15"
                fill="none"
                stroke="url(#cof-triad-arc)"
                strokeWidth="12"
                strokeLinecap="round"
                opacity="0.22"
                filter="url(#arc-blur)"
              />
              <path
                d="M 105.15 63.15 A 132 132 0 0 1 244.85 63.15"
                fill="none"
                stroke="url(#cof-triad-arc)"
                strokeWidth="3.5"
                strokeLinecap="round"
                opacity="0.75"
              />

              {/* Astrolabe Pointer Arm & Reticle Lens */}
              {/* Connector line from center hub (y=125) to reticle bottom (y=101) */}
              <line
                x1="175"
                y1="125"
                x2="175"
                y2="101"
                stroke="#d4af37"
                strokeWidth="1"
                strokeDasharray="2,2"
                opacity="0.6"
              />

              {/* Reticle Ring framing the Relative Minor note at y=88 (radius 87) */}
              <circle
                cx="175"
                cy="88"
                r="13"
                className="fill-slate-950/70 stroke-amber-400"
                strokeWidth="1.2"
                strokeDasharray="3,1.5"
              />

              {/* Tapered Pointer Arrow from reticle top (y=75) to outer node edge (y=63) */}
              <path
                d="M 175 63 L 178 75 L 172 75 Z"
                fill="url(#cof-needle-gold)"
                stroke="#fef08a"
                strokeWidth="0.75"
                className="drop-shadow-md"
              />
              <line x1="175" y1="63" x2="175" y2="75" stroke="#ffffff" strokeWidth="0.5" opacity="0.8" />

              {/* Counter-weight jewel at south (180 deg, radius 52 down) */}
              <circle cx="175" cy="227" r="4.5" fill="#0f1117" stroke="#d4af37" strokeWidth="1.2" />
              <circle cx="175" cy="227" r="1.5" fill="#fbbf24" />

              {/* Inner reticle dashed ring */}
              <circle
                cx={center}
                cy={center}
                r={54}
                fill="none"
                stroke="#d4af37"
                strokeWidth="1"
                strokeDasharray="3,3"
                opacity="0.4"
              />
            </g>

            {/* =========================================================================
                CENTER MEDALLION: Active Key Center Readout with Transposition Shockwave
                ========================================================================= */}
            {/* Dynamic Shockwave ripple wave on key change */}
            <circle
              key={`ripple-${rippleKey}`}
              cx={center}
              cy={center}
              r={46}
              fill="none"
              stroke="#f59e0b"
              strokeWidth="2"
              opacity="0.8"
              className="pointer-events-none"
            >
              <animate attributeName="r" from="46" to="78" dur="0.65s" begin="0s" repeatCount="1" fill="freeze" />
              <animate attributeName="opacity" from="0.8" to="0" dur="0.65s" begin="0s" repeatCount="1" fill="freeze" />
              <animate attributeName="stroke-width" from="2" to="0.5" dur="0.65s" begin="0s" repeatCount="1" fill="freeze" />
            </circle>

            {/* Center Medallion Outer Bezel */}
            <circle
              cx={center}
              cy={center}
              r={49}
              className="fill-none stroke-amber-500/30"
              strokeWidth="1"
            />
            {/* Center Medallion Disc */}
            <circle
              cx={center}
              cy={center}
              r={46}
              fill="url(#cof-center-bg)"
              stroke="#d4af37"
              strokeWidth="2"
              className="drop-shadow-lg"
            />

            {/* Center Key Info Typography */}
            <text
              x={center}
              y={center - 11}
              textAnchor="middle"
              className="fill-amber-300 font-serif font-black text-2xl select-none filter drop-shadow"
            >
              {currentKey.root.replace('b', '♭').replace('#', '♯')}
            </text>
            <text
              x={center}
              y={center + 8}
              textAnchor="middle"
              className="fill-slate-300 font-mono text-[10px] font-semibold select-none"
            >
              {currentKey.accidentalType === 'natural'
                ? 'Natural'
                : currentKey.accidentalType === 'sharp'
                ? `${currentKey.sharpsCount}♯`
                : `${currentKey.flatsCount}♭`}
            </text>
            <text
              x={center}
              y={center + 24}
              textAnchor="middle"
              className="fill-purple-300 font-mono font-semibold text-[9.5px] select-none"
            >
              {currentKey.relativeMinorRoot.replace('b', '♭').replace('#', '♯')}m
            </text>

            {/* =========================================================================
                12 OUTER MAJOR KEY NODES & ACCIDENTAL BADGES
                (Mathematically locked: zero displacement on hover)
                ========================================================================= */}
            {CIRCLE_OF_FIFTHS_KEYS.map((keyInfo, i) => {
              const angleDeg = i * 30 - 90;
              const angleRad = angleDeg * (Math.PI / 180);
              const x = center + radius * Math.cos(angleRad);
              const y = center + radius * Math.sin(angleRad);

              // Accidental badge coordinate cleanly positioned on outer radial orbit (radius 160)
              const xAcc = center + (radius + 28) * Math.cos(angleRad);
              const yAcc = center + (radius + 28) * Math.sin(angleRad);

              const isSelected = keyInfo.root === currentKey.root;
              const isDominant = keyInfo.root === dominantKey.root;
              const isSubdominant = keyInfo.root === subdominantKey.root;

              const nodeR = isSelected ? 20 : 17;
              const displayLabel = keyInfo.root.replace('b', '♭').replace('#', '♯');
              const accidentalBadge = getAccidentalShortBadge(i);

              return (
                <g
                  key={keyInfo.root}
                  data-testid={`cof-node-${keyInfo.root}`}
                  onClick={() => handleSelect(keyInfo.root)}
                  className="cursor-pointer group focus:outline-none"
                  role="button"
                  tabIndex={0}
                  aria-label={`${keyInfo.name}, ${keyInfo.keySignatureDesc}`}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      handleSelect(keyInfo.root);
                    }
                  }}
                >
                  {/* High-precision optical focus ring on hover (never shifts geometry) */}
                  <circle
                    cx={x}
                    cy={y}
                    r={isSelected ? nodeR + 4 : nodeR + 3.5}
                    className={`pointer-events-none transition-all duration-200 fill-none ${
                      isSelected
                        ? 'stroke-amber-400/60 opacity-100'
                        : isDominant
                        ? 'stroke-sky-400/80 opacity-0 group-hover:opacity-100'
                        : isSubdominant
                        ? 'stroke-emerald-400/80 opacity-0 group-hover:opacity-100'
                        : 'stroke-amber-400/80 opacity-0 group-hover:opacity-100'
                    }`}
                    strokeWidth={isSelected ? 1.5 : 1.2}
                    strokeDasharray="2.5,2"
                  />

                  {/* Main Node Disc (Fixed mathematical center, zero CSS transform drift) */}
                  <circle
                    cx={x}
                    cy={y}
                    r={nodeR}
                    filter={
                      isSelected
                        ? 'url(#glow-gold)'
                        : isDominant
                        ? 'url(#glow-sky)'
                        : isSubdominant
                        ? 'url(#glow-emerald)'
                        : undefined
                    }
                    className={`transition-all duration-200 ${
                      isSelected
                        ? 'fill-amber-500 stroke-amber-200 group-hover:stroke-white'
                        : isDominant
                        ? 'fill-sky-950 stroke-sky-400 group-hover:fill-sky-900 group-hover:stroke-sky-300'
                        : isSubdominant
                        ? 'fill-emerald-950 stroke-emerald-400 group-hover:fill-emerald-900 group-hover:stroke-emerald-300'
                        : 'fill-slate-900 stroke-slate-700/80 group-hover:fill-slate-800 group-hover:stroke-amber-400/90'
                    }`}
                    strokeWidth={isSelected ? 2.5 : 1.5}
                  />

                  {/* Root Note Glyph (Permanently anchored to center x, y) */}
                  <text
                    x={x}
                    y={y + 4.5}
                    textAnchor="middle"
                    className={`font-serif select-none pointer-events-none transition-colors duration-200 ${
                      isSelected
                        ? 'fill-slate-950 font-black text-sm'
                        : isDominant
                        ? 'fill-sky-300 font-bold text-xs group-hover:fill-sky-200'
                        : isSubdominant
                        ? 'fill-emerald-300 font-bold text-xs group-hover:fill-emerald-200'
                        : 'fill-slate-200 font-bold text-xs group-hover:fill-amber-300'
                    }`}
                  >
                    {displayLabel}
                  </text>

                  {/* Accidental count micro-badge on clean perimeter track */}
                  <text
                    x={xAcc}
                    y={yAcc}
                    textAnchor="middle"
                    dominantBaseline="central"
                    className={`font-mono text-[8.5px] font-semibold select-none pointer-events-none transition-colors duration-200 ${
                      isSelected
                        ? 'fill-amber-300 font-bold text-[9px]'
                        : isDominant
                        ? 'fill-sky-400 font-bold'
                        : isSubdominant
                        ? 'fill-emerald-400 font-bold'
                        : 'fill-slate-500 group-hover:fill-slate-300'
                    }`}
                  >
                    {accidentalBadge}
                  </text>
                </g>
              );
            })}

            {/* =========================================================================
                INNER RING: RELATIVE MINOR NODES
                ========================================================================= */}
            {CIRCLE_OF_FIFTHS_KEYS.map((keyInfo, i) => {
              const angleDeg = i * 30 - 90;
              const angleRad = angleDeg * (Math.PI / 180);
              const x = center + (innerRadius - 2) * Math.cos(angleRad);
              const y = center + (innerRadius - 2) * Math.sin(angleRad);
              const isSelected = keyInfo.root === currentKey.root;
              const minorLabel = keyInfo.relativeMinorRoot.replace('b', '♭').replace('#', '♯') + 'm';

              return (
                <text
                  key={`minor-${keyInfo.root}`}
                  x={x}
                  y={y + 3.5}
                  textAnchor="middle"
                  className={`font-mono select-none pointer-events-none transition-all duration-300 ${
                    isSelected
                      ? 'fill-amber-300 font-extrabold text-[10px]'
                      : 'fill-slate-400 text-[8.5px]'
                  }`}
                >
                  {minorLabel}
                </text>
              );
            })}
          </svg>
        </div>

        {/* Harmonic Relationship Inspector Card */}
        <div
          key={currentKey.root}
          className="flex-1 w-full bg-slate-950/80 rounded-2xl p-5 sm:p-6 border border-slate-800/90 space-y-5 shadow-inner transition-all duration-300 animate-in fade-in-50"
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <div>
              <span className="text-[11px] font-mono text-amber-400 font-semibold uppercase tracking-wider">
                Harmonic Center
              </span>
              <h4 className="text-2xl sm:text-3xl font-serif font-bold text-slate-100 mt-0.5">
                {currentKey.name}
              </h4>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-mono px-3 py-1 rounded-full bg-amber-500/10 text-amber-300 border border-amber-500/30 font-semibold">
                {currentKey.keySignatureDesc}
              </span>
            </div>
          </div>

          {/* Primary Functional Harmonic Triad (IV -> I -> V) */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {/* Subdominant IV */}
            <button
              onClick={() => handleSelect(subdominantKey.root)}
              aria-label={`Modulate to Subdominant key of ${subdominantKey.name}`}
              className="p-3.5 rounded-xl bg-emerald-950/30 border border-emerald-500/30 hover:border-emerald-400 hover:bg-emerald-950/50 text-left transition-all group flex flex-col justify-between shadow-sm hover:shadow-emerald-950/40"
            >
              <div className="flex items-center justify-between text-[10px] font-mono uppercase text-emerald-400 font-bold">
                <span className="flex items-center gap-1">
                  <ArrowLeft className="w-3 h-3 group-hover:-translate-x-0.5 transition-transform" />
                  Subdominant (IV)
                </span>
                <span className="text-sm font-serif font-bold text-emerald-300">
                  {subdominantKey.root.replace('b', '♭').replace('#', '♯')}
                </span>
              </div>
              <p className="text-[11px] text-slate-400 mt-2 leading-relaxed">
                Step counter-clockwise. Provides gentle harmonic relaxation and release.
              </p>
            </button>

            {/* Tonic I */}
            <div className="p-3.5 rounded-xl bg-amber-500/15 border border-amber-500/40 text-left flex flex-col justify-between shadow-md shadow-amber-950/20">
              <div className="flex items-center justify-between text-[10px] font-mono uppercase text-amber-300 font-bold">
                <span className="flex items-center gap-1">
                  <Home className="w-3 h-3 text-amber-400" />
                  Tonic (I) Home
                </span>
                <span className="text-sm font-serif font-bold text-amber-200">
                  {currentKey.root.replace('b', '♭').replace('#', '♯')}
                </span>
              </div>
              <p className="text-[11px] text-slate-300 mt-2 leading-relaxed">
                Harmonic center of gravity. Maximum consonance, stability, and resolution.
              </p>
            </div>

            {/* Dominant V */}
            <button
              onClick={() => handleSelect(dominantKey.root)}
              aria-label={`Modulate to Dominant key of ${dominantKey.name}`}
              className="p-3.5 rounded-xl bg-sky-950/30 border border-sky-500/30 hover:border-sky-400 hover:bg-sky-950/50 text-left transition-all group flex flex-col justify-between shadow-sm hover:shadow-sky-950/40"
            >
              <div className="flex items-center justify-between text-[10px] font-mono uppercase text-sky-400 font-bold">
                <span className="flex items-center gap-1">
                  Dominant (V)
                  <ArrowRight className="w-3 h-3 group-hover:translate-x-0.5 transition-transform" />
                </span>
                <span className="text-sm font-serif font-bold text-sky-300">
                  {dominantKey.root.replace('b', '♭').replace('#', '♯')}
                </span>
              </div>
              <p className="text-[11px] text-slate-400 mt-2 leading-relaxed">
                Step clockwise. Strongest harmonic tension pulling urgently back to Tonic I.
              </p>
            </button>
          </div>

          {/* Diatonic Notes Highway */}
          <div className="pt-3 border-t border-slate-800/80">
            <span className="text-[11px] font-mono text-slate-400 font-semibold block mb-2 uppercase tracking-wider">
              Diatonic Major Scale Tones (Click to audition):
            </span>
            <div className="flex flex-wrap gap-1.5">
              {currentKey.majorScaleNotes.map((note, idx) => (
                <button
                  key={note}
                  onClick={() => handlePreviewTone(note)}
                  title={`Audition ${note}`}
                  className="px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-800 hover:border-amber-400/80 hover:text-amber-300 font-mono text-xs text-amber-200 font-semibold shadow-sm transition-all group inline-flex items-center gap-1"
                >
                  <span className="text-[9px] text-slate-500 group-hover:text-amber-400/80">{idx + 1}:</span>
                  <span>{note}</span>
                  <Volume2 className="w-2.5 h-2.5 text-slate-600 group-hover:text-amber-400 ml-0.5 opacity-0 group-hover:opacity-100 transition-opacity" />
                </button>
              ))}
              <span className="px-2.5 py-1 rounded-lg bg-purple-950/60 border border-purple-500/40 font-mono text-xs text-purple-300 font-semibold flex items-center">
                Rel. Minor: {currentKey.relativeMinor}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
