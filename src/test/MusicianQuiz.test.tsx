import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MusicianQuiz } from '../components/MusicianQuiz';

describe('MusicianQuiz Component', () => {
  it('renders initial question and options', () => {
    render(<MusicianQuiz />);
    expect(screen.getByText('Musician Level Self-Assessment')).toBeInTheDocument();
    expect(screen.getByTestId('quiz-question-text')).toBeInTheDocument();
    expect(screen.getByTestId('quiz-option-0')).toBeInTheDocument();
  });

  it('selects an answer and reveals explanation and next button', () => {
    render(<MusicianQuiz />);
    const optionBtn = screen.getByTestId('quiz-option-1');
    fireEvent.click(optionBtn);

    expect(screen.getByText(/Musician Breakdown/i)).toBeInTheDocument();
    expect(screen.getByTestId('quiz-next-btn')).toBeInTheDocument();
  });

  it('allows switching between Piano Quiz and Guitar Quiz', () => {
    render(<MusicianQuiz />);
    const guitarQuizBtn = screen.getByTestId('quiz-inst-guitar');
    fireEvent.click(guitarQuizBtn);

    expect(screen.getByText(/fretting fingertip be placed/i)).toBeInTheDocument();
  });
});
