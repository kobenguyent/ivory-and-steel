import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { Metronome } from '../components/Metronome';
import { audioEngine } from '../utils/audio';

describe('Metronome Component', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('renders default BPM and controls', () => {
    render(<Metronome />);
    expect(screen.getByText('Precision Metronome')).toBeInTheDocument();
    expect(screen.getByTestId('metronome-bpm-display').textContent).toBe('100');
  });

  it('increments and decrements BPM', () => {
    render(<Metronome />);
    const incBtn = screen.getByTestId('metronome-increment');
    const decBtn = screen.getByTestId('metronome-decrement');

    fireEvent.click(incBtn);
    expect(screen.getByTestId('metronome-bpm-display').textContent).toBe('105');

    fireEvent.click(decBtn);
    expect(screen.getByTestId('metronome-bpm-display').textContent).toBe('100');
  });

  it('starts and stops playback when toggle is clicked', () => {
    const clickSpy = vi.spyOn(audioEngine, 'playMetronomeClick');
    render(<Metronome />);

    const toggleBtn = screen.getByTestId('metronome-toggle');
    expect(toggleBtn.textContent).toContain('START');

    fireEvent.click(toggleBtn);
    expect(toggleBtn.textContent).toContain('STOP');
    expect(clickSpy).toHaveBeenCalled();

    // Advance time
    act(() => {
      vi.advanceTimersByTime(600);
    });

    fireEvent.click(toggleBtn);
    expect(toggleBtn.textContent).toContain('START');
  });

  it('allows tapping tempo', () => {
    render(<Metronome />);
    const tapBtn = screen.getByTestId('metronome-tap');

    // First tap
    fireEvent.click(tapBtn);
    // Tap again 500ms later (120 BPM)
    vi.advanceTimersByTime(500);
    fireEvent.click(tapBtn);

    // Should adjust BPM
    const bpmText = screen.getByTestId('metronome-bpm-display').textContent;
    expect(Number(bpmText)).toBeGreaterThan(30);
  });
});
