/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Outfit', 'sans-serif'],
        mono: ['DM Mono', 'monospace'],
      },
      colors: {
        teal: {
          950: '#002b27',
          900: '#004d40',
          800: '#00695c',
          700: '#00796b',
          600: '#00897b',
          500: '#009688',
          400: '#26a69a',
          300: '#4db6ac',
          200: '#80cbc4',
          100: '#b2dfdb',
          50:  '#e0f2f1',
        },
      },
    },
  },
  plugins: [],
}
