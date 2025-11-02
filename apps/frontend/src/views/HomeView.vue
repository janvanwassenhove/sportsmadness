<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { RouterLink, useRouter } from 'vue-router'
import { onMounted, watch } from 'vue'

console.log('🏠 HomeView component loading...')

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()

// Get role badge class for styling
function getRoleBadgeClass(role?: string) {
  switch (role) {
    case 'admin':
      return 'bg-red-100 text-red-800'
    case 'team':
      return 'bg-blue-100 text-blue-800'
    case 'user':
      return 'bg-green-100 text-green-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

// Redirect users to their appropriate dashboard if they're coming from a direct home visit
function redirectUserToDefaultPage() {
  // Only redirect if user is authenticated and has a specific role
  if (authStore.isAuthenticated && authStore.profile?.role) {
    const currentRoute = router.currentRoute.value
    
    // Don't redirect if user came from another page (has a referrer)
    if (document.referrer && !document.referrer.includes(window.location.origin + '/')) {
      return
    }
    
    // Don't redirect if there are query parameters (might be a specific intent)
    if (Object.keys(currentRoute.query).length > 0) {
      return
    }
    
    // Redirect based on role preference (optional auto-redirect)
    switch (authStore.profile.role) {
      case 'admin':
        // Admins can stay on home page to see overview
        break
      case 'user':
        // Users should probably see their dashboard
        router.replace('/dashboard')
        break
      case 'team':
        // Team members can stay on home page
        break
    }
  }
}

onMounted(() => {
  console.log('🏠 HomeView mounted successfully!')
  
  // Small delay to ensure auth is fully loaded
  setTimeout(() => {
    redirectUserToDefaultPage()
  }, 500)
})

// Watch for auth changes and redirect accordingly
watch(() => authStore.profile?.role, (newRole) => {
  if (newRole === 'user') {
    setTimeout(() => {
      redirectUserToDefaultPage()
    }, 100)
  }
})
</script>

<template>
  <div class="min-h-screen transition-colors duration-500"
       :style="{ 
         background: `linear-gradient(to bottom right, ${themeStore.currentTheme?.colors.background}, ${themeStore.currentTheme?.colors.surface})` 
       }">
    <div class="container mx-auto px-4 py-16">
      <!-- Header -->
      <div class="text-center mb-16">
        <h1 class="text-6xl font-bold mb-6 font-theme-title"
            :style="{ 
              color: themeStore.currentTheme?.colors.text,
              background: `linear-gradient(45deg, ${themeStore.currentTheme?.colors.primary}, ${themeStore.currentTheme?.colors.accent})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent'
            }">
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="inline w-16 h-16 mr-4"
          />
          <span v-else>🏒</span>
          {{ $t('home.title') }}
        </h1>
        <p class="text-xl max-w-2xl mx-auto font-theme-subtitle"
           :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
          {{ $t('home.subtitle') }}
        </p>
      </div>

      <!-- Navigation Cards -->
      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
        <!-- Public Scoreboard -->
        <RouterLink 
          to="/scoreboard" 
          class="backdrop-blur-sm rounded-xl p-8 text-center hover:scale-105 transition-all duration-300 transform border-2"
          :style="{ 
            backgroundColor: themeStore.currentTheme?.colors.surface + '40',
            borderColor: themeStore.currentTheme?.colors.primary + '40',
            color: themeStore.currentTheme?.colors.text
          }"
        >
          <div class="text-4xl mb-4">📺</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.liveScoreboard.title') }}</h2>
          <p class="text-blue-100">
            {{ $t('home.liveScoreboard.description') }}
          </p>
        </RouterLink>

        <!-- Admin Panel (if admin) -->
        <RouterLink 
          v-if="authStore.isAdmin"
          to="/admin" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">⚙️</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.tournamentAdmin.title') }}</h2>
          <p class="text-blue-100">
            {{ $t('home.tournamentAdmin.description') }}
          </p>
        </RouterLink>

        <!-- User Dashboard (if user role) -->
        <RouterLink 
          v-if="authStore.isUser"
          to="/dashboard" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">📈</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.myDashboard.title') }}</h2>
          <p class="text-blue-100">
            {{ $t('home.myDashboard.description') }}
          </p>
        </RouterLink>

        <!-- Team Profile (if team role) -->
        <RouterLink 
          v-if="authStore.isTeam"
          to="/profile" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">👥</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.myTeamProfile.title') }}</h2>
          <p class="text-blue-100">
            {{ $t('home.myTeamProfile.description') }}
          </p>
        </RouterLink>

        <!-- Theme Demo -->
        <RouterLink 
          to="/theme-demo" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">🎨</div>
          <h2 class="text-2xl font-bold text-white mb-3">Theme Demo</h2>
          <p class="text-blue-100">
            Experience different themes and color schemes
          </p>
        </RouterLink>

        <!-- Login (if not authenticated) -->
        <RouterLink 
          v-if="!authStore.isAuthenticated"
          to="/login" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">🔑</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.login.title') }}</h2>
          <p class="text-blue-100">
            {{ $t('home.login.description') }}
          </p>
        </RouterLink>

        <!-- User Profile (if regular user or admin) -->
        <RouterLink 
          v-else-if="authStore.isUser || authStore.isAdmin"
          to="/profile" 
          class="bg-white/10 backdrop-blur-sm rounded-xl p-8 text-center hover:bg-white/20 transition-all duration-300 transform hover:scale-105 border border-white/20"
        >
          <div class="text-4xl mb-4">👤</div>
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('home.profile.title') }}</h2>
          <p class="text-blue-100 mb-2">
            {{ authStore.profile?.email }}
          </p>
          <span 
            class="inline-flex px-3 py-1 text-xs font-semibold rounded-full"
            :class="getRoleBadgeClass(authStore.profile?.role)"
          >
            {{ authStore.profile?.role }}
          </span>
        </RouterLink>
      </div>

      <!-- Features -->
      <div class="mt-20 text-center">
        <h3 class="text-3xl font-bold text-white mb-12">{{ $t('features.title') }}</h3>
        <div class="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div class="text-center">
            <div class="text-3xl mb-4">⏱️</div>
            <h4 class="text-lg font-semibold text-white mb-2">{{ $t('features.liveTimer.title') }}</h4>
            <p class="text-blue-200">{{ $t('features.liveTimer.description') }}</p>
          </div>
          <div class="text-center">
            <div class="text-3xl mb-4">🎯</div>
            <h4 class="text-lg font-semibold text-white mb-2">{{ $t('features.scoreTracking.title') }}</h4>
            <p class="text-blue-200">{{ $t('features.scoreTracking.description') }}</p>
          </div>
          <div class="text-center">
            <div class="text-3xl mb-4">🎪</div>
            <h4 class="text-lg font-semibold text-white mb-2">{{ $t('features.specialEffects.title') }}</h4>
            <p class="text-blue-200">{{ $t('features.specialEffects.description') }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
