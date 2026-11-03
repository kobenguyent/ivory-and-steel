import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { PracticeRoutine } from '../components/PracticeRoutine';

describe('PracticeRoutine Component', () => {
  it('renders deliberate practice routine and timer display', () => {
    render(<PracticeRoutine />);
    expect(screen.getByText('Deliberate Practice Routine')).toBeInTheDocument();
    expect(screen.getByTestId('timer-display')).toBeInTheDocument();
  });

  it('switches routine preset between piano and guitar', () => {
    render(<PracticeRoutine />);
    const guitarPresetBtn = screen.getByTestId('routine-preset-1');
    fireEvent.click(guitarPresetBtn);

    expect(screen.getAllByText(/Minimal Pressure Fretting Warmup/i).length).toBeGreaterThan(0);
  });

  it('toggles timer running state', () => {
    render(<PracticeRoutine />);
    const startBtn = screen.getByTestId('toggle-timer-btn');
    expect(startBtn.textContent).toContain('Start Drill');

    fireEvent.click(startBtn);
    expect(startBtn.textContent).toContain('Pause Drill');
  });
});
