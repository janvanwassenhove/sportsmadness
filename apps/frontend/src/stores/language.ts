import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { i18n, availableLocales } from '@/i18n'

export const useLanguageStore = defineStore('language', () => {
  // Get saved locale from localStorage or default to English
  const savedLocale = localStorage.getItem('hm-locale') || 'en'
  
  // Current locale
  const currentLocale = ref(savedLocale)
  
  // Available languages
  const languages = ref(availableLocales)
  
  // Current language object
  const currentLanguage = computed(() => {
    return languages.value.find(lang => lang.code === currentLocale.value) || languages.value[0]
  })
  
  // Change language
  function changeLanguage(localeCode: string) {
    const language = languages.value.find(lang => lang.code === localeCode)
    if (language) {
      currentLocale.value = localeCode
      // Directly set the locale on the i18n instance
      i18n.global.locale.value = localeCode as 'en' | 'nl' | 'fr'
      localStorage.setItem('hm-locale', localeCode)
      document.documentElement.setAttribute('lang', localeCode)
      console.log(`🌐 Language changed to ${language.name}`)
    }
  }
  
  // Initialize from saved locale
  function initialize() {
    // Set the locale on initialization
    if (availableLocales.some(l => l.code === currentLocale.value)) {
      i18n.global.locale.value = currentLocale.value as 'en' | 'nl' | 'fr'
      document.documentElement.setAttribute('lang', currentLocale.value)
    }
  }
  
  return {
    currentLocale,
    currentLanguage,
    languages,
    changeLanguage,
    initialize
  }
})