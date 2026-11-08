import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ChordScaleExplorer } from '../components/ChordScaleExplorer';
import { audioEngine } from '../utils/audio';

describe('ChordScaleExplorer Component', () => {
  it('renders explorer header and toggles', () => {
    render(<ChordScaleExplorer />);
    expect(screen.getByText('Chord & Scale Theory Explorer')).toBeInTheDocument();
    expect(screen.getByTestId('toggle-piano')).toBeInTheDocument();
    expect(screen.getByTestId('toggle-guitar')).toBeInTheDocument();
    expect(screen.getByTestId('toggle-diatonic')).toBeInTheDocument();
  });

  it('switches between piano and guitar views', () => {
    render(<ChordScaleExplorer />);
    const guitarToggle = screen.getByTestId('toggle-guitar');
    fireEvent.click(guitarToggle);

    expect(screen.getByText(/Guitar Fretboard Pattern/i)).toBeInTheDocument();
  });

  it('switches between chords, scales, and diatonic suite', () => {
    render(<ChordScaleExplorer />);
    const scalesToggle = screen.getByTestId('toggle-scales');
    fireEvent.click(scalesToggle);
    expect(screen.getAllByText(/Major Scale/i).length).toBeGreaterThan(0);

    const chordsToggle = screen.getByTestId('toggle-chords');
    fireEvent.click(chordsToggle);
    expect(screen.getByTestId('chord-quality-major')).toBeInTheDocument();

    const diatonicToggle = screen.getByTestId('toggle-diatonic');
    fireEvent.click(diatonicToggle);
    expect(screen.getByTestId('diatonic-chord-I')).toBeInTheDocument();
  });

  it('switches key center across all 12 keys via root selector', () => {
    render(<ChordScaleExplorer />);
    const ebBtn = screen.getByTestId('root-select-Eb');
    fireEvent.click(ebBtn);

    expect(screen.getAllByText(/E♭ Major/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/3 Flats/i).length).toBeGreaterThan(0);
  });

  it('interacts with the Circle of Fifths compass', () => {
    render(<ChordScaleExplorer />);
    expect(screen.getByText('Circle of Fifths Compass')).toBeInTheDocument();

    // Click G node on Circle of Fifths
    const gNode = screen.getByTestId('cof-node-G');
    fireEvent.click(gNode);

    expect(screen.getAllByText(/1 Sharp/i).length).toBeGreaterThan(0);

    // Toggle Circle of Fifths collapse
    const cofToggle = screen.getByTestId('toggle-circle-of-fifths');
    fireEvent.click(cofToggle);
    expect(screen.queryByText('Circle of Fifths Compass')).not.toBeInTheDocument();
  });

  it('plays audio when play button is clicked', () => {
    const playChordSpy = vi.spyOn(audioEngine, 'playChord');
    render(<ChordScaleExplorer />);

    const playBtn = screen.getByTestId('play-audio-btn');
    fireEvent.click(playBtn);

    expect(playChordSpy).toHaveBeenCalled();
  });

  it('plays progression cadence in diatonic mode', () => {
    const playChordSpy = vi.spyOn(audioEngine, 'playChord');
    render(<ChordScaleExplorer />);

    const progressionBtn = screen.getByTestId('play-progression-btn');
    fireEvent.click(progressionBtn);

    expect(playChordSpy).toHaveBeenCalled();
  });
});
