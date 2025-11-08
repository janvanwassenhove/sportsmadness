<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  status: 'pending' | 'active' | 'paused' | 'finished'
  time_left: number
  tournament_id?: string
  division_id?: string
  match_date?: string
  start_time?: string
  created_at: string
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
}

interface Team {
  id: string
  name: string
  players: any[]
}

const authStore = useAuthStore()
const router = useRouter()
const matches = ref<Match[]>([])
const tournamentMatches = ref<Match[]>([])
const standaloneMatches = ref<Match[]>([])
const teams = ref<Record<string, Team>>({})
const loading = ref(true)
const showMatchType = ref<'tournament' | 'standalone' | 'all'>('all')

// Edit match modal state
const showEditMatchModal = ref(false)
const editMatchData = ref({
  id: '',
  quarters_count: 4,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10
})

// Create match modal state
const showCreateMatchModal = ref(false)
const newMatchData = ref({
  team_a: '',
  team_b: '',
  quarters_count: 4,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10
})

async function loadData() {
  try {
    loading.value = true
    
    // Load matches and teams in parallel
    const [matchesResult, teamsResult] = await Promise.all([
      supabase.from('matches').select('*').order('created_at', { ascending: true }),
      supabase.from('teams').select('*').order('name')
    ])

    if (matchesResult.error) {
      console.error('Error loading matches:', matchesResult.error)
      return
    }

    if (teamsResult.error) {
      console.error('Error loading teams:', teamsResult.error)
      return
    }

    matches.value = matchesResult.data || []
    
    // Separate tournament matches from standalone matches
    tournamentMatches.value = matches.value.filter(match => match.tournament_id)
    standaloneMatches.value = matches.value.filter(match => !match.tournament_id)
    
    const teamsMap: Record<string, Team> = {}
    teamsResult.data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

function getTeamName(teamId: string): string {
  return teams.value[teamId]?.name || 'Unknown Team'
}

function getStatusColor(status: string): string {
  switch (status) {
    case 'active': return 'bg-green-500'
    case 'paused': return 'bg-yellow-500'
    case 'finished': return 'bg-red-500'
    default: return 'bg-gray-500'
  }
}

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

// Computed property for displayed matches based on filter
const displayedMatches = computed(() => {
  switch (showMatchType.value) {
    case 'tournament':
      return tournamentMatches.value
    case 'standalone':
      return standaloneMatches.value
    default:
      return matches.value
  }
})

// Format match date for display
function formatMatchDate(match: Match): string {
  if (match.match_date) {
    const date = new Date(match.match_date)
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    })
  }
  // Fallback to creation date
  const date = new Date(match.created_at)
  return date.toLocaleDateString('en-US', { 
    weekday: 'short', 
    month: 'short', 
    day: 'numeric' 
  })
}

// Format match start time for display
function formatMatchStartTime(match: Match): string {
  if (match.start_time) {
    return match.start_time.substring(0, 5) // HH:MM format
  }
  // Fallback to creation time
  const date = new Date(match.created_at)
  return date.toLocaleTimeString('en-US', { 
    hour: '2-digit', 
    minute: '2-digit', 
    hour12: false 
  })
}

// Get match type label
function getMatchTypeLabel(match: Match): string {
  return match.tournament_id ? 'Tournament' : 'Standalone'
}

// Get match type color
function getMatchTypeColor(match: Match): string {
  return match.tournament_id ? 'bg-blue-500' : 'bg-purple-500'
}

// Match editing functions
function editMatch(match: Match) {
  // For standalone matches, use system defaults since there's no tournament context
  const defaultQuarters = 4
  const defaultQuarterDuration = 15
  const defaultBreakDuration = 2
  const defaultHalftimeDuration = 10

  // Populate edit form with current match values or defaults
  editMatchData.value = {
    id: match.id,
    quarters_count: match.quarters_count || defaultQuarters,
    quarter_duration_minutes: match.quarter_duration_minutes || defaultQuarterDuration,
    break_duration_minutes: match.break_duration_minutes || defaultBreakDuration,
    halftime_duration_minutes: match.halftime_duration_minutes || defaultHalftimeDuration
  }

  showEditMatchModal.value = true
}

async function saveMatchSettings() {
  try {
    const { error } = await supabase
      .from('matches')
      .update({
        quarters_count: editMatchData.value.quarters_count,
        quarter_duration_minutes: editMatchData.value.quarter_duration_minutes,
        break_duration_minutes: editMatchData.value.break_duration_minutes,
        halftime_duration_minutes: editMatchData.value.halftime_duration_minutes
      })
      .eq('id', editMatchData.value.id)

    if (error) {
      console.error('Error updating match settings:', error)
      alert('Failed to save match settings. Please try again.')
      return
    }

    // Update match in local state arrays
    const updateMatch = (matchArray: Match[]) => {
      const matchIndex = matchArray.findIndex(m => m.id === editMatchData.value.id)
      if (matchIndex !== -1 && matchArray[matchIndex]) {
        const match = matchArray[matchIndex]
        match.quarters_count = editMatchData.value.quarters_count
        match.quarter_duration_minutes = editMatchData.value.quarter_duration_minutes
        match.break_duration_minutes = editMatchData.value.break_duration_minutes
        match.halftime_duration_minutes = editMatchData.value.halftime_duration_minutes
      }
    }

    // Update in all arrays
    updateMatch(matches.value)
    updateMatch(tournamentMatches.value)
    updateMatch(standaloneMatches.value)

    showEditMatchModal.value = false
    console.log('✅ Match settings saved successfully')
  } catch (error) {
    console.error('Error saving match settings:', error)
    alert('Failed to save match settings. Please try again.')
  }
}

async function startMatch(matchId: string) {
  try {
    const { error } = await supabase
      .from('matches')
      .update({ status: 'active' })
      .eq('id', matchId)

    if (error) {
      console.error('Error starting match:', error)
      return
    }

    // Navigate to match control
    await loadData()
  } catch (error) {
    console.error('Error starting match:', error)
  }
}

async function deleteMatch(matchId: string) {
  // Find the match to get its status for better confirmation message
  const match = matches.value.find(m => m.id === matchId)
  const matchType = match?.tournament_id ? 'tournament' : 'standalone'
  const matchStatus = match?.status || 'unknown'
  
  let confirmMessage = `Are you sure you want to delete this ${matchStatus} ${matchType} match?`
  if (matchStatus === 'finished') {
    confirmMessage += '\n\nThis will permanently remove the match and all its results from the database.'
  }
  confirmMessage += '\n\nThis action cannot be undone.'
  
  if (!confirm(confirmMessage)) {
    return
  }

  try {
    const { error } = await supabase
      .from('matches')
      .delete()
      .eq('id', matchId)

    if (error) {
      console.error('Error deleting match:', error)
      alert('Failed to delete match. Please try again.')
      return
    }

    // Remove match from local state arrays
    matches.value = matches.value.filter(m => m.id !== matchId)
    tournamentMatches.value = tournamentMatches.value.filter(m => m.id !== matchId)
    standaloneMatches.value = standaloneMatches.value.filter(m => m.id !== matchId)
    
    console.log('✅ Match deleted successfully')
  } catch (error) {
    console.error('Error:', error)
    alert('Failed to delete match. Please try again.')
  }
}

function createNewMatch() {
  // Reset form data
  newMatchData.value = {
    team_a: '',
    team_b: '',
    quarters_count: 4,
    quarter_duration_minutes: 15,
    break_duration_minutes: 2,
    halftime_duration_minutes: 10
  }
  showCreateMatchModal.value = true
}

async function saveNewMatch() {
  try {
    // Validate that teams are selected and different
    if (!newMatchData.value.team_a || !newMatchData.value.team_b) {
      alert('Please select both teams')
      return
    }
    
    if (newMatchData.value.team_a === newMatchData.value.team_b) {
      alert('Please select different teams')
      return
    }

    // Calculate total match duration in seconds
    const totalDuration = newMatchData.value.quarters_count * newMatchData.value.quarter_duration_minutes * 60

    const matchData = {
      team_a: newMatchData.value.team_a,
      team_b: newMatchData.value.team_b,
      score_a: 0,
      score_b: 0,
      status: 'pending',
      time_left: totalDuration,
      maddie: false,
      boosters: {},
      cards: {},
      quarters_count: newMatchData.value.quarters_count,
      quarter_duration_minutes: newMatchData.value.quarter_duration_minutes,
      break_duration_minutes: newMatchData.value.break_duration_minutes,
      halftime_duration_minutes: newMatchData.value.halftime_duration_minutes
    }

    const { data, error } = await supabase
      .from('matches')
      .insert([matchData])
      .select()
      .single()

    if (error) {
      console.error('Error creating match:', error)
      alert('Failed to create match. Please try again.')
      return
    }

    // Add new match to local state
    matches.value.unshift(data)
    standaloneMatches.value.unshift(data)
    
    showCreateMatchModal.value = false
    console.log('✅ Match created successfully')
  } catch (error) {
    console.error('Error:', error)
    alert('Failed to create match. Please try again.')
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-white mb-2">{{ $t('admin.title') }}</h1>
        <p class="text-blue-100">{{ $t('admin.subtitle') }}</p>
      </div>

      <!-- Quick Actions -->
      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <RouterLink 
          to="/admin/tournaments"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center hover:bg-white/20 transition-all duration-300 border border-white/20 block"
        >
          <div class="text-3xl mb-3">🏆</div>
          <h3 class="text-xl font-bold text-white mb-2">{{ $t('admin.quickActions.tournaments.title') }}</h3>
          <p class="text-blue-100">{{ $t('admin.quickActions.tournaments.description') }}</p>
        </RouterLink>

        <RouterLink 
          to="/admin/teams"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center hover:bg-white/20 transition-all duration-300 border border-white/20 block"
        >
          <div class="text-3xl mb-3">👥</div>
          <h3 class="text-xl font-bold text-white mb-2">{{ $t('admin.quickActions.teams.title') }}</h3>
          <p class="text-blue-100">{{ $t('admin.quickActions.teams.description') }}</p>
        </RouterLink>

        <RouterLink 
          to="/admin/boosters"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center hover:bg-white/20 transition-all duration-300 border border-white/20 block"
        >
          <div class="text-3xl mb-3">⚡</div>
          <h3 class="text-xl font-bold text-white mb-2">{{ $t('admin.quickActions.boosters.title') }}</h3>
          <p class="text-blue-100">{{ $t('admin.quickActions.boosters.description') }}</p>
        </RouterLink>

        <RouterLink 
          to="/scoreboard"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center hover:bg-white/20 transition-all duration-300 border border-white/20 block"
        >
          <div class="text-3xl mb-3">📺</div>
          <h3 class="text-xl font-bold text-white mb-2">{{ $t('admin.quickActions.scoreboard.title') }}</h3>
          <p class="text-blue-100">{{ $t('admin.quickActions.scoreboard.description') }}</p>
        </RouterLink>

        <RouterLink 
          to="/"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center hover:bg-white/20 transition-all duration-300 border border-white/20 block"
        >
          <div class="text-3xl mb-3">🏠</div>
          <h3 class="text-xl font-bold text-white mb-2">{{ $t('admin.quickActions.backHome.title') }}</h3>
          <p class="text-blue-100">{{ $t('admin.quickActions.backHome.description') }}</p>
        </RouterLink>
      </div>

      <!-- Matches Section -->
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
        <div class="flex justify-between items-center mb-6">
          <div>
            <h2 class="text-2xl font-bold text-white mb-2">{{ $t('admin.matches.title') }}</h2>
            <!-- Match Type Filter -->
            <div class="flex space-x-2">
              <button 
                @click="showMatchType = 'all'"
                :class="showMatchType === 'all' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm'"
              >
                {{ $t('admin.matches.filters.all') }} ({{ matches.length }})
              </button>
              <button 
                @click="showMatchType = 'tournament'"
                :class="showMatchType === 'tournament' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm'"
              >
                {{ $t('admin.matches.filters.tournament') }} ({{ tournamentMatches.length }})
              </button>
              <button 
                @click="showMatchType = 'standalone'"
                :class="showMatchType === 'standalone' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm'"
              >
                {{ $t('admin.matches.filters.standalone') }} ({{ standaloneMatches.length }})
              </button>
            </div>
          </div>
          <button 
            @click="createNewMatch"
            class="btn btn-primary"
          >
            {{ $t('admin.matches.newMatch') }}
          </button>
        </div>

        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">{{ $t('admin.matches.loading') }}</div>
        </div>

        <div v-else-if="matches.length === 0" class="text-center py-8">
          <div class="text-4xl mb-4">�</div>
          <h3 class="text-xl text-white mb-2">{{ $t('admin.matches.noMatches.title') }}</h3>
          <p class="text-blue-200">{{ $t('admin.matches.noMatches.description') }}</p>
        </div>

        <div v-else class="space-y-4">
          <div 
            v-for="match in displayedMatches" 
            :key="match.id"
            class="bg-white/5 rounded-lg p-4 border border-white/10"
          >
            <div class="flex items-center justify-between">
              <div class="flex-1">
                <div class="flex items-center space-x-4 mb-2">
                  <div 
                    class="px-3 py-1 rounded-full text-white text-sm font-bold"
                    :class="getStatusColor(match.status)"
                  >
                    {{ match.status.toUpperCase() }}
                  </div>
                  <div v-if="match.tournament_id" class="px-2 py-1 rounded bg-purple-600/50 text-white text-xs">
                    {{ $t('admin.matches.labels.tournament') }}
                  </div>
                  <div v-else class="px-2 py-1 rounded bg-gray-600/50 text-white text-xs">
                    {{ $t('admin.matches.labels.standalone') }}
                  </div>
                  <div class="text-white font-mono">
                    {{ formatTime(match.time_left) }}
                  </div>
                  <!-- Date and Time Display -->
                  <div class="text-gray-400 text-sm">
                    📅 {{ formatMatchDate(match) }}
                  </div>
                  <div class="text-gray-400 text-sm">
                    🕒 {{ formatMatchStartTime(match) }}
                  </div>
                </div>
                
                <div class="flex items-center space-x-6">
                  <div class="text-center">
                    <div class="text-blue-300 font-semibold">
                      {{ getTeamName(match.team_a) }}
                    </div>
                    <div class="text-2xl font-bold text-white">
                      {{ match.score_a }}
                    </div>
                  </div>
                  
                  <div class="text-yellow-400 font-bold">VS</div>
                  
                  <div class="text-center">
                    <div class="text-red-300 font-semibold">
                      {{ getTeamName(match.team_b) }}
                    </div>
                    <div class="text-2xl font-bold text-white">
                      {{ match.score_b }}
                    </div>
                  </div>
                </div>
              </div>

              <div class="flex space-x-2">
                <RouterLink 
                  :to="`/admin/match/${match.id}`"
                  class="btn btn-primary"
                >
                  {{ match.status === 'active' || match.status === 'paused' ? $t('admin.matches.actions.controlMatch') : $t('admin.matches.actions.viewMatch') }}
                </RouterLink>
                
                <button 
                  v-if="match.status === 'pending'"
                  @click="editMatch(match)"
                  class="btn btn-secondary"
                  :title="$t('admin.matches.actions.editSettings')"
                >
                  ⚙️
                </button>
                
                <button 
                  v-if="match.status === 'pending'"
                  @click="startMatch(match.id)"
                  class="btn btn-success"
                >
                  {{ $t('admin.matches.actions.startMatch') }}
                </button>
                
                <button 
                  v-if="match.status === 'pending' || match.status === 'finished'"
                  @click="deleteMatch(match.id)"
                  class="btn btn-xs bg-red-600 hover:bg-red-700 text-white"
                  :title="$t('admin.matches.actions.deleteMatch')"
                >
                  🗑️
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Teams Overview -->
      <div class="mt-8 bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-white">{{ $t('admin.teams.title') }}</h2>
          <RouterLink to="/admin/teams" class="btn btn-primary">
            {{ $t('admin.teams.manageTeams') }}
          </RouterLink>
        </div>

        <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div 
            v-for="team in Object.values(teams)" 
            :key="team.id"
            class="bg-white/5 rounded-lg p-4 text-center border border-white/10"
          >
            <h3 class="text-lg font-bold text-white mb-2">{{ team.name }}</h3>
            <p class="text-blue-200">{{ team.players?.length || 0 }} {{ $t('admin.teams.playersCount') }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Match Settings Modal -->
    <div v-if="showEditMatchModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">{{ $t('admin.editMatch.title') }}</h3>
        
        <form @submit.prevent="saveMatchSettings" class="space-y-4">
          <!-- Match Duration Settings -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">{{ $t('admin.editMatch.duration.title') }}</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editMatchData.quarters_count === 2 ? $t('admin.editMatch.duration.halves') : $t('admin.editMatch.duration.quarters') }}
                </label>
                <input 
                  v-model.number="editMatchData.quarters_count"
                  type="number" 
                  min="1" 
                  max="6"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editMatchData.quarters_count === 2 ? $t('admin.editMatch.duration.halfLength') : $t('admin.editMatch.duration.quarterLength') }}
                </label>
                <input 
                  v-model.number="editMatchData.quarter_duration_minutes"
                  type="number" 
                  min="5" 
                  max="30"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div v-if="editMatchData.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">{{ $t('admin.editMatch.duration.breakTime') }}</label>
                <input 
                  v-model.number="editMatchData.break_duration_minutes"
                  type="number" 
                  min="1" 
                  max="10"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ $t('admin.editMatch.duration.halftime') }}
                </label>
                <input 
                  v-model.number="editMatchData.halftime_duration_minutes"
                  type="number" 
                  min="5" 
                  max="20"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
            </div>
            
            <div class="text-xs text-white/60 mt-2">
              {{ $t('admin.editMatch.duration.totalTime') }}: {{ 
                (editMatchData.quarters_count * editMatchData.quarter_duration_minutes) + 
                (editMatchData.quarters_count === 2 ? editMatchData.halftime_duration_minutes : 
                  ((editMatchData.quarters_count - 1) * editMatchData.break_duration_minutes) + 
                  (editMatchData.quarters_count > 2 ? editMatchData.halftime_duration_minutes : 0)
                ) 
              }} {{ $t('common.minutes') }}
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              {{ $t('admin.editMatch.actions.save') }}
            </button>
            <button 
              type="button" 
              @click="showEditMatchModal = false"
              class="flex-1 btn btn-secondary"
            >
              {{ $t('admin.editMatch.actions.cancel') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Create New Match Modal -->
    <div v-if="showCreateMatchModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">{{ $t('admin.createMatch.title') }}</h3>
        
        <form @submit.prevent="saveNewMatch" class="space-y-4">
          <!-- Team Selection -->
          <div class="space-y-3">
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">{{ $t('admin.createMatch.teamA') }}</label>
              <select 
                v-model="newMatchData.team_a"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                required
              >
                <option value="">{{ $t('admin.createMatch.selectTeam') }}</option>
                <option 
                  v-for="team in Object.values(teams)" 
                  :key="team.id" 
                  :value="team.id"
                  :disabled="team.id === newMatchData.team_b"
                >
                  {{ team.name }}
                </option>
              </select>
            </div>
            
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">{{ $t('admin.createMatch.teamB') }}</label>
              <select 
                v-model="newMatchData.team_b"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                required
              >
                <option value="">{{ $t('admin.createMatch.selectTeam') }}</option>
                <option 
                  v-for="team in Object.values(teams)" 
                  :key="team.id" 
                  :value="team.id"
                  :disabled="team.id === newMatchData.team_a"
                >
                  {{ team.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- Match Duration Settings -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">{{ $t('admin.createMatch.duration.title') }}</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ newMatchData.quarters_count === 2 ? $t('admin.createMatch.duration.halves') : $t('admin.createMatch.duration.quarters') }}
                </label>
                <input 
                  v-model.number="newMatchData.quarters_count"
                  type="number" 
                  min="1" 
                  max="6"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ newMatchData.quarters_count === 2 ? $t('admin.createMatch.duration.halfLength') : $t('admin.createMatch.duration.quarterLength') }}
                </label>
                <input 
                  v-model.number="newMatchData.quarter_duration_minutes"
                  type="number" 
                  min="5" 
                  max="30"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div v-if="newMatchData.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">{{ $t('admin.createMatch.duration.breakTime') }}</label>
                <input 
                  v-model.number="newMatchData.break_duration_minutes"
                  type="number" 
                  min="1" 
                  max="10"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div v-if="newMatchData.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">{{ $t('admin.createMatch.duration.halftimeBreak') }}</label>
                <input 
                  v-model.number="newMatchData.halftime_duration_minutes"
                  type="number" 
                  min="5" 
                  max="20"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              {{ $t('admin.createMatch.actions.create') }}
            </button>
            <button 
              type="button" 
              @click="showCreateMatchModal = false"
              class="flex-1 btn btn-secondary"
            >
              {{ $t('admin.createMatch.actions.cancel') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>