<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-white mb-4">
          🎮 {{ $t('gameGuide.title') }}
        </h1>
        <p class="text-xl text-blue-100">
          {{ $t('gameGuide.subtitle') }}
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
        <p class="text-blue-200">{{ $t('gameGuide.loading') }}</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-12">
        <div class="text-6xl mb-4">⚠️</div>
        <p class="text-xl text-white mb-2">{{ $t('gameGuide.error') }}</p>
        <p class="text-blue-200">{{ error }}</p>
        <button 
          @click="loadData"
          class="mt-4 bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg transition-colors"
        >
          {{ $t('gameGuide.retry') }}
        </button>
      </div>

      <!-- Content -->
      <div v-else class="max-w-6xl mx-auto space-y-8">
        
        <!-- Boosters Section -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 border border-white/20">
          <div class="flex items-center mb-6">
            <h2 class="text-3xl font-bold text-white">⚡ {{ $t('gameGuide.boosters.title') }}</h2>
          </div>
          
          <p class="text-blue-100 text-lg mb-6">
            {{ $t('gameGuide.boosters.description') }}
          </p>

          <!-- No Boosters -->
          <div v-if="boosters.length === 0" class="text-center py-8">
            <div class="text-4xl mb-4">📦</div>
            <p class="text-blue-200">{{ $t('gameGuide.boosters.noBoosters') }}</p>
          </div>

          <!-- Boosters Grid -->
          <div v-else class="grid md:grid-cols-2 gap-6">
            <div 
              v-for="booster in boosters" 
              :key="booster.id"
              class="bg-white/5 hover:bg-white/10 rounded-lg p-6 border border-white/10 transition-all duration-300 hover:scale-105 hover:shadow-xl"
            >
              <div class="flex items-start space-x-4">
                <!-- Icon -->
                <div class="text-5xl flex-shrink-0">
                  {{ booster.icon || '⚡' }}
                </div>
                
                <!-- Content -->
                <div class="flex-1">
                  <h3 class="text-xl font-bold text-white mb-2">
                    {{ booster.title }}
                  </h3>
                  <p class="text-blue-100 mb-4">
                    {{ booster.description }}
                  </p>
                  
                  <!-- Duration Info -->
                  <div class="flex items-center space-x-4 text-sm">
                    <div v-if="booster.has_countdown" class="flex items-center space-x-2 text-blue-200">
                      <span>⏱️</span>
                      <span>{{ $t('gameGuide.duration') }}: {{ formatDuration(booster.duration) }}</span>
                    </div>
                    <div v-else class="flex items-center space-x-2 text-yellow-300">
                      <span>⚡</span>
                      <span>{{ $t('gameGuide.instant') }}</span>
                    </div>
                  </div>

                  <!-- Picture if available -->
                  <div v-if="booster.picture" class="mt-4">
                    <img 
                      :src="booster.picture" 
                      :alt="booster.title"
                      class="w-full h-32 object-cover rounded-lg"
                      @error="handleImageError"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Maddies Section -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 border border-white/20">
          <div class="flex items-center mb-6">
            <h2 class="text-3xl font-bold text-white">🎪 {{ $t('gameGuide.maddies.title') }}</h2>
          </div>
          
          <p class="text-blue-100 text-lg mb-6">
            {{ $t('gameGuide.maddies.description') }}
          </p>

          <!-- No Maddies -->
          <div v-if="maddies.length === 0" class="text-center py-8">
            <div class="text-4xl mb-4">📦</div>
            <p class="text-blue-200">{{ $t('gameGuide.maddies.noMaddies') }}</p>
          </div>

          <!-- Maddies Grid -->
          <div v-else class="grid md:grid-cols-2 gap-6">
            <div 
              v-for="maddie in maddies" 
              :key="maddie.id"
              class="bg-gradient-to-br from-purple-500/20 to-pink-500/20 hover:from-purple-500/30 hover:to-pink-500/30 rounded-lg p-6 border border-purple-300/30 transition-all duration-300 hover:scale-105 hover:shadow-xl"
            >
              <div class="flex items-start space-x-4">
                <!-- Icon -->
                <div class="text-5xl flex-shrink-0">
                  {{ maddie.icon || '🎪' }}
                </div>
                
                <!-- Content -->
                <div class="flex-1">
                  <h3 class="text-xl font-bold text-white mb-2">
                    {{ maddie.title }}
                  </h3>
                  <p class="text-blue-100 mb-4">
                    {{ maddie.description }}
                  </p>
                  
                  <!-- Duration Info -->
                  <div class="flex items-center space-x-2 text-sm text-purple-200">
                    <span>⏱️</span>
                    <span>{{ $t('gameGuide.duration') }}: {{ formatDuration(maddie.duration) }}</span>
                  </div>

                  <!-- Picture if available -->
                  <div v-if="maddie.picture" class="mt-4">
                    <img 
                      :src="maddie.picture" 
                      :alt="maddie.title"
                      class="w-full h-32 object-cover rounded-lg"
                      @error="handleImageError"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Strategy Tips -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 border border-white/20">
          <h2 class="text-3xl font-bold text-white mb-6">💡 {{ $t('gameGuide.tips.title') }}</h2>
          
          <div class="grid md:grid-cols-2 gap-6">
            <div class="bg-white/5 rounded-lg p-6">
              <h3 class="text-xl font-semibold text-white mb-3 flex items-center">
                <span class="mr-2">🎯</span>
                {{ $t('gameGuide.tips.timing.title') }}
              </h3>
              <p class="text-blue-100">
                {{ $t('gameGuide.tips.timing.description') }}
              </p>
            </div>

            <div class="bg-white/5 rounded-lg p-6">
              <h3 class="text-xl font-semibold text-white mb-3 flex items-center">
                <span class="mr-2">🤝</span>
                {{ $t('gameGuide.tips.teamwork.title') }}
              </h3>
              <p class="text-blue-100">
                {{ $t('gameGuide.tips.teamwork.description') }}
              </p>
            </div>

            <div class="bg-white/5 rounded-lg p-6">
              <h3 class="text-xl font-semibold text-white mb-3 flex items-center">
                <span class="mr-2">🎪</span>
                {{ $t('gameGuide.tips.adaptation.title') }}
              </h3>
              <p class="text-blue-100">
                {{ $t('gameGuide.tips.adaptation.description') }}
              </p>
            </div>

            <div class="bg-white/5 rounded-lg p-6">
              <h3 class="text-xl font-semibold text-white mb-3 flex items-center">
                <span class="mr-2">📊</span>
                {{ $t('gameGuide.tips.strategy.title') }}
              </h3>
              <p class="text-blue-100">
                {{ $t('gameGuide.tips.strategy.description') }}
              </p>
            </div>
          </div>
        </div>

        <!-- Back to Dashboard Button -->
        <div class="text-center py-6">
          <RouterLink 
            to="/dashboard" 
            class="inline-flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 rounded-lg font-medium transition-colors"
          >
            <span>←</span>
            <span>{{ $t('gameGuide.backToDashboard') }}</span>
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface Booster {
  id: string
  title: string
  description: string
  icon: string | null
  picture: string | null
  has_countdown: boolean
  duration: number
  created_at: string
  updated_at: string
}

interface Maddie {
  id: string
  title: string
  description: string
  icon: string | null
  picture: string | null
  duration: number
  created_at: string
  updated_at: string
}

const boosters = ref<Booster[]>([])
const maddies = ref<Maddie[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

// Load boosters from database
async function loadBoosters() {
  try {
    const { data, error: boostersError } = await supabase
      .from('boosters')
      .select('*')
      .order('title', { ascending: true })

    if (boostersError) throw boostersError
    boosters.value = data || []
  } catch (err) {
    console.error('Error loading boosters:', err)
    throw err
  }
}

// Load maddies from database
async function loadMaddies() {
  try {
    const { data, error: maddiesError } = await supabase
      .from('maddies')
      .select('*')
      .order('title', { ascending: true })

    if (maddiesError) throw maddiesError
    maddies.value = data || []
  } catch (err) {
    console.error('Error loading maddies:', err)
    throw err
  }
}

// Load all data
async function loadData() {
  loading.value = true
  error.value = null
  
  try {
    await Promise.all([
      loadBoosters(),
      loadMaddies()
    ])
  } catch (err: any) {
    error.value = err.message || 'Failed to load game data'
  } finally {
    loading.value = false
  }
}

// Format duration in seconds to readable format
function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${seconds}s`
  }
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  if (remainingSeconds === 0) {
    return `${minutes}m`
  }
  return `${minutes}m ${remainingSeconds}s`
}

// Handle image loading errors
function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  img.style.display = 'none'
}

// Initialize
onMounted(() => {
  loadData()
})
</script>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
