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
  });

  it('switches between piano and guitar views', () => {
    render(<ChordScaleExplorer />);
    const guitarToggle = screen.getByTestId('toggle-guitar');
    fireEvent.click(guitarToggle);

    expect(screen.getByText(/Guitar Fretboard Pattern/i)).toBeInTheDocument();
  });

  it('switches between chords and scales', () => {
    render(<ChordScaleExplorer />);
    const scalesToggle = screen.getByTestId('toggle-scales');
    fireEvent.click(scalesToggle);

    expect(screen.getAllByText(/Major Scale/i).length).toBeGreaterThan(0);
  });

  it('plays audio when play button is clicked', () => {
    const playChordSpy = vi.spyOn(audioEngine, 'playChord');
    render(<ChordScaleExplorer />);

    const playBtn = screen.getByTestId('play-audio-btn');
    fireEvent.click(playBtn);

    expect(playChordSpy).toHaveBeenCalled();
  });
});
