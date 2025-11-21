<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed, onErrorCaptured, ref } from 'vue'
import AppNavigation from '@/components/AppNavigation.vue'
import AppFooter from '@/components/AppFooter.vue'

const route = useRoute()
const hasError = ref(false)
const errorMessage = ref('')

// Hide navigation and footer on scoreboard view for full-screen display
const showNavigationAndFooter = computed(() => {
  return route.name !== 'scoreboard' && route.name !== 'scoreboard-match'
})

// Capture errors in child components
onErrorCaptured((err, instance, info) => {
  console.error('App error captured:', err, info)
  
  const errorMsg = (err as Error)?.message || String(err)
  
  // Check if it's a chunk loading error
  if (errorMsg.includes('Failed to fetch') || 
      errorMsg.includes('dynamically imported module') ||
      errorMsg.includes('ERR_ABORTED') ||
      errorMsg.includes('Loading chunk') ||
      errorMsg.includes('ChunkLoadError')) {
    console.warn('🔄 Chunk loading error in component, attempting reload...')
    
    const hasReloaded = sessionStorage.getItem('chunk-load-reload')
    if (!hasReloaded) {
      sessionStorage.setItem('chunk-load-reload', 'true')
      console.log('🔄 Reloading page due to chunk loading error...')
      window.location.reload()
      return false // Prevent error from propagating
    } else {
      hasError.value = true
      errorMessage.value = 'Failed to load application resources. This may be due to a recent update. Please clear your browser cache and refresh the page.'
      console.error('🚨 Chunk loading failed even after reload')
      sessionStorage.removeItem('chunk-load-reload')
    }
  } else {
    // Other types of errors
    hasError.value = true
    errorMessage.value = `Application error: ${errorMsg}`
    console.error('🚨 General application error:', err)
  }
  
  return false // Prevent error from propagating to parent
})

function clearCacheAndReload() {
  sessionStorage.clear()
  window.location.reload()
}
</script>

<template>
  <div id="app" class="min-h-screen flex flex-col">
    <!-- Error State -->
    <div v-if="hasError" class="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-700 flex items-center justify-center p-4">
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 max-w-md border border-white/20 text-center">
        <div class="text-6xl mb-4">⚠️</div>
        <h1 class="text-2xl font-bold text-white mb-4">Application Error</h1>
        <p class="text-white/90 mb-6">{{ errorMessage }}</p>
        <button 
          @click="clearCacheAndReload"
          class="bg-white text-red-900 px-6 py-3 rounded-lg font-semibold hover:bg-red-50 transition-colors"
        >
          Clear Cache & Reload
        </button>
      </div>
    </div>
    
    <!-- Normal App -->
    <template v-else>
      <AppNavigation v-if="showNavigationAndFooter" />
      <main class="flex-1">
        <Suspense>
          <RouterView />
          <template #fallback>
            <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 flex items-center justify-center">
              <div class="text-center">
                <div class="animate-spin rounded-full h-16 w-16 border-b-4 border-white mx-auto mb-4"></div>
                <p class="text-white text-xl">Loading...</p>
              </div>
            </div>
          </template>
        </Suspense>
      </main>
      <AppFooter v-if="showNavigationAndFooter" />
    </template>
  </div>
</template>

<style>
html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}

#app {
  min-height: 100vh;
}
</style>
