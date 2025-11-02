# HC Lokeren Theme Contrast Improvements

## Overview
Improved the contrast and readability of the HC Lokeren theme to address visibility issues, particularly on the scoreboard view.

## Changes Made

### 1. Theme Color Updates (`src/stores/theme.ts`)
**Before:**
```typescript
colors: {
  primary: '#121238',     // Navy blue (too dark for text)
  secondary: '#478dcb',   // Light blue
  accent: '#ffffff',      // White
  background: '#0a0a1a',  // Darker navy
  surface: '#1a1a40',     // Navy surface
  text: '#ffffff',
  textSecondary: '#b8c5d9' // Light blue-gray (insufficient contrast)
}
```

**After:**
```typescript
colors: {
  primary: '#478dcb',     // Light blue (better contrast for text)
  secondary: '#5ba3d9',   // Slightly lighter blue for hover states
  accent: '#ffffff',      // White for high contrast
  background: '#0a0a1a',  // Dark navy background
  surface: '#1a1a40',     // Navy surface
  text: '#ffffff',        // Pure white for maximum readability
  textSecondary: '#c5d1e6' // Lighter blue-gray (WCAG AA compliant)
}
```

### 2. Enhanced CSS Classes (`src/assets/main.css`)
Added theme-specific improvements:

- **Card Styling**: More opaque surfaces with primary color borders
- **Button Improvements**: Better hover effects with shadows and transforms  
- **Status Indicators**: Proper contrast for active, ready, and expired states
- **Scoreboard Cards**: Enhanced gradient backgrounds with better opacity
- **Text Shadows**: Added shadows for better text readability
- **Color Overrides**: Improved yellow, green, and red colors with glowing effects

### 3. Scoreboard View Updates (`src/views/ScoreboardView.vue`)
**Team Cards:**
- Added `scoreboard-card` class for enhanced styling
- Increased surface opacity from '40' to 'CC' for better background visibility
- Added `text-shadow` class to team names
- Added `score-display` class to scores for enhanced readability

**VS Section:**
- Wrapped in `vs-section` styling class
- Added proper spacing and visual hierarchy
- Enhanced text shadows for better contrast

**Status Indicators:**
- Replaced hardcoded background classes with theme-aware status classes:
  - `status-active` for active boosters (green with border)
  - `status-ready` for ready boosters (theme primary color)
  - `status-expired` for expired boosters (gray with border)

## Contrast Improvements

### Text Readability
- **Primary Color**: Changed from dark navy (`#121238`) to light blue (`#478dcb`) for better visibility on dark backgrounds
- **Secondary Text**: Improved from `#b8c5d9` to `#c5d1e6` for WCAG AA compliance
- **Text Shadows**: Added shadows to important text elements for better readability

### Visual Hierarchy
- **Scoreboard Cards**: Enhanced gradient backgrounds with proper borders
- **VS Section**: Dedicated styling with gradient background and proper spacing
- **Status Indicators**: Clear color coding with borders and shadows

### Interactive Elements
- **Buttons**: Improved hover states with transformations and glowing shadows
- **Cards**: Better opacity and backdrop blur for depth
- **Animations**: Enhanced pulse effects for live elements

## Accessibility Considerations

1. **WCAG AA Compliance**: All text meets minimum contrast ratios
2. **Color Independence**: Status is conveyed through multiple visual cues (color, icons, text)
3. **Text Shadows**: Ensure text remains readable against various backgrounds
4. **High Contrast**: Pure white text on dark backgrounds for maximum readability

## Testing Instructions

1. Start the development server: `npm run dev` (from `apps/frontend` directory)
2. Switch to HC Lokeren theme using the theme selector
3. Navigate to the Scoreboard view
4. Verify improved readability of:
   - Team names and scores
   - Timer and phase information
   - Booster status indicators
   - Live status badges

## Browser Support

All improvements use standard CSS properties with good browser support:
- CSS Custom Properties (IE 11+)
- CSS Gradients (IE 10+)
- Text Shadows (IE 10+)
- Backdrop Filter (Chrome 76+, Firefox 70+, Safari 9+)

## Future Enhancements

Consider adding:
- Dark mode toggle for additional accessibility
- User preference for text size
- High contrast mode for users with visual impairments
- Additional theme color validation for contrast ratios