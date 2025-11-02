/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
        success: '#10b981',
        warning: '#f59e0b',
        danger: '#ef4444',
        // Theme-aware colors
        'theme-primary': 'var(--theme-primary)',
        'theme-secondary': 'var(--theme-secondary)',
        'theme-accent': 'var(--theme-accent)',
        'theme-background': 'var(--theme-background)',
        'theme-surface': 'var(--theme-surface)',
        'theme-text': 'var(--theme-text)',
        'theme-text-secondary': 'var(--theme-text-secondary)',
        // HC Lokeren Design Kit Colors
        'hc-primary': '#121238',
        'hc-accent': '#478dcb', 
        'hc-white': '#ffffff',
        'hc-grey-light': '#f3f3f3',
        'hc-grey-medium': '#c0c0c0',
        'hc-grey-dark': '#4a4a4a',
        // Lokeren Theme Mapping
        lokeren: {
          primary: '#121238',
          accent: '#478dcb',
          surface: '#ffffff',
          grey: '#f3f3f3',
          dark: '#4a4a4a'
        },
      },
      fontFamily: {
        'theme-title': ['var(--font-title)'],
        'theme-subtitle': ['var(--font-subtitle)'],
        'theme-links': ['var(--font-links)'],
        'theme-text': ['var(--font-text)'],
        // HC Lokeren Design Kit Fonts
        'hc-title': ['"League Spartan"', 'Montserrat', 'sans-serif'],
        'hc-subtitle': ['"Quicksand"', 'Nunito', 'sans-serif'],
        'hc-link': ['"Bebas Neue"', 'Oswald', 'sans-serif'],
        'hc-body': ['"Futura"', 'Poppins', 'sans-serif'],
      },
      fontSize: {
        'hc-title': ['2.2rem', { fontWeight: '700', lineHeight: '1.1' }],
        'hc-subtitle': ['1.4rem', { fontWeight: '600', lineHeight: '1.2' }],
        'hc-text': ['1rem', { fontWeight: '400', lineHeight: '1.5' }],
      },
      boxShadow: {
        'hc-card': '0 2px 8px rgba(0, 0, 0, 0.1)',
        'shadow-card': '0 2px 8px rgba(0, 0, 0, 0.1)',
        'shadow-card-hover': '0 4px 16px rgba(0, 0, 0, 0.15)',
      },
      borderRadius: {
        'hc-xl': '1rem',
      },
      animation: {
        'pulse-fast': 'pulse 1s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'flash': 'flash 0.5s ease-in-out',
      },
      keyframes: {
        flash: {
          '0%, 100%': { backgroundColor: 'transparent' },
          '50%': { backgroundColor: '#fbbf24' },
        }
      }
    },
  },
  plugins: [],
}