<template>
  <nav class="bg-gradient-to-r from-blue-900 via-purple-900 to-indigo-900 shadow-lg sticky top-0 z-50 backdrop-blur-sm bg-opacity-95">
    <div class="container mx-auto px-4">
      <div class="flex justify-between items-center py-4">
        <!-- Logo/Brand -->
        <div class="flex items-center space-x-3">
          <RouterLink to="/" class="flex items-center space-x-3 hover:opacity-80 transition-opacity">
            <img 
              v-if="themeStore.currentTheme?.logo" 
              :src="themeStore.currentTheme.logo" 
              :alt="themeStore.currentTheme.name"
              class="w-8 h-8"
            />
            <div v-else class="text-2xl">🏑</div>
            <span class="text-xl font-bold text-white font-theme-title">
              {{ themeStore.currentTheme?.name || 'Hockey Madness' }}
            </span>
          </RouterLink>
        </div>

        <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center space-x-6">
          <!-- Public Links -->
          <RouterLink 
            to="/" 
            class="nav-link"
            :class="{ 'nav-link-active': $route.name === 'home' }"
          >
            {{ $t('navigation.home') }}
          </RouterLink>
          <button
            @click="navigateToScoreboard" 
            class="nav-link"
            :class="{ 'nav-link-active': $route.name === 'scoreboard' || $route.name === 'scoreboard-match' }"
          >
            {{ $t('navigation.scoreboard') }}
          </button>
          <RouterLink 
            to="/game-guide" 
            class="nav-link"
            :class="{ 'nav-link-active': $route.name === 'game-guide' }"
          >
            {{ $t('navigation.gameGuide') }}
          </RouterLink>

          <!-- Admin Links (when authenticated) -->
          <template v-if="authStore.isAuthenticated && authStore.isAdmin">
            <div class="relative" ref="adminDropdownRef">
              <button
                @click="showAdminDropdown = !showAdminDropdown"
                class="nav-link flex items-center space-x-1"
                :class="{ 'nav-link-active': isAdminRoute }"
              >
                <span>{{ $t('navigation.admin') }}</span>
                <svg 
                  class="w-4 h-4 transition-transform duration-200"
                  :class="{ 'rotate-180': showAdminDropdown }"
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                </svg>
              </button>
              
              <!-- Admin Dropdown -->
              <div 
                v-show="showAdminDropdown"
                class="absolute right-0 mt-2 w-48 bg-white/95 backdrop-blur-sm rounded-lg shadow-lg border border-white/20 py-2 z-50"
              >
                <RouterLink 
                  to="/admin"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">📊</span>
                  {{ $t('navigation.dashboard') }}
                </RouterLink>
                <RouterLink 
                  to="/admin/tournaments"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">🏆</span>
                  {{ $t('navigation.tournaments') }}
                </RouterLink>
                <RouterLink 
                  to="/admin/teams"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">👥</span>
                  {{ $t('navigation.teams') }}
                </RouterLink>
                <RouterLink 
                  to="/admin/boosters"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">⚡</span>
                  {{ $t('navigation.boosters') }}
                </RouterLink>
                <RouterLink 
                  to="/admin/rules"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">📋</span>
                  {{ $t('navigation.rules') }}
                </RouterLink>
                <RouterLink 
                  to="/admin/users"
                  class="dropdown-link"
                  @click="showAdminDropdown = false"
                >
                  <span class="text-lg mr-2">👤</span>
                  {{ $t('navigation.userManagement') }}
                </RouterLink>
              </div>
            </div>
          </template>

          <!-- User Dashboard Link (for regular users and team members) -->
          <template v-if="authStore.isAuthenticated && (authStore.isUser || authStore.isTeam)">
            <RouterLink 
              to="/dashboard" 
              class="nav-link"
              :class="{ 'nav-link-active': $route.name === 'user-dashboard' }"
            >
              <span class="mr-2">📈</span>
              {{ $t('navigation.dashboard') }}
            </RouterLink>
            <RouterLink 
              to="/game-guide" 
              class="nav-link"
              :class="{ 'nav-link-active': $route.name === 'game-guide' }"
            >
              <span class="mr-2">🎮</span>
              {{ $t('navigation.gameGuide') }}
            </RouterLink>
          </template>

          <!-- Theme Switcher -->
          <ThemeSwitcher />

          <!-- Language Selector -->
          <div class="relative" ref="languageDropdownRef">
            <button
              @click="showLanguageDropdown = !showLanguageDropdown"
              class="flex items-center justify-center w-10 h-10 rounded-lg transition-colors hover:bg-white/10 text-white font-semibold text-sm"
              :title="$t('navigation.language')"
            >
              {{ languageStore.currentLanguage?.code?.toUpperCase() || 'EN' }}
            </button>
            
            <!-- Language Dropdown -->
            <div 
              v-show="showLanguageDropdown"
              class="absolute right-0 mt-2 w-48 bg-white/95 backdrop-blur-sm rounded-lg shadow-lg border border-white/20 py-2 z-50"
            >
              <button
                v-for="language in languageStore.languages"
                :key="language.code"
                @click="languageStore.changeLanguage(language.code); showLanguageDropdown = false"
                class="dropdown-link w-full text-left"
                :class="{ 'bg-blue-50 text-blue-600': languageStore.currentLocale === language.code }"
              >
                <span class="text-lg mr-2">{{ language.flag }}</span>
                {{ language.name }}
              </button>
            </div>
          </div>

          <!-- Auth Section -->
          <div class="flex items-center space-x-4 ml-6 pl-6 border-l border-white/20">
            <template v-if="authStore.isAuthenticated">
              <!-- User Profile Dropdown -->
              <div class="relative" ref="userDropdownRef">
                <button
                  @click="showUserDropdown = !showUserDropdown"
                  class="flex items-center space-x-2 text-sm text-blue-200 hover:text-white transition-colors"
                >
                  <span>{{ authStore.profile?.email }}</span>
                  <span 
                    class="inline-flex px-2 py-1 text-xs font-semibold rounded-full"
                    :class="getRoleBadgeClass(authStore.profile?.role)"
                  >
                    {{ authStore.profile?.role }}
                  </span>
                  <svg 
                    class="w-4 h-4 transition-transform duration-200"
                    :class="{ 'rotate-180': showUserDropdown }"
                    fill="none" 
                    stroke="currentColor" 
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                  </svg>
                </button>
                
                <!-- User Dropdown -->
                <div 
                  v-show="showUserDropdown"
                  class="absolute right-0 mt-2 w-48 bg-white/95 backdrop-blur-sm rounded-lg shadow-lg border border-white/20 py-2 z-50"
                >
                  <RouterLink 
                    v-if="authStore.isUser"
                    to="/dashboard"
                    class="dropdown-link"
                    @click="showUserDropdown = false"
                  >
                    <span class="text-lg mr-2">📈</span>
                    {{ $t('navigation.dashboard') }}
                  </RouterLink>
                  <RouterLink 
                    to="/profile"
                    class="dropdown-link"
                    @click="showUserDropdown = false"
                  >
                    <span class="text-lg mr-2">👤</span>
                    {{ $t('navigation.profile') }}
                  </RouterLink>
                  <div class="border-t border-gray-200 my-1"></div>
                  <button 
                    @click="authStore.signOut(); showUserDropdown = false"
                    class="dropdown-link w-full text-left text-red-600 hover:text-red-700 hover:bg-red-50"
                  >
                    <span class="text-lg mr-2">🚪</span>
                    {{ $t('navigation.logout') }}
                  </button>
                </div>
              </div>
            </template>
            <template v-else>
              <RouterLink 
                to="/login" 
                class="btn btn-primary text-sm"
              >
                {{ $t('navigation.login') }}
              </RouterLink>
            </template>
          </div>
        </div>

        <!-- Mobile Menu Button -->
        <button
          @click="showMobileMenu = !showMobileMenu"
          class="md:hidden flex items-center justify-center w-10 h-10 rounded-lg bg-white/10 hover:bg-white/20 transition-colors"
          aria-label="Toggle menu"
        >
          <svg 
            class="w-6 h-6 text-white transition-transform duration-200"
            :class="{ 'rotate-90': showMobileMenu }"
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
          >
            <path 
              v-if="!showMobileMenu"
              stroke-linecap="round" 
              stroke-linejoin="round" 
              stroke-width="2" 
              d="M4 6h16M4 12h16M4 18h16"
            ></path>
            <path 
              v-else
              stroke-linecap="round" 
              stroke-linejoin="round" 
              stroke-width="2" 
              d="M6 18L18 6M6 6l12 12"
            ></path>
          </svg>
        </button>
      </div>

      <!-- Mobile Menu -->
      <div 
        v-show="showMobileMenu"
        class="md:hidden border-t border-white/20 py-4 space-y-2"
      >
        <!-- Public Links -->
        <RouterLink 
          to="/" 
          class="mobile-nav-link"
          :class="{ 'mobile-nav-link-active': $route.name === 'home' }"
          @click="showMobileMenu = false"
        >
          <span class="text-lg mr-2">🏠</span>
          {{ $t('navigation.home') }}
        </RouterLink>
        <button
          @click="navigateToScoreboard(); showMobileMenu = false" 
          class="mobile-nav-link text-left w-full"
          :class="{ 'mobile-nav-link-active': $route.name === 'scoreboard' || $route.name === 'scoreboard-match' }"
        >
          <span class="text-lg mr-2">📊</span>
          {{ $t('navigation.scoreboard') }}
        </button>
        <RouterLink 
          to="/game-guide" 
          class="mobile-nav-link"
          :class="{ 'mobile-nav-link-active': $route.name === 'game-guide' }"
          @click="showMobileMenu = false"
        >
          <span class="text-lg mr-2">🎮</span>
          {{ $t('navigation.gameGuide') }}
        </RouterLink>

        <!-- Admin Links (when authenticated) -->
        <template v-if="authStore.isAuthenticated && authStore.isAdmin">
          <div class="border-t border-white/10 pt-2 mt-2">
            <div class="px-3 py-2 text-xs font-semibold text-blue-200 uppercase tracking-wider">
              {{ $t('navigation.admin') }}
            </div>
            <RouterLink 
              to="/admin"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">📊</span>
              {{ $t('navigation.dashboard') }}
            </RouterLink>
            <RouterLink 
              to="/admin/tournaments"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">🏆</span>
              {{ $t('navigation.tournaments') }}
            </RouterLink>
            <RouterLink 
              to="/admin/teams"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">👥</span>
              {{ $t('navigation.teams') }}
            </RouterLink>
            <RouterLink 
              to="/admin/boosters"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">⚡</span>
              {{ $t('navigation.boosters') }}
            </RouterLink>
            <RouterLink 
              to="/admin/rules"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">📋</span>
              {{ $t('navigation.rules') }}
            </RouterLink>
            <RouterLink 
              to="/admin/users"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">👤</span>
              {{ $t('navigation.userManagement') }}
            </RouterLink>
          </div>
        </template>

        <!-- User Dashboard Links (for regular users and team members) -->
        <template v-if="authStore.isAuthenticated && (authStore.isUser || authStore.isTeam)">
          <div class="border-t border-white/10 pt-2 mt-2">
            <div class="px-3 py-2 text-xs font-semibold text-blue-200 uppercase tracking-wider">
              {{ $t('navigation.dashboard') }}
            </div>
            <RouterLink 
              to="/dashboard" 
              class="mobile-nav-link"
              :class="{ 'mobile-nav-link-active': $route.name === 'user-dashboard' }"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">📈</span>
              {{ $t('navigation.dashboard') }}
            </RouterLink>
            <RouterLink 
              to="/game-guide" 
              class="mobile-nav-link"
              :class="{ 'mobile-nav-link-active': $route.name === 'game-guide' }"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">🎮</span>
              {{ $t('navigation.gameGuide') }}
            </RouterLink>
          </div>
        </template>

        <!-- Auth Section -->
        <div class="border-t border-white/10 pt-2 mt-2">
          <template v-if="authStore.isAuthenticated">
            <div class="px-3 py-2 text-sm text-blue-200 flex items-center justify-between">
              <span>{{ authStore.profile?.email }}</span>
              <span 
                class="inline-flex px-2 py-1 text-xs font-semibold rounded-full"
                :class="getRoleBadgeClass(authStore.profile?.role)"
              >
                {{ authStore.profile?.role }}
              </span>
            </div>
            <RouterLink 
              v-if="authStore.isUser"
              to="/dashboard"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">📈</span>
              {{ $t('navigation.dashboard') }}
            </RouterLink>
            <RouterLink 
              to="/profile"
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">👤</span>
              {{ $t('navigation.profile') }}
            </RouterLink>
            <button 
              @click="authStore.signOut(); showMobileMenu = false"
              class="mobile-nav-link text-left w-full text-red-300 hover:text-red-100"
            >
              <span class="text-lg mr-2">🚪</span>
              {{ $t('navigation.logout') }}
            </button>
          </template>
          <template v-else>
            <RouterLink 
              to="/login" 
              class="mobile-nav-link"
              @click="showMobileMenu = false"
            >
              <span class="text-lg mr-2">🔐</span>
              {{ $t('navigation.login') }}
            </RouterLink>
          </template>
        </div>

        <!-- Language Selector (Mobile) -->
        <div class="border-t border-white/10 pt-2 mt-2">
          <div class="px-3 py-2 text-xs font-semibold text-blue-200 uppercase tracking-wider">
            {{ $t('navigation.language') }}
          </div>
          <button
            v-for="language in languageStore.languages"
            :key="language.code"
            @click="languageStore.changeLanguage(language.code); showMobileMenu = false"
            class="mobile-nav-link text-left w-full"
            :class="{ 'text-yellow-300': languageStore.currentLocale === language.code }"
          >
            <span class="text-lg mr-2">{{ language.flag }}</span>
            {{ language.name }}
          </button>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useLanguageStore } from '@/stores/language'
import { useThemeStore } from '@/stores/theme'
import { supabase } from '@/lib/supabase'
import ThemeSwitcher from './ThemeSwitcher.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const languageStore = useLanguageStore()
const themeStore = useThemeStore()

const showMobileMenu = ref(false)
const showAdminDropdown = ref(false)
const showUserDropdown = ref(false)
const showLanguageDropdown = ref(false)
const adminDropdownRef = ref<HTMLElement>()
const userDropdownRef = ref<HTMLElement>()
const languageDropdownRef = ref<HTMLElement>()

const isAdminRoute = computed(() => {
  return route.path.startsWith('/admin')
})

// Get role badge class for styling
function getRoleBadgeClass(role?: string) {
  switch (role) {
    case 'admin':
      return 'bg-red-100 text-red-800'
    case 'team':
      return 'bg-blue-100 text-blue-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

// Close dropdowns when clicking outside
function handleClickOutside(event: MouseEvent) {
  if (adminDropdownRef.value && !adminDropdownRef.value.contains(event.target as Node)) {
    showAdminDropdown.value = false
  }
  if (userDropdownRef.value && !userDropdownRef.value.contains(event.target as Node)) {
    showUserDropdown.value = false
  }
  if (languageDropdownRef.value && !languageDropdownRef.value.contains(event.target as Node)) {
    showLanguageDropdown.value = false
  }
}

// Navigate to scoreboard with match selection logic
async function navigateToScoreboard() {
  try {
    // Check for multiple active/paused matches
    const { data: activeMatches, error } = await supabase
      .from('matches')
      .select('*')
      .in('status', ['active', 'paused'])

    if (error) {
      console.error('Error loading active matches:', error)
      // Fallback to normal navigation
      router.push('/scoreboard')
      return
    }

    if (activeMatches && activeMatches.length > 1) {
      // Multiple active matches - go to scoreboard without ID to show selector
      router.push('/scoreboard')
    } else if (activeMatches && activeMatches.length === 1) {
      // Single active match - go directly to that match
      router.push(`/scoreboard/${activeMatches[0].id}`)
    } else {
      // No active matches - check for initialized pending matches
      const { data: pendingMatches, error: pendingError } = await supabase
        .from('matches')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', { ascending: false })

      if (pendingError) {
        console.error('Error loading pending matches:', pendingError)
        router.push('/scoreboard')
        return
      }

      if (pendingMatches && pendingMatches.length > 0) {
        // Filter initialized matches
        const initializedMatches = pendingMatches.filter(match => {
          const hasConfirmedBoosters = (
            match.boosters?.teamA?.length > 0 || 
            match.boosters?.teamB?.length > 0
          )
          const hasCards = Object.keys(match.cards || {}).length > 0
          const hasScores = match.score_a > 0 || match.score_b > 0
          const hasModifiedTime = match.time_left !== 1800
          
          return hasConfirmedBoosters || hasCards || hasScores || hasModifiedTime
        })

        if (initializedMatches.length > 1) {
          // Multiple initialized matches - show selector
          router.push('/scoreboard')
        } else if (initializedMatches.length === 1) {
          // Single initialized match - go directly to it
          router.push(`/scoreboard/${initializedMatches[0].id}`)
        } else if (pendingMatches.length > 1) {
          // Multiple pending matches - show selector
          router.push('/scoreboard')
        } else {
          // Single or no matches - go to general scoreboard
          router.push('/scoreboard')
        }
      } else {
        // No matches at all
        router.push('/scoreboard')
      }
    }
  } catch (error) {
    console.error('Error in navigateToScoreboard:', error)
    // Fallback to normal navigation
    router.push('/scoreboard')
  }
}

// Close mobile menu on route change
function handleRouteChange() {
  showMobileMenu.value = false
  showAdminDropdown.value = false
  showUserDropdown.value = false
  showLanguageDropdown.value = false
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

// Watch for route changes and close menus
watch(route, handleRouteChange)

// Close mobile menu when ESC is pressed
function handleKeyDown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    showMobileMenu.value = false
    showAdminDropdown.value = false
    showUserDropdown.value = false
  }
}

onMounted(() => {
  document.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeyDown)
})
</script>

<style scoped>
.nav-link {
  color: white;
  transition: color 0.2s ease;
  padding: 0.5rem 0.75rem;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
}

.nav-link:hover {
  color: rgb(191 219 254);
}

.nav-link-active {
  color: rgb(191 219 254);
  background-color: rgba(255, 255, 255, 0.1);
}

.mobile-nav-link {
  display: flex;
  align-items: center;
  padding: 0.75rem;
  color: white;
  transition: background-color 0.2s ease;
  border-radius: 0.375rem;
  margin: 0 0.5rem;
}

.mobile-nav-link:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.mobile-nav-link-active {
  background-color: rgba(255, 255, 255, 0.1);
  color: rgb(191 219 254);
}

.dropdown-link {
  display: flex;
  align-items: center;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  color: rgb(31 41 55);
  transition: background-color 0.2s ease, color 0.2s ease;
}

.dropdown-link:hover {
  background-color: rgb(239 246 255);
  color: rgb(30 58 138);
}

/* Smooth transitions for dropdowns */
.admin-dropdown-enter-active,
.admin-dropdown-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.admin-dropdown-enter-from,
.admin-dropdown-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>