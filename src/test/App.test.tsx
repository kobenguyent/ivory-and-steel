import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import App from '../App';

describe('App Main Component', () => {
  it('renders navbar brand Ivory & Steel and Hero section', () => {
    render(<App />);
    expect(screen.getAllByText('Ivory & Steel').length).toBeGreaterThan(0);
    expect(screen.getByText(/Master the/i)).toBeInTheDocument();
  });

  it('navigates to Virtual Piano tab and toggles 12-key scale guide', () => {
    render(<App />);
    const pianoNav = screen.getByTestId('nav-piano');
    fireEvent.click(pianoNav);

    expect(screen.getByText(/Full Concert Grand Piano/i)).toBeInTheDocument();
    expect(screen.getByTestId('piano-guide-root')).toBeInTheDocument();

    const rootSelect = screen.getByTestId('piano-guide-root');
    fireEvent.change(rootSelect, { target: { value: 'Eb' } });
    expect(screen.getByTestId('piano-guide-scale')).toBeInTheDocument();
  });

  it('navigates to Guitar Fretboard tab and toggles 12-key fretboard guide', () => {
    render(<App />);
    const guitarNav = screen.getByTestId('nav-guitar');
    fireEvent.click(guitarNav);

    expect(screen.getByText(/6-String Guitar Fretboard/i)).toBeInTheDocument();
    expect(screen.getByTestId('guitar-guide-root')).toBeInTheDocument();

    const rootSelect = screen.getByTestId('guitar-guide-root');
    fireEvent.change(rootSelect, { target: { value: 'A' } });
    expect(screen.getByTestId('guitar-guide-scale')).toBeInTheDocument();
  });

  it('navigates to Metronome tab via navbar', () => {
    render(<App />);
    const metronomeNav = screen.getByTestId('nav-metronome');
    fireEvent.click(metronomeNav);

    expect(screen.getByText(/Precision Metronome/i)).toBeInTheDocument();
  });

  it('navigates to Skill Assessment Quiz via navbar', () => {
    render(<App />);
    const quizNav = screen.getByTestId('nav-quiz');
    fireEvent.click(quizNav);

    expect(screen.getByText(/Musician Level Self-Assessment/i)).toBeInTheDocument();
  });

  it('toggles audio mute button in navbar', () => {
    render(<App />);
    const muteBtn = screen.getByTestId('audio-mute-toggle');
    expect(muteBtn.textContent).toContain('Sound ON');

    fireEvent.click(muteBtn);
    expect(muteBtn.textContent).toContain('Muted');
  });

  it('toggles theme mode', () => {
    render(<App />);
    const themeBtn = screen.getByTestId('theme-toggle');
    fireEvent.click(themeBtn);
    // Theme toggled without error
    expect(themeBtn).toBeInTheDocument();
  });
});
