import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { InteractiveFretboard } from '../components/InteractiveFretboard';
import { audioEngine } from '../utils/audio';

describe('InteractiveFretboard Component', () => {
  it('renders fretboard with standard tuning indicators (EADGBE)', () => {
    render(<InteractiveFretboard />);
    expect(screen.getByText('Interactive 6-String Fretboard')).toBeInTheDocument();
    expect(screen.getByText('Nut (0)')).toBeInTheDocument();

    // Check open string 1 (High E)
    const openE = screen.getByTestId('fret-1-0');
    expect(openE).toBeInTheDocument();
  });

  it('plays acoustic guitar note when fret is clicked', () => {
    const playSpy = vi.spyOn(audioEngine, 'playGuitarNote');
    render(<InteractiveFretboard />);

    // Click string 6 (Low E) fret 3 (G note)
    const gFret = screen.getByTestId('fret-6-3');
    fireEvent.click(gFret);

    expect(playSpy).toHaveBeenCalled();
  });

  it('renders highlights for root and chord notes', () => {
    const highlights = [
      { stringNum: 6, fret: 3, label: 'R', isRoot: true },
      { stringNum: 5, fret: 2, label: '3', isRoot: false },
    ];
    render(<InteractiveFretboard highlights={highlights} />);

    const rootBtn = screen.getByTestId('fret-6-3');
    expect(rootBtn.textContent).toBe('R');
    expect(rootBtn.className).toContain('bg-amber-500');
  });
});
