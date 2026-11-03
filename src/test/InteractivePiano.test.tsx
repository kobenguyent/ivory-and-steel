import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { InteractivePiano } from '../components/InteractivePiano';
import { audioEngine } from '../utils/audio';

describe('InteractivePiano Component', () => {
  it('renders piano title and white/black keys', () => {
    render(<InteractivePiano />);
    expect(screen.getByText('Interactive Grand Piano')).toBeInTheDocument();

    // Check specific keys
    const c4Key = screen.getByTestId('piano-key-C4');
    expect(c4Key).toBeInTheDocument();

    const cSharp4Key = screen.getByTestId('piano-key-C#4');
    expect(cSharp4Key).toBeInTheDocument();
  });

  it('triggers audio synthesis on key click', () => {
    const playSpy = vi.spyOn(audioEngine, 'playPianoNote');
    render(<InteractivePiano />);

    const c4Key = screen.getByTestId('piano-key-C4');
    fireEvent.click(c4Key);

    expect(playSpy).toHaveBeenCalledWith('C4', expect.any(Number), expect.any(Number));
  });

  it('toggles note labels when button is clicked', () => {
    render(<InteractivePiano />);
    const toggleBtn = screen.getByText('Notes: ON');
    expect(toggleBtn).toBeInTheDocument();

    fireEvent.click(toggleBtn);
    expect(screen.getByText('Notes: OFF')).toBeInTheDocument();
  });

  it('highlights given chord/scale notes with accent styling', () => {
    render(<InteractivePiano highlightedNotes={['C4', 'E4', 'G4']} />);
    const c4Key = screen.getByTestId('piano-key-C4');
    expect(c4Key.className).toContain('ring-amber-400');
  });
});
