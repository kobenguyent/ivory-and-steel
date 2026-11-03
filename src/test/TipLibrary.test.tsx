import React from 'react';
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TipLibrary } from '../components/TipLibrary';

describe('TipLibrary Component', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('renders initial tip library and filter buttons', () => {
    render(<TipLibrary />);
    expect(screen.getByTestId('search-input')).toBeInTheDocument();
    expect(screen.getByTestId('filter-inst-piano')).toBeInTheDocument();
    expect(screen.getByTestId('filter-inst-guitar')).toBeInTheDocument();
  });

  it('filters tips by instrument', () => {
    render(<TipLibrary />);
    const guitarFilter = screen.getByTestId('filter-inst-guitar');
    fireEvent.click(guitarFilter);

    // F-barre chord tip should be present
    expect(screen.getByText(/F-Barre Chord Breakthrough/i)).toBeInTheDocument();
  });

  it('filters tips by difficulty level', () => {
    render(<TipLibrary />);
    const masteryFilter = screen.getByTestId('filter-level-mastery');
    fireEvent.click(masteryFilter);

    // Mastery tip should be present
    expect(screen.getByText(/Allan Holdsworth Symmetry/i)).toBeInTheDocument();
  });

  it('searches tips by keywords', () => {
    render(<TipLibrary />);
    const searchInput = screen.getByTestId('search-input');
    fireEvent.change(searchInput, { target: { value: 'Chopin' } });

    expect(screen.getByText(/Chopin "Arm-Weight"/i)).toBeInTheDocument();
  });

  it('toggles bookmarks and filters saved tips', () => {
    render(<TipLibrary />);
    const bookmarkBtn = screen.getByTestId('bookmark-btn-piano-beg-01');
    fireEvent.click(bookmarkBtn);

    // Click saved tips toggle
    const savedToggle = screen.getByTestId('toggle-bookmarks-btn');
    fireEvent.click(savedToggle);

    // Bookmarked tip is present
    expect(screen.getByText(/Curved Dome/i)).toBeInTheDocument();
  });

  it('expands tip to display practical drill and pro secret', () => {
    render(<TipLibrary />);
    const expandBtn = screen.getByTestId('expand-tip-piano-beg-01');
    fireEvent.click(expandBtn);

    expect(screen.getByText(/Daily Practice Drill/i)).toBeInTheDocument();
    expect(screen.getByText(/Pro Musician Secret/i)).toBeInTheDocument();
    expect(screen.getByText(/Amateur Pitfall to Avoid/i)).toBeInTheDocument();
  });
});
