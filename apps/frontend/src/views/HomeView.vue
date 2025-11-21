<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { RouterLink, useRouter } from 'vue-router'
import { onMounted, watch, ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

console.log('🏠 HomeView component loading...')

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  status: 'pending' | 'active' | 'paused' | 'finished'
  time_left: number
  match_date?: string
  start_time?: string
  created_at?: string
  tournament_id?: string
  division_id?: string
  match_type?: string
  boosters?: any
}

interface Tournament {
  id: string
  name: string
}

interface Division {
  id: string
  name: string
  tournament_id: string
}

interface Team {
  id: string
  name: string
}

const upcomingMatches = ref<Match[]>([])
const teams = ref<Record<string, Team>>({})
const tournaments = ref<Record<string, Tournament>>({})
const divisions = ref<Record<string, Division>>({})
const loadingMatches = ref(true)

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

// Load teams for reference
async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('id, name')

    if (error) throw error
    
    const teamsMap: Record<string, Team> = {}
    data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
  } catch (error) {
    console.error('Error loading teams:', error)
  }
}

// Load tournaments and divisions
async function loadTournamentsAndDivisions() {
  try {
    // Load tournaments
    const { data: tournamentsData, error: tournamentsError } = await supabase
      .from('tournaments')
      .select('id, name')

    if (tournamentsError) throw tournamentsError
    
    const tournamentsMap: Record<string, Tournament> = {}
    tournamentsData?.forEach(tournament => {
      tournamentsMap[tournament.id] = tournament
    })
    tournaments.value = tournamentsMap

    // Load divisions
    const { data: divisionsData, error: divisionsError } = await supabase
      .from('tournament_divisions')
      .select('id, name, tournament_id')

    if (divisionsError) throw divisionsError
    
    const divisionsMap: Record<string, Division> = {}
    divisionsData?.forEach(division => {
      divisionsMap[division.id] = division
    })
    divisions.value = divisionsMap
  } catch (error) {
    console.error('Error loading tournaments and divisions:', error)
  }
}

// Load upcoming matches for public view
async function loadUpcomingMatches() {
  try {
    loadingMatches.value = true
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .in('status', ['pending', 'active'])
      .order('start_time', { ascending: true })
      .limit(10)

    if (error) throw error

    console.log('📅 Loaded upcoming matches:', data)
    upcomingMatches.value = data || []
  } catch (error) {
    console.error('Error loading upcoming matches:', error)
  } finally {
    loadingMatches.value = false
  }
}

// Get team name from ID
function getTeamName(teamId: string, match?: Match): string {
  // Check if this team is a placeholder in the match context
  if (match && match.boosters) {
    if (match.team_a === teamId && match.boosters.team_a_placeholder) {
      // This is a placeholder - show placeholder text
      return match.boosters.team_a_placeholder
    }
    if (match.team_b === teamId && match.boosters.team_b_placeholder) {
      // This is a placeholder - show placeholder text
      return match.boosters.team_b_placeholder
    }
  }
  
  // Regular team lookup
  return teams.value[teamId]?.name || 'Unknown Team'
}

// Get match category (tournament or standalone)
function getMatchCategory(match: Match): { label: string; class: string } {
  if (match.tournament_id) {
    const tournament = tournaments.value[match.tournament_id]
    const division = match.division_id ? divisions.value[match.division_id] : null
    
    let label = tournament?.name || 'Tournament'
    if (division) {
      label += ` - ${division.name}`
    }
    
    return {
      label,
      class: 'bg-purple-500/80 text-white'
    }
  }
  
  return {
    label: 'Standalone Match',
    class: 'bg-gray-500/80 text-white'
  }
}

// Format match date
function formatMatchDate(dateString?: string): string {
  if (!dateString) return 'Date TBD'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

// Format time left
function formatTimeLeft(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

// Format start time (removes seconds from HH:MM:SS)
function formatStartTime(timeString?: string): string {
  if (!timeString) return ''
  // Time string is in format HH:MM:SS, we want HH:MM
  return timeString.substring(0, 5)
}

// Get match status badge class
function getMatchStatusClass(status: string): string {
  switch (status) {
    case 'active':
      return 'bg-green-500 text-white'
    case 'pending':
      return 'bg-blue-500 text-white'
    case 'paused':
      return 'bg-yellow-500 text-white'
    case 'finished':
      return 'bg-gray-500 text-white'
    default:
      return 'bg-gray-400 text-white'
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
  
  // Load data for displaying upcoming matches
  Promise.all([
    loadTeams(),
    loadTournamentsAndDivisions()
  ]).then(() => {
    loadUpcomingMatches()
  })
  
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
    <div class="container mx-auto px-3 md:px-4 py-8 md:py-16">
      <!-- Header -->
      <div class="text-center mb-8 md:mb-16">
        <h1 class="home-title font-theme-title text-4xl md:text-6xl">
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="inline w-12 h-12 md:w-16 md:h-16 mr-2 md:mr-4"
          />
          <span v-else class="text-4xl md:text-6xl">🏑</span>
          {{ $t('home.title') }}
        </h1>
        <p class="home-subtitle font-theme-subtitle text-base md:text-lg">
          {{ $t('home.subtitle') }}
        </p>
      </div>

      <!-- Navigation Cards -->
      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-8 max-w-6xl mx-auto mb-8 md:mb-16">
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

        <!-- Game Guide -->
        <RouterLink 
          to="/game-guide" 
          class="nav-card"
        >
          <div class="text-4xl mb-4">�</div>
          <h2 class="nav-card-title">{{ $t('home.gameGuide.title') }}</h2>
          <p class="nav-card-description">
            {{ $t('home.gameGuide.description') }}
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

      <!-- Upcoming Matches List (for non-authenticated users) -->
      <div v-if="!authStore.isAuthenticated" class="mt-8 md:mt-16 max-w-6xl mx-auto">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4 md:mb-8 font-theme-title" 
            :style="{ color: themeStore.currentTheme?.colors.primary }">
          📅 {{ $t('home.upcomingMatches.title') }}
        </h2>
        
        <!-- Loading State -->
        <div v-if="loadingMatches" class="text-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto mb-2"
               :style="{ borderColor: themeStore.currentTheme?.colors.primary }"></div>
          <p :style="{ color: themeStore.currentTheme?.colors.text }">{{ $t('home.upcomingMatches.loadingMatches') }}</p>
        </div>

        <!-- No Matches -->
        <div v-else-if="upcomingMatches.length === 0" class="text-center py-8">
          <div class="text-6xl mb-4">📊</div>
          <p class="text-xl" :style="{ color: themeStore.currentTheme?.colors.text }">
            No upcoming matches at the moment
          </p>
        </div>

        <!-- Matches List -->
        <div v-else class="space-y-3 md:space-y-4">
          <RouterLink
            v-for="match in upcomingMatches" 
            :key="match.id"
            :to="{ name: 'scoreboard', params: { id: match.id } }"
            class="nav-card block hover:scale-[1.02] transition-transform duration-300 !p-3 md:!p-6"
          >
            <!-- Mobile Layout -->
            <div class="block md:hidden">
              <!-- Teams and Score -->
              <div class="mb-3">
                <h3 class="text-lg font-bold font-theme-title leading-tight mb-2">
                  {{ getTeamName(match.team_a, match) }} 
                  <span class="opacity-50 mx-1">vs</span> 
                  {{ getTeamName(match.team_b, match) }}
                </h3>
                <div class="flex items-center justify-center gap-3 mb-3">
                  <span class="text-3xl font-bold">{{ match.score_a }}</span>
                  <span class="text-xl opacity-50">-</span>
                  <span class="text-3xl font-bold">{{ match.score_b }}</span>
                </div>
              </div>
              
              <!-- Match Details Below Score on Mobile -->
              <div class="flex flex-wrap gap-2 justify-center text-center">
                <!-- Start Time -->
                <span v-if="match.start_time" class="text-sm font-semibold opacity-90 px-2 py-1 bg-black/10 rounded">
                  ⏰ {{ formatStartTime(match.start_time) }}
                </span>
                
                <!-- Status -->
                <span 
                  class="px-2 py-1 rounded text-xs font-semibold uppercase"
                  :class="getMatchStatusClass(match.status)"
                >
                  {{ match.status }}
                </span>
                
                <!-- Category -->
                <span 
                  class="px-2 py-1 rounded text-xs font-semibold"
                  :class="getMatchCategory(match).class"
                >
                  {{ getMatchCategory(match).label }}
                </span>
                
                <!-- Time Left -->
                <span v-if="match.time_left && match.status === 'active'" class="text-xs opacity-70 px-2 py-1 bg-black/10 rounded">
                  ⏱️ {{ formatTimeLeft(match.time_left) }}
                </span>
                
                <!-- Date -->
                <span v-if="match.match_date" class="text-xs opacity-70 px-2 py-1 bg-black/10 rounded">
                  {{ formatMatchDate(match.match_date) }}
                </span>
              </div>
            </div>

            <!-- Desktop Layout (unchanged) -->
            <div class="hidden md:flex md:items-center md:justify-between gap-4">
              <!-- Match Info -->
              <div class="flex-1">
                <div class="flex items-center gap-3 mb-2 flex-wrap">
                  <!-- Start Time - More Prominent -->
                  <span v-if="match.start_time" class="text-lg font-bold opacity-90">
                    ⏰ {{ formatStartTime(match.start_time) }}
                  </span>
                  <span 
                    class="px-3 py-1 rounded-full text-xs font-semibold uppercase"
                    :class="getMatchStatusClass(match.status)"
                  >
                    {{ match.status }}
                  </span>
                  <span 
                    class="px-3 py-1 rounded-full text-xs font-semibold"
                    :class="getMatchCategory(match).class"
                  >
                    {{ getMatchCategory(match).label }}
                  </span>
                  <span v-if="match.match_date" class="text-sm opacity-70">
                    {{ formatMatchDate(match.match_date) }}
                  </span>
                </div>
                <h3 class="text-xl md:text-2xl font-bold font-theme-title">
                  {{ getTeamName(match.team_a, match) }} <span class="opacity-50 mx-2">vs</span> {{ getTeamName(match.team_b, match) }}
                </h3>
              </div>
              
              <!-- Score -->
              <div class="flex items-center gap-6">
                <div class="flex items-center gap-4">
                  <span class="text-4xl font-bold">{{ match.score_a }}</span>
                  <span class="text-2xl opacity-50">-</span>
                  <span class="text-4xl font-bold">{{ match.score_b }}</span>
                </div>
                <div v-if="match.time_left && match.status === 'active'" class="text-sm opacity-70 min-w-[80px] text-right">
                  ⏱️ {{ formatTimeLeft(match.time_left) }}
                </div>
              </div>
            </div>
          </RouterLink>
        </div>
      </div>

      <!-- Features -->
      <div class="mt-12 md:mt-20 text-center">
        <h3 class="features-title text-xl md:text-2xl">{{ $t('features.title') }}</h3>
        <div class="grid md:grid-cols-3 gap-4 md:gap-8 max-w-4xl mx-auto">
          <div class="feature-item text-center p-4">
            <div class="text-2xl md:text-3xl mb-2 md:mb-4">⏱️</div>
            <h4 class="text-base md:text-lg">{{ $t('features.liveTimer.title') }}</h4>
            <p class="text-sm md:text-base">{{ $t('features.liveTimer.description') }}</p>
          </div>
          <div class="feature-item text-center p-4">
            <div class="text-2xl md:text-3xl mb-2 md:mb-4">🎯</div>
            <h4 class="text-base md:text-lg">{{ $t('features.scoreTracking.title') }}</h4>
            <p class="text-sm md:text-base">{{ $t('features.scoreTracking.description') }}</p>
          </div>
          <div class="feature-item text-center p-4">
            <div class="text-2xl md:text-3xl mb-2 md:mb-4">🎪</div>
            <h4 class="text-base md:text-lg">{{ $t('features.specialEffects.title') }}</h4>
            <p class="text-sm md:text-base">{{ $t('features.specialEffects.description') }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
