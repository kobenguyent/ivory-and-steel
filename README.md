# 🎹 Ivory & Steel 🎸

> **The Modern Musician's Guide & Interactive Masterclass for Piano & Guitar**  
> *From First Chords to Concert Stage Virtuosity — on Web & Native macOS.*

[![macOS Tests](https://img.shields.io/badge/macOS%20XCTest-42%20passed-success.svg)](https://developer.apple.com/xcode/swift-package-manager/)
[![Web Tests](https://img.shields.io/badge/Web%20Vitest-57%20passed-brightgreen.svg)](https://vitest.dev/)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138.svg)](https://swift.org/)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%2F%20Sequoia-black.svg)](https://www.apple.com/macos/)
[![React 18](https://img.shields.io/badge/react-18.3.1-blue.svg)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/typescript-5.7.2-3178c6.svg)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/tailwindcss-3.4.17-38bdf8.svg)](https://tailwindcss.com/)
[![Deploy to GitHub Pages](https://img.shields.io/badge/deploy-GitHub%20Pages-success.svg)](https://pages.github.com/)

---

## 🌟 Overview

**Ivory & Steel** is a musician-grade interactive suite for pianists and guitarists across all progression tiers—**Beginner**, **Intermediate**, **Advanced**, and **Mastery/Virtuoso**.

Unlike superficial tutorials, Ivory & Steel unifies anatomical ergonomics, music theory mechanics, actionable practice regimens, and interactive physical audio visualizers across two platforms:
1. **🌐 Web Masterclass App**: Single-page React application powered by client-side Web Audio synthesis, zero external sound samples, 100% offline-ready, deployed seamlessly to GitHub Pages.
2. **🖥️ Native macOS Studio Desktop App**: High-performance native SwiftUI application powered by AVFoundation audio DSP, 16-voice polyphonic ring allocation, discrete-time sample scheduling, CoreMIDI hardware controller support, and an Apple-inspired concert grand aesthetic.

---

## 🖥️ Native macOS Desktop Studio (`macos/`)

The native macOS application provides zero-latency performance, hardware MIDI controller input, and dedicated practice tools engineered specifically for Apple Silicon and Intel Macs.

### Key macOS Capabilities
- **7 Dedicated Studios**:
  - **Theory Explorer**: Universal 12-key circle of fifths astrolabe, Roman numeral chord degree badges (`I` through `vii°`), diatonic voice leading, and instant sector modulation.
  - **Virtual Piano**: 25-key dual-octave keyboard (C4–C6) with natural acoustic ivory keys, subtle champagne gold jewel pips, and computer keyboard mapping.
  - **Guitar Fretboard**: 15-fret rosewood fingerboard with mother-of-pearl inlays, CAGED pattern overlays, and individual plucked string resonance.
  - **Metronome Studio**: Analog swinging pendulum physics with adjustable bob height scaled by BPM, circular tempo dial, Italian tempo presets (*Largo* to *Presto*), 6 time signatures, rhythmic subdivisions, and automated speed acceleration trainer.
  - **Practice Routine**: Guided daily interval workouts with audio completion chimes.
  - **Masterclass Tips**: Categorized physical and harmonic drills with bookmarks.
  - **Level Quiz**: Comprehensive diagnostic skill assessments for piano and guitar.
- **Menu Bar Extra Companion (`MenuBarExtraView.swift`)**:
  - Quick-access menu bar icon with one-click metronome playback, tempo slider, volume toggle, and studio switcher shortcuts.
- **CoreMIDI Hardware Integration (`MIDIManager.swift`)**:
  - Plug-and-play USB & Bluetooth MIDI keyboard/fretboard support with real-time note-on/note-off visual illumination.
- **Master Audio Engine (`AudioEngine.swift`, `VoiceNodePool.swift`)**:
  - 44.1 kHz stereo AVFoundation graph with parametric presence EQ, soundboard body warmth, and 16-voice circular pool with 3ms micro-fadeout to eliminate clicks and speaker pops.

### macOS CLI Commands

```bash
# Launch native macOS app (compiles and runs release bundle)
npm run macos

# Fast launch (sub-second launch skipping DMG generation)
npm run macos:fast

# Build and package signed IvoryAndSteel.app bundle
npm run macos:build

# Run 42-test native macOS XCTest suite
npm run macos:test

# Run full dual-platform suite (42 XCTests + 57 Vitests = 99 tests)
npm run test:all

# Open Xcode workspace
npm run macos:open
```

---

## 🌐 Web Masterclass Features

### 1. 📚 4-Tier Masterclass & Tips Library
- **Beginner**: "Curved Dome" hand posture (holding the orange), ghost thumb-under scale glide, anchor finger transitions (G-Cadd9-D-Em7), fret-edge minimal pressure rule, landmark notation sight-reading.
- **Intermediate**: Syncopated pedaling synchronization, hand decoupling & Alberti bass, Chopin arm-weight drop, F-barre leverage mechanics, CAGED fretboard mapping, 3:2 polyrhythms ("Not Dif-fi-cult"), and guide-tone ii-V-I voice leading.
- **Advanced**: Bill Evans rootless voicings (Type A/B), Allan Holdsworth liquid legato, 3-string sweep picking triangles, top-3 string triad arranging, modal target notes (Dorian & Mixolydian), and romantic rubato phrasing.
- **Mastery / Virtuoso**: Acoustic grand half-pedaling & harmonic micro-clearing, real-time tritone substitution with chromatic bass descent, Taubman forearm rotational freedom, instant ear transcription, and stage fright flow state conditioning.
- **Interactive Search & Filtering**: Filter by instrument, level, and category. Bookmark favorite tips directly to `localStorage`.

### 2. 🎹 Interactive Virtual Grand Piano
- 25-key dual-octave keyboard (C4 - C6).
- Harmonic overtone synthesis (sine + triangle overtones + natural acoustic decay envelope).
- Play using mouse clicks or full computer keyboard typing (`A` through `K` keys).
- Visual chord and scale degree highlighting.

### 3. 🎸 Interactive 6-String Guitar Fretboard
- 15 frets in Standard Tuning (`E-A-D-G-B-E`).
- Modeled plucked acoustic string resonance.
- Visual pearloid fret markers (frets 3, 5, 7, 9, 12 double-dot, 15).
- Chord & scale overlays (CAGED, pentatonic boxes, modal patterns).

### 4. 🧭 Chord & Scale Theory Explorer
- Switch seamlessly between Piano and Guitar diagrams.
- Explore Major, Minor, Dominant 7th, Maj7, Min7, Diminished, Pentatonic, Blues, and Modes (Dorian, Harmonic Minor).
- Real-time arpeggiated strums or scale step runs with one click.

### 5. ⏱️ Precision Backbeat Metronome
- Sample-accurate discrete audio click generation (high-pitch downbeat accent on beat 1).
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
- Xcode 15+ (optional, for native macOS build)

```bash
# 1. Clone the repository
git clone https://github.com/thienng-it/ivory-and-steel.git
cd ivory-and-steel

# 2. Install dependencies
npm install

# 3. Start local development server (Web)
npm run dev

# 4. Launch native macOS application (macOS only)
npm run macos
```

---

## 🧪 Automated Testing (99 Tests Passing)

Ivory & Steel enforces rigorous test coverage across both platforms:

```bash
# Run both macOS and Web test suites
npm run test:all

# Run Web Vitest suite only (57 tests)
npm test

# Run Native macOS XCTest suite only (42 tests)
npm run macos:test
```

### Coverage Overview:
- **12-TET Math**: $f = 440 \times 2^{(n-69)/12}$ frequency verification across all 12 keys.
- **Acoustic Audio DSP**: Non-zero envelope floors, 3ms voice stealing without clicks, audio buffer caching, and downbeat/standard woodblock synthesis.
- **CoreMIDI Handling**: Universal MIDI Packet (UMP) and Legacy packet parsing, device refresh safety, and note-on/off routing.
- **Music Theory Engine**: All 12 key signatures, circle of fifths positions, diatonic chords, and enharmonic translations.
- **Metronome Engine**: Sample-accurate interval frame math, state transitions, rapid lifecycle toggle idempotency, and tap-tempo algorithms.
- **UI & Accessibility**: Screen-reader labels, keyboard navigation, and responsive touch/click targets.

---

## 📦 Building for Production

### Web Production Bundle (Vite)
```bash
npm run build
```
Generates static assets in `dist/` configured with relative paths (`./`) for static hosting or GitHub Pages.

### Native macOS Application Bundle (`.app`, `.dmg`, `.zip`)
```bash
npm run macos:build
```
Compiles, ad-hoc code-signs, and packages:
- `macos/build/IvoryAndSteel.app` — Standalone native macOS application bundle
- `macos/build/IvoryAndSteel.dmg` — Apple Disk Image with `/Applications` drag-and-drop shortcut & one-click Gatekeeper-bypass installer (`Install Ivory & Steel (No Apple Dev Account).command`)
- `macos/build/IvoryAndSteel.zip` — Compressed app bundle preserving resource forks and permissions
- `macos/build/SHA256SUMS.txt` — SHA-256 checksums for all release artifacts

---

## 🚢 GitHub Actions Workflows & Native App Releases

Ivory & Steel includes three automated GitHub Actions pipelines in `.github/workflows/`:

1. **`ci.yml` — CI & Native macOS Build**
   - Triggers on every `push` and `pull_request` to `main`/`master` as well as manual `workflow_dispatch`.
   - Runs all 99 tests (`42 macOS XCTests` + `57 Web Vitest tests`), compiles the native macOS `.app`, packages `.dmg` & `.zip` installers, verifies ad-hoc code signatures, and uploads **`IvoryAndSteel-macOS-DMG`**, **`IvoryAndSteel-macOS-ZIP`**, and **`IvoryAndSteel-macOS-Release`** directly to the workflow run summary for one-click download.
2. **`release.yml` — Build & Publish GitHub Release**
   - Triggers automatically when pushing a version tag (`v*`, e.g., `v1.0.0`) or manually via **Actions → Release → Run workflow**.
   - Stamps the release version into `Info.plist`, runs the full test suite, builds `IvoryAndSteel.dmg`, `IvoryAndSteel.zip`, versioned archives, and `SHA256SUMS.txt`, and publishes a full **GitHub Release** with downloadable native installers and installation instructions.
3. **`deploy.yml` — Deploy to GitHub Pages**
   - Automatically tests, builds, and deploys the Web Masterclass SPA to GitHub Pages on pushes to `main`.

### Publishing a New Native Release
```bash
git tag v1.0.0
git push origin v1.0.0
```
*(Or trigger manually from GitHub Actions → **Release** → **Run workflow** with your desired version tag).*

---

## 📁 Project Architecture

```
ivory-and-steel/
├── .github/workflows/                 # Automated CI/CD & Native Release Pipelines
│   ├── ci.yml                         # Continuous macOS + Web testing & DMG/ZIP artifacts
│   ├── release.yml                    # Automated GitHub Release publisher (.dmg, .zip, SHA256)
│   └── deploy.yml                     # GitHub Pages web deployment
├── macos/                             # Native macOS Desktop App (Swift 6 + SwiftUI)
│   ├── Package.swift                  # Swift Package Manager manifest
│   ├── Resources/                     # AppIcon.icns, Info.plist, Entitlements
│   ├── Sources/IvoryAndSteel/
│   │   ├── App/                       # App lifecycle, AppState, MenuBarExtraView
│   │   ├── Core/Audio/                # AudioEngine, DSPMath, MetronomeEngine, VoiceNodePool
│   │   ├── Core/Contracts/            # Swift protocols for audio, state, theory
│   │   ├── Core/MIDI/                 # CoreMIDI Manager & device discovery
│   │   ├── Core/Storage/              # Persistent UserDefaults bookmarking
│   │   ├── Core/Theory/               # MusicTheoryEngine, scales, chords, keys
│   │   └── UI/
│   │       ├── Components/            # CircleOfFifths, NativePiano, NativeFretboard, MetronomeDial
│   │       └── Views/                 # 7 dedicated studio views & SettingsView
│   ├── Tests/IvoryAndSteelTests/      # 42 XCTest unit tests
│   └── scripts/                       # run.sh, build_app.sh, run_tests.sh
├── src/                               # Web Masterclass App (React 18 + TypeScript)
│   ├── components/                    # InteractivePiano, InteractiveFretboard, Metronome, etc.
│   ├── data/                          # tipsData, chordsAndScalesData, quizData
│   ├── test/                          # 57 Vitest unit & integration tests
│   ├── utils/audio.ts                 # Client-side Web Audio API synthesizer
│   ├── types/                         # TypeScript interfaces
│   ├── App.tsx                        # Main React coordinator
│   └── index.css                      # Tailwind luxury theme styling
├── package.json                       # Unified npm run scripts (web & macos)
└── vite.config.ts                     # Vite bundler & test configuration
```

---

## 🎼 License

MIT &copy; Ivory & Steel. Handcrafted for musicians worldwide.
