import './assets/main.css'
import '@fortawesome/fontawesome-free/css/all.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { i18n, initializeLocale } from '@/i18n'

async function initializeApp() {
  const app = createApp(App)
  
  app.use(createPinia())
  app.use(i18n)
  
  // Initialize locale settings
  initializeLocale()
  
  // Initialize theme store
  const { useThemeStore } = await import('@/stores/theme')
  const themeStore = useThemeStore()
  themeStore.initialize()
  console.log('🎨 Theme system initialized')
  
  // Initialize auth store before mounting with timeout
  console.log('� Hockey Madness loaded - Initializing auth...')
  const { useAuthStore } = await import('@/stores/auth')
  const authStore = useAuthStore()
  
  try {
    // Add timeout to prevent hanging
    await Promise.race([
      authStore.initialize(),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Auth initialization timeout')), 10000)
      )
    ])
    console.log('🏑 Auth initialization complete, setting up router')
  } catch (error) {
    console.error('🏑 Auth initialization failed or timed out:', error)
    console.log('🏑 Continuing with app setup anyway...')
  }
  
  app.use(router)
  app.mount('#app')
  console.log('🏑 App mounted successfully!')
}

initializeApp().catch((error) => {
  console.error('Failed to initialize app:', error)
})
