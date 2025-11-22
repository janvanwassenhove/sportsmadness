<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 text-white">
    <div class="container mx-auto px-4 py-8">
      <div class="text-center">
        <h1 class="text-6xl font-bold mb-8">🏒 Hockey Madness</h1>
        <h2 class="text-4xl font-bold mb-6">Scoreboard Test</h2>
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 max-w-2xl mx-auto">
          <p class="text-xl mb-4">✅ Scoreboard component is loading successfully!</p>
          <p class="text-lg mb-4">Current URL: {{ currentUrl }}</p>
          <p class="text-lg mb-4">Base URL: {{ baseUrl }}</p>
          <p class="text-lg mb-4">Environment: {{ environment }}</p>
          <div class="mt-6 space-y-2">
            <button 
              @click="testFunction" 
              class="bg-green-600 hover:bg-green-700 px-6 py-3 rounded-lg font-semibold mx-2"
            >
              Test Function
            </button>
            <button 
              @click="goToActualScoreboard" 
              class="bg-blue-600 hover:bg-blue-700 px-6 py-3 rounded-lg font-semibold mx-2"
            >
              Load Full Scoreboard
            </button>
          </div>
          <div v-if="testResult" class="mt-4 p-4 bg-green-500/20 rounded">
            <p>{{ testResult }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const testResult = ref('')

const currentUrl = computed(() => window.location.href)
const baseUrl = computed(() => import.meta.env.BASE_URL)
const environment = computed(() => import.meta.env.PROD ? 'production' : 'development')

function testFunction() {
  testResult.value = `Test successful at ${new Date().toLocaleTimeString()}`
  console.log('✅ Test scoreboard function working')
}

function goToActualScoreboard() {
  // Try to navigate to the actual scoreboard
  console.log('🔄 Attempting to load full ScoreboardView...')
  // We'll implement this after testing
  testResult.value = 'Full scoreboard loading not implemented yet - this is just a test component'
}
</script>