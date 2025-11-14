import { ref, computed, watch } from 'vue'
import { defineStore } from 'pinia'
import hcLokerenLogo from '@/assets/Logo Hockey Club Lokeren transparant.png'

export interface Theme {
  id: string
  name: string
  logo?: string
  colors: {
    primary: string
    secondary: string
    accent: string
    background: string
    surface: string
    text: string
    textSecondary: string
  }
  fonts: {
    title: string
    subtitle: string
    links: string
    text: string
  }
}

export const themes: Theme[] = [
  {
    id: 'default',
    name: 'Hockey Madness',
    colors: {
      primary: '#3b82f6',     // blue-600
      secondary: '#1e40af',   // blue-800
      accent: '#f59e0b',      // amber-500
      background: '#0f172a',  // slate-900
      surface: '#1e293b',     // slate-800
      text: '#ffffff',
      textSecondary: '#cbd5e1' // slate-300
    },
    fonts: {
      title: 'Inter, system-ui, sans-serif',
      subtitle: 'Inter, system-ui, sans-serif',
      links: 'Inter, system-ui, sans-serif',
      text: 'Inter, system-ui, sans-serif'
    }
  },
  {
    id: 'hclokeren',
    name: 'HC Lokeren',
    logo: hcLokerenLogo,
    colors: {
      primary: '#121238',     // Primary dark navy blue from brand
      secondary: '#478dcb',   // Accent blue for highlights and CTAs  
      accent: '#478dcb',      // Accent blue for consistency
      background: '#f3f3f3',  // Light grey background
      surface: '#ffffff',     // White surface for cards
      text: '#121238',        // Dark navy text on light backgrounds
      textSecondary: '#4a4a4a' // Dark grey for secondary text
    },
    fonts: {
      title: "'League Spartan', 'Montserrat', sans-serif",
      subtitle: "'Quicksand', 'Nunito', sans-serif", 
      links: "'Bebas Neue', 'Oswald', sans-serif",
      text: "'Futura', 'Poppins', sans-serif"
    }
  }
]

export const useThemeStore = defineStore('theme', () => {
  // Get saved theme from localStorage or default to 'hclokeren'
  const savedThemeId = localStorage.getItem('hm-theme') || 'hclokeren'
  
  // Current theme ID
  const currentThemeId = ref(savedThemeId)
  
  // Available themes
  const availableThemes = ref(themes)
  
  // Current theme object
  const currentTheme = computed(() => {
    return availableThemes.value.find(theme => theme.id === currentThemeId.value) || availableThemes.value[0]
  })
  
  // Change theme
  function changeTheme(themeId: string) {
    const theme = availableThemes.value.find(t => t.id === themeId)
    if (theme) {
      currentThemeId.value = themeId
      localStorage.setItem('hm-theme', themeId)
      applyTheme(theme)
      console.log(`🎨 Theme changed to ${theme.name}`)
    }
  }
  
  // Apply theme to DOM
  function applyTheme(theme: Theme) {
    const root = document.documentElement
    
    // Apply CSS custom properties
    root.style.setProperty('--theme-primary', theme.colors.primary)
    root.style.setProperty('--theme-secondary', theme.colors.secondary)
    root.style.setProperty('--theme-accent', theme.colors.accent)
    root.style.setProperty('--theme-background', theme.colors.background)
    root.style.setProperty('--theme-surface', theme.colors.surface)
    root.style.setProperty('--theme-text', theme.colors.text)
    root.style.setProperty('--theme-text-secondary', theme.colors.textSecondary)
    
    // Apply font families
    root.style.setProperty('--font-title', theme.fonts.title)
    root.style.setProperty('--font-subtitle', theme.fonts.subtitle)
    root.style.setProperty('--font-links', theme.fonts.links)
    root.style.setProperty('--font-text', theme.fonts.text)
    
    // Add theme class to body
    document.body.className = document.body.className.replace(/theme-\w+/g, '')
    document.body.classList.add(`theme-${theme.id}`)
  }
  
  // Initialize theme
  function initialize() {
    const theme = availableThemes.value.find(t => t.id === currentThemeId.value) || availableThemes.value[0]
    if (theme) {
      applyTheme(theme)
    }
  }
  
  // Watch for theme changes
  watch(currentTheme, (newTheme) => {
    if (newTheme) {
      applyTheme(newTheme)
    }
  })
  
  return {
    currentThemeId,
    currentTheme,
    availableThemes,
    changeTheme,
    initialize
  }
})