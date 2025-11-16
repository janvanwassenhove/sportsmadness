import './assets/main.css'
import '@fortawesome/fontawesome-free/css/all.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { i18n, initializeLocale } from '@/i18n'

// Global error handler for chunk loading failures
window.addEventListener('error', (event) => {
  const errorMsg = event.message || event.error?.message || ''
  
  // Check if it's a chunk loading error
  if (errorMsg.includes('Failed to fetch') || 
      errorMsg.includes('Importing a module script failed') ||
      event.filename?.includes('.js')) {
    console.error('🚨 Global chunk loading error detected:', event)
    
    const hasReloaded = sessionStorage.getItem('chunk-load-reload')
    if (!hasReloaded) {
      console.warn('🔄 Attempting page reload to fetch latest assets...')
      sessionStorage.setItem('chunk-load-reload', 'true')
      window.location.reload()
      event.preventDefault()
    } else {
      console.error('🚨 Chunk load failed even after reload')
      sessionStorage.removeItem('chunk-load-reload')
    }
  }
})

async function initializeApp() {
  const app = createApp(App)
  
  // Global Vue error handler
  app.config.errorHandler = (err, instance, info) => {
    console.error('🚨 Vue error:', err, info)
    
    // Check for chunk loading errors
    const errorMsg = (err as Error)?.message || String(err)
    if (errorMsg.includes('Failed to fetch') || 
        errorMsg.includes('dynamically imported module') ||
        errorMsg.includes('ERR_ABORTED')) {
      console.warn('🔄 Vue caught chunk loading error, reloading...')
      
      const hasReloaded = sessionStorage.getItem('chunk-load-reload')
      if (!hasReloaded) {
        sessionStorage.setItem('chunk-load-reload', 'true')
        window.location.reload()
      }
    }
  }
  
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
  console.log('🏑 Hockey Madness loaded - Initializing auth...')
  const { useAuthStore } = await import('@/stores/auth')
  const authStore = useAuthStore()
  
  try {
    // Add timeout to prevent hanging (15 seconds - should be enough for slow networks)
    await Promise.race([
      authStore.initialize(),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Auth initialization timeout')), 15000)
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
