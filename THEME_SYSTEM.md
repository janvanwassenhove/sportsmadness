# Theme System Documentation

## Overview
The Hockey Madness application now includes a comprehensive theme system that allows switching between different visual themes, including a custom HC Lokeren theme.

## Available Themes

### 1. Default Theme (Hockey Madness)
- **Colors**: Blue-based color scheme with purple accents
- **Fonts**: Inter font family (system default)
- **Logo**: Hockey stick emoji 🏒
- **Target**: General hockey tournament management

### 2. HC Lokeren Theme
- **Primary Color**: `#121238` (Navy Blue)
- **Secondary Color**: `#478dcb` (Light Blue) 
- **Accent Color**: `#ffffff` (White)
- **Background**: `#0a0a1a` (Dark Navy)
- **Surface**: `#1a1a40` (Lighter Navy)
- **Logo**: Custom SVG logo with hockey sticks and club branding
- **Fonts**:
  - Title: League Spartan (fallback: Oswald)
  - Subtitle: Quicksand (fallback: Roboto Condensed)
  - Links: Bebas Neue (fallback: Ubuntu Condensed) 
  - Text: Futura (fallback: Roboto)

## Implementation Details

### Theme Store (`src/stores/theme.ts`)
The theme system is managed by a Pinia store that:
- Stores theme definitions with colors and fonts
- Manages current theme selection
- Persists theme choice in localStorage
- Applies CSS custom properties to the DOM
- Provides reactive theme switching

### Theme Switcher Component (`src/components/ThemeSwitcher.vue`)
A dropdown component that:
- Shows current theme with logo/icon
- Displays available themes with color previews
- Provides theme selection interface
- Integrates with the navigation bar

### CSS Integration
The theme system uses CSS custom properties:
```css
--theme-primary: Theme primary color
--theme-secondary: Theme secondary color  
--theme-accent: Theme accent color
--theme-background: Background color
--theme-surface: Surface/card color
--theme-text: Primary text color
--theme-text-secondary: Secondary text color

--font-title: Title font family
--font-subtitle: Subtitle font family
--font-links: Links font family
--font-text: Body text font family
```

### Tailwind Integration
Theme colors are integrated with Tailwind CSS:
```javascript
colors: {
  'theme-primary': 'var(--theme-primary)',
  'theme-secondary': 'var(--theme-secondary)',
  // etc...
}
```

## Usage

### In Components
```vue
<template>
  <!-- Use theme-aware colors -->
  <div class="bg-theme-surface text-theme-text">
    <h1 class="font-theme-title text-theme-primary">Title</h1>
    <p class="font-theme-text text-theme-text-secondary">Content</p>
  </div>
  
  <!-- Or use CSS custom properties directly -->
  <div :style="{ 
    backgroundColor: themeStore.currentTheme?.colors.surface,
    color: themeStore.currentTheme?.colors.text 
  }">
    Dynamic styling
  </div>
</template>

<script setup>
import { useThemeStore } from '@/stores/theme'
const themeStore = useThemeStore()
</script>
```

### Adding New Themes
1. Add theme definition to `themes` array in `src/stores/theme.ts`:
```typescript
{
  id: 'new-theme',
  name: 'New Theme',
  logo: '/path/to/logo.svg', // Optional
  colors: {
    primary: '#color',
    secondary: '#color',
    accent: '#color',
    background: '#color',
    surface: '#color', 
    text: '#color',
    textSecondary: '#color'
  },
  fonts: {
    title: 'Font Family',
    subtitle: 'Font Family',
    links: 'Font Family',
    text: 'Font Family'
  }
}
```

2. Add logo file to `public/` directory
3. Import fonts in `src/assets/base.css` if needed
4. Add translations for theme name if using i18n

## Font Loading
Fonts are loaded via Google Fonts in `index.html`:
- League Spartan: For HC Lokeren titles
- Bebas Neue: For HC Lokeren links/navigation
- Quicksand: For HC Lokeren subtitles
- Oswald, Ubuntu Condensed, Roboto Condensed: Fallbacks

## Theme Demo
Visit `/theme-demo` to see:
- Live theme switching
- Color palette visualization  
- Typography examples
- Interactive theme selection

## Technical Features
- ✅ Persistent theme selection (localStorage)
- ✅ Reactive theme switching
- ✅ CSS custom properties integration
- ✅ Tailwind CSS integration
- ✅ Google Fonts loading
- ✅ Logo support per theme
- ✅ Font family customization per theme
- ✅ Accessible theme switcher UI
- ✅ Mobile-responsive design
- ✅ Smooth transitions between themes
- ✅ TypeScript type safety

## Browser Support
- Modern browsers with CSS custom properties support
- Fallback fonts for systems without Google Fonts access
- Progressive enhancement approach