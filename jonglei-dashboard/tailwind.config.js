/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans:    ['Outfit', 'sans-serif'],
        mono:    ['"JetBrains Mono"', 'monospace'],
        display: ['"DM Serif Display"', 'serif'],
      },
      colors: {
        canvas: '#F7F4EF',
        teal: {
          950: '#001F1A',
          900: '#002B25',
          800: '#004D3C',
          700: '#005440',
          600: '#0F6E56',
          500: '#1A8B6E',
          400: '#3DAA8C',
          300: '#6CC4A8',
          200: '#A8DECE',
          100: '#D4EFE8',
          50:  '#EDF8F4',
        },
        amber: {
          950: '#3B1A00',
          900: '#6B3300',
          800: '#92400E',
          700: '#B45309',
          600: '#D97706',
          500: '#F59E0B',
          400: '#FBB347',
          300: '#FCD07A',
          200: '#FDE68A',
          100: '#FEF3C7',
          50:  '#FFFBEB',
        },
      },
      boxShadow: {
        card: '0 2px 12px rgba(0,84,64,0.07)',
        'card-hover': '0 6px 28px rgba(0,84,64,0.13)',
        amber: '0 2px 12px rgba(180,83,9,0.18)',
      },
      transitionTimingFunction: {
        spring: 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [],
}
