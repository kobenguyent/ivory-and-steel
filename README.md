# 🎹 Ivory & Steel 🎸

> **The Modern Musician's Guide & Interactive Masterclass for Piano & Guitar**  
> *From First Chords to Concert Stage Virtuosity.*

[![Vitest](https://img.shields.io/badge/tests-44%20passed-brightgreen.svg)](https://github.com/)
[![React 18](https://img.shields.io/badge/react-18.3.1-blue.svg)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/typescript-5.7.2-3178c6.svg)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/tailwindcss-3.4.17-38bdf8.svg)](https://tailwindcss.com/)
[![Deploy to GitHub Pages](https://img.shields.io/badge/deploy-GitHub%20Pages-success.svg)](https://pages.github.com/)

---

## 🌟 Overview

**Ivory & Steel** is a musician-grade interactive web application designed to guide pianists and guitarists across all progression tiers—**Beginner**, **Intermediate**, **Advanced**, and **Mastery/Virtuoso**.

Unlike superficial tutorials, Ivory & Steel combines anatomical ergonomics, music theory mechanics, actionable practice regimens, and interactive physical audio visualizers.

Powered entirely by **client-side Web Audio synthesis**, there are zero external audio files to buffer or fail. It runs 100% offline and deploys frictionlessly to **GitHub Pages**.

---

## ✨ Core Features

### 1. 📚 4-Tier Masterclass & Tips Library
- **Beginner**: "Curved Dome" hand posture (holding the orange), ghost thumb-under scale glide, anchor finger chord transitions (G-Cadd9-D-Em7), fret-edge minimal pressure rule, landmark notation sight-reading.
- **Intermediate**: Syncopated pedaling synchronization, hand decoupling & Alberti bass, the Chopin arm-weight drop, F-barre chord leverage mechanics, CAGED system fretboard mapping, 3:2 polyrhythms ("Not Dif-fi-cult"), and guide-tone ii-V-I jazz voice leading.
- **Advanced**: Bill Evans rootless voicings (Type A/B), Allan Holdsworth liquid legato mechanics, 3-string sweep picking triangles, top-3 string triad arranging, modal target notes (Dorian & Mixolydian), and romantic rubato phrasing.
- **Mastery / Virtuoso**: Acoustic grand half-pedaling & harmonic micro-clearing, real-time tritone substitution with chromatic bass descent, Taubman forearm rotational freedom, instant ear transcription, and stage fright flow state conditioning.
- **Interactive Search & Filtering**: Filter by instrument, level, and category. Bookmark favorite tips directly to `localStorage`.
- **Anatomy of Every Tip**:
  - Detailed physical and harmonic explanation
  - Step-by-step daily practice drill with recommended BPM
  - *Pro Musician Secret*
  - *Amateur Pitfall to Avoid*
  - Formatted musical diagram / TAB / notation

### 2. 🎹 Interactive Virtual Grand Piano
- 25-key dual-octave keyboard (C4 - C6).
- Harmonic overtone synthesis (sine + triangle overtones + natural acoustic decay envelope).
- Play using mouse clicks or full computer keyboard typing (`A` through `K` keys).
- Visual chord and scale degree highlighting.

### 3. 🎸 Interactive 6-String Guitar Fretboard
- 15 frets in Standard Tuning (`E-A-D-G-B-E`).
- Modeled plucked acoustic string resonance.
- Visual pearloid fret markers (frets 3, 5, 7, 9, 12 double-dot, 15).
- Click any string/fret to preview pitch and check tuning.
- Chord & scale overlays (CAGED, pentatonic boxes, modal patterns).

### 4. 🧭 Chord & Scale Theory Explorer
- Switch seamlessly between Piano and Guitar diagrams.
- Explore Major, Minor, Dominant 7th, Maj7, Min7, Diminished, Pentatonic, Blues, and Modes (Dorian, Harmonic Minor).
- Listen to real-time arpeggiated strums or scale step runs with one click.

### 5. ⏱️ Precision Backbeat Metronome
- Accurate Web Audio API clave/click generation (high pitch accent on beat 1).
- BPM range 30 to 260 BPM with fine +1/-1 and +5/-5 controls.
- **Tap Tempo** calculation engine.
- Time signatures: 2/4, 3/4, 4/4, 6/8.
- Visual beat pulse indicators and classical tempo presets (*Largo, Adagio, Andante, Moderato, Allegro, Presto*).

### 6. ⏳ Deliberate Practice Routine Planner
- Built-in interval session timer (30-min Piano workout, 30-min Guitar speed workout).
- Audio completion chimes between blocks.
- Interactive checklist to track daily execution.

### 7. 🏆 Musician Skill Self-Assessment Quiz
- Comprehensive diagnostic tests for Piano and Guitar across all 4 levels.
- Immediate explanatory feedback on harmony, ergonomics, and technique.
- Tailored level evaluation and study recommendations.

---

## 🚀 Quick Start & Local Development

### Prerequisites
- Node.js `v18.0.0` or higher
- npm `v9.0.0` or higher

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/ivory-and-steel.git
cd ivory-and-steel

# 2. Install dependencies
npm install

# 3. Start local development server
npm run dev
```

Visit `http://localhost:5173` in your browser.

---

## 🧪 Automated Testing

Ivory & Steel includes a 44-test automated suite powered by **Vitest** and **React Testing Library**:

```bash
# Run tests once
npm run test

# Run tests in watch mode
npm run test:watch
```

Test coverage includes:
- Equal temperament mathematical calculations ($440 \times 2^{(n-69)/12}$)
- Enharmonic pitch conversions (e.g. `Db4` $\leftrightarrow$ `C#4`)
- Web Audio API tone synthesis and mute safety
- Virtual Piano keyboard note strikes and shortcut handling
- Guitar fretboard string gauge rendering and fret calculation
- Metronome timing intervals, tap tempo, and beat accents
- Tip library search, multi-filter combinations, and bookmarking
- Musician self-assessment scoring and level evaluation

---

## 📦 Building for Production

Compile TypeScript and bundle static assets with Vite:

```bash
npm run build
```

The compiled static assets are generated in the `dist/` directory:
- Zero backend dependencies
- Relative asset paths (`base: './'`) configured for GitHub Pages sub-paths or custom apex domains.

---

## 🌐 Deploying to GitHub Pages

### Method A: Automated GitHub Actions (Recommended)

1. Push your repository to GitHub:
   ```bash
   git remote add origin https://github.com/<your-username>/ivory-and-steel.git
   git branch -M main
   git push -u origin main
   ```
2. In your GitHub repository:
   - Go to **Settings** > **Pages**.
   - Under **Build and deployment** > **Source**, select **GitHub Actions**.
3. Push to `main` (or trigger the workflow under **Actions** > **Deploy Ivory & Steel to GitHub Pages**).
4. GitHub Actions will test, build, and deploy your site automatically!

### Method B: Manual Deploy using `gh-pages`

```bash
# Install gh-pages
npm install -D gh-pages

# Add to package.json scripts:
# "deploy": "npm run build && gh-pages -d dist"

npm run deploy
```

---

## 📁 Project Architecture

```
ivory-and-steel/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Pages CI/CD workflow
├── src/
│   ├── components/
│   │   ├── ChordScaleExplorer.tsx # Interactive Chord/Scale previewer
│   │   ├── Footer.tsx             # Musician footer & links
│   │   ├── Hero.tsx               # Catchy visual header & CTA
│   │   ├── InteractiveFretboard.tsx # 6-string guitar neck
│   │   ├── InteractivePiano.tsx   # 2-octave concert grand keyboard
│   │   ├── Metronome.tsx          # Precision backbeat metronome
│   │   ├── MusicianQuiz.tsx       # 4-tier level assessment quiz
│   │   ├── Navbar.tsx             # Navigation, sound & theme toggles
│   │   ├── PracticeRoutine.tsx    # Timed deliberate practice builder
│   │   └── TipLibrary.tsx         # Filterable master tips & drills
│   ├── data/
│   │   ├── chordsAndScalesData.ts # Chord & scale theory mappings
│   │   ├── quizData.ts            # Self-assessment question bank
│   │   └── tipsData.ts            # 4-level piano & guitar curriculum
│   ├── test/
│   │   ├── setup.ts               # Test environment & Web Audio mocks
│   │   ├── audio.test.ts          # Pitch math & synthesizer tests
│   │   ├── data.test.ts           # Curriculum integrity tests
│   │   ├── InteractivePiano.test.tsx
│   │   ├── InteractiveFretboard.test.tsx
│   │   ├── Metronome.test.tsx
│   │   ├── TipLibrary.test.tsx
│   │   ├── ChordScaleExplorer.test.tsx
│   │   ├── PracticeRoutine.test.tsx
│   │   ├── MusicianQuiz.test.tsx
│   │   └── App.test.tsx
│   ├── utils/
│   │   └── audio.ts               # Web Audio API physical synthesizer
│   ├── types/
│   │   └── index.ts               # Strict TypeScript definitions
│   ├── App.tsx                    # Main application coordinator
│   ├── index.css                  # Custom Tailwind styles & animations
│   └── main.tsx                   # React root entry point
├── index.html                     # HTML5 shell & Google Fonts
├── package.json                   # Dependencies & test scripts
├── tailwind.config.js             # Luxury musician color theme
├── tsconfig.json                  # TypeScript compiler options
└── vite.config.ts                 # Vite bundler & vitest config
```

---

## 🎼 License

MIT &copy; Ivory & Steel. Handcrafted for musicians worldwide.
