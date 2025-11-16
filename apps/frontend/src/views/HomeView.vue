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
      return 'role-badge-admin'
    case 'team':
      return 'role-badge-team'
    case 'user':
      return 'role-badge-user'
    default:
      return 'role-badge-default'
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
        // Users should see their dashboard
        router.replace('/dashboard')
        break
      case 'team':
        // Team members should stay on home page - no redirect needed
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
        <h1 class="home-title font-theme-title">
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="inline w-16 h-16 mr-4"
          />
          <span v-else class="text-6xl">🏑</span>
          {{ $t('home.title') }}
        </h1>
        <p class="home-subtitle font-theme-subtitle">
          {{ $t('home.subtitle') }}
        </p>
      </div>

      <!-- Navigation Cards -->
      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
        <!-- Public Scoreboard -->
        <RouterLink 
          to="/scoreboard" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">📺</div>
          <h2 class="nav-card-title">{{ $t('home.liveScoreboard.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.liveScoreboard.description') }}
          </p>
        </RouterLink>

        <!-- Admin Panel (if admin) -->
        <RouterLink 
          v-if="authStore.isAdmin"
          to="/admin" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">⚙️</div>
          <h2 class="nav-card-title">{{ $t('home.tournamentAdmin.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.tournamentAdmin.description') }}
          </p>
        </RouterLink>

        <!-- User Dashboard (if user role) -->
        <RouterLink 
          v-if="authStore.isUser"
          to="/dashboard" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">📈</div>
          <h2 class="nav-card-title">{{ $t('home.myDashboard.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.myDashboard.description') }}
          </p>
        </RouterLink>

        <!-- Team Profile (if team role) -->
        <RouterLink 
          v-if="authStore.isTeam"
          to="/profile" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">👥</div>
          <h2 class="nav-card-title">{{ $t('home.myTeamProfile.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.myTeamProfile.description') }}
          </p>
        </RouterLink>

        <!-- Team Dashboard (if team role) -->
        <RouterLink 
          v-if="authStore.isTeam"
          to="/dashboard" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">📅</div>
          <h2 class="nav-card-title">{{ $t('home.myDashboard.title') }}</h2>
          <p class="nav-card-description">
            View your upcoming matches and team statistics
          </p>
        </RouterLink>

        <!-- Theme Demo (Admin only) -->
        <RouterLink 
          v-if="authStore.isAdmin"
          to="/theme-demo" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">🎨</div>
          <h2 class="nav-card-title">Theme Demo</h2>
          <p class="nav-card-description">
            Experience different themes and color schemes
          </p>
        </RouterLink>

        <!-- Login (if not authenticated) -->
        <RouterLink 
          v-if="!authStore.isAuthenticated"
          to="/login" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">🔑</div>
          <h2 class="nav-card-title">{{ $t('home.login.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.login.description') }}
          </p>
        </RouterLink>

        <!-- User Profile (if regular user or admin) -->
        <RouterLink 
          v-else-if="authStore.isUser || authStore.isAdmin"
          to="/profile" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">👤</div>
          <h2 class="nav-card-title">{{ $t('home.profile.title') }}</h2>
          <p class="nav-card-description mb-2">
            {{ authStore.profile?.email }}
          </p>
          <span 
            class="role-badge"
            :class="getRoleBadgeClass(authStore.profile?.role)"
          >
            {{ authStore.profile?.role }}
          </span>
        </RouterLink>
      </div>

      <!-- Features -->
      <div class="mt-20 text-center">
        <h3 class="features-title">{{ $t('features.title') }}</h3>
        <div class="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div class="feature-item text-center">
            <div class="text-3xl mb-4">⏱️</div>
            <h4>{{ $t('features.liveTimer.title') }}</h4>
            <p>{{ $t('features.liveTimer.description') }}</p>
          </div>
          <div class="feature-item text-center">
            <div class="text-3xl mb-4">🎯</div>
            <h4>{{ $t('features.scoreTracking.title') }}</h4>
            <p>{{ $t('features.scoreTracking.description') }}</p>
          </div>
          <div class="feature-item text-center">
            <div class="text-3xl mb-4">🎪</div>
            <h4>{{ $t('features.specialEffects.title') }}</h4>
            <p>{{ $t('features.specialEffects.description') }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
