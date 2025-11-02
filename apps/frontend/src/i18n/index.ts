import { createI18n } from 'vue-i18n'
import en from './locales/en.json'
import nl from './locales/nl.json'
import fr from './locales/fr.json'

// Get saved locale from localStorage or default to English
const savedLocale = localStorage.getItem('hm-locale') || 'en'

export const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: savedLocale,
  fallbackLocale: 'en',
  globalInjection: true, // Allow $t in templates without importing useI18n
  messages: {
    en,
    nl,
    fr
  }
})

// Available languages with their display names and flags
export const availableLocales = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'nl', name: 'Nederlands', flag: '🇳🇱' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' }
]

// Helper function to change locale
export function setLocale(locale: string) {
  if (availableLocales.some(l => l.code === locale)) {
    i18n.global.locale.value = locale as 'en' | 'nl' | 'fr'
    localStorage.setItem('hm-locale', locale)
    document.documentElement.setAttribute('lang', locale)
  }
}

// Initialize locale on app start
export function initializeLocale() {
  const locale = i18n.global.locale.value
  document.documentElement.setAttribute('lang', locale)
}