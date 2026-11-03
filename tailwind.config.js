/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        musician: {
          gold: '#d4af37',
          amber: '#f59e0b',
          wood: '#8b5a2b',
          ebony: '#0f1117',
          ivory: '#fdfbf7',
          pearl: '#f3efe6',
          charcoal: '#181b22',
          brass: '#c59b27'
        }
      },
      fontFamily: {
        serif: ['"Playfair Display"', 'Georgia', 'serif'],
        sans: ['"Inter"', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'monospace'],
      },
      boxShadow: {
        'piano-key': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06), inset 0 -3px 0 0 rgba(0,0,0,0.15)',
        'piano-black': '0 6px 12px -2px rgba(0, 0, 0, 0.5), inset 0 -2px 0 0 rgba(255,255,255,0.1)',
        'glow-gold': '0 0 25px -5px rgba(212, 175, 55, 0.3)',
      }
    },
  },
  plugins: [],
};
