<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div class="flex items-center space-x-4">
          <button 
            @click="$router.back()"
            class="bg-blue-600 hover:bg-blue-700 text-white p-2 rounded-lg transition-colors"
          >
            ← Back
          </button>
          <h1 class="text-3xl font-bold text-white">Match Center</h1>
        </div>
        
        <div v-if="match" class="text-right">
          <div class="text-sm text-blue-200">Match ID</div>
          <div class="text-white font-mono">{{ match.id.slice(-8) }}</div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-20">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
        <p class="text-blue-200 text-xl">Loading match data...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-20">
        <div class="text-6xl mb-4">❌</div>
        <h2 class="text-2xl font-bold text-white mb-4">Match Not Found</h2>
        <p class="text-blue-200 mb-6">{{ error }}</p>
        <RouterLink 
          to="/dashboard"
          class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
        >
          Return to Dashboard
        </RouterLink>
      </div>

      <!-- Match Content -->
      <div v-else-if="match" class="space-y-8">
        
        <!-- Match Info Header -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <div class="grid md:grid-cols-3 gap-6 items-center">
            
            <!-- Team A -->
            <div class="text-center">
              <div class="text-4xl font-bold text-white mb-2">{{ getTeamName(match.team_a) }}</div>
              <div class="text-6xl font-bold text-blue-300">{{ match.score_a }}</div>
              <div v-if="userTeam?.id === match.team_a" class="mt-2">
                <span class="bg-blue-500 text-white px-3 py-1 rounded-full text-sm font-semibold">
                  YOUR TEAM
                </span>
              </div>
            </div>

            <!-- Match Status & Timer -->
            <div class="text-center">
              <div class="text-2xl font-bold text-white mb-4">VS</div>
              
              <!-- Match Status -->
              <div class="mb-4">
                <span 
                  class="px-4 py-2 rounded-full text-sm font-semibold"
                  :class="getMatchStatusClass(match.status)"
                >
                  {{ match.status.toUpperCase() }}
                </span>
              </div>

              <!-- Timer Display -->
              <div v-if="match.status === 'active' && match.time_left > 0" class="text-center">
                <div class="text-4xl font-bold text-white font-mono">
                  {{ formatTimeLeft(match.time_left) }}
                </div>
                <div class="text-blue-200 text-sm">Time Remaining</div>
              </div>
              
              <div v-else-if="match.status === 'finished'" class="text-center">
                <div class="text-2xl font-bold text-gray-400">FINAL</div>
              </div>
              
              <div v-else class="text-center">
                <div class="text-2xl font-bold text-yellow-400">{{ match.status.toUpperCase() }}</div>
              </div>
            </div>

            <!-- Team B -->
            <div class="text-center">
              <div class="text-4xl font-bold text-white mb-2">{{ getTeamName(match.team_b) }}</div>
              <div class="text-6xl font-bold text-purple-300">{{ match.score_b }}</div>
              <div v-if="userTeam?.id === match.team_b" class="mt-2">
                <span class="bg-purple-500 text-white px-3 py-1 rounded-full text-sm font-semibold">
                  YOUR TEAM
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- User Team Booster Controls -->
        <div v-if="userTeamSide && match.status === 'active'" class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <h2 class="text-2xl font-bold text-white mb-6 flex items-center">
            <span class="mr-3">⚡</span>
            Your Team's Boosters
            <span class="ml-3 text-sm bg-green-600 px-3 py-1 rounded-full">
              {{ getTeamName(userTeam?.id || '') }}
            </span>
          </h2>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div 
              v-for="(booster, index) in getUserTeamBoosters()"
              :key="`user-booster-${index}`"
              class="bg-white/5 rounded-lg p-4 border border-white/10"
            >
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center space-x-3">
                  <span 
                    class="text-2xl"
                    :class="{ 'line-through opacity-50': booster.expired }"
                  >
                    {{ booster.expired ? '🚫' : (booster.icon || '⚡') }}
                  </span>
                  <div>
                    <div 
                      class="text-white font-semibold"
                      :class="{ 'line-through text-gray-400': booster.expired }"
                    >
                      {{ booster.name || booster.title }}
                    </div>
                    <div 
                      class="text-blue-200 text-sm"
                      :class="{ 'text-gray-500': booster.expired }"
                    >
                      {{ booster.description }}
                    </div>
                  </div>
                </div>
                
                <!-- Booster Status -->
                <div class="text-right">
                  <div v-if="booster.activated" class="text-green-400 text-sm font-semibold">
                    ✓ ACTIVE
                  </div>
                  <div v-else-if="booster.used" class="text-gray-400 text-sm">
                    ✓ Used
                  </div>
                  <div v-else class="text-yellow-400 text-sm">
                    Ready
                  </div>
                </div>
              </div>

              <!-- Activation Button -->
              <div v-if="!booster.used && !booster.activated" class="text-center">
                <button
                  @click="activateUserBooster(index)"
                  :disabled="activatingBooster"
                  class="w-full bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 disabled:from-gray-500 disabled:to-gray-600 text-white font-semibold py-3 px-6 rounded-lg transition-all transform hover:scale-105 disabled:hover:scale-100"
                >
                  <span v-if="activatingBooster" class="flex items-center justify-center">
                    <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Activating...
                  </span>
                  <span v-else class="flex items-center justify-center">
                    <span class="mr-2">🚀</span>
                    Activate Booster
                  </span>
                </button>
              </div>

              <!-- Active Timer -->
              <div v-else-if="booster.activated && activeBoosterTimers[`${userTeamSide}_${index}`]" class="text-center">
                <div class="bg-green-500/20 border border-green-400 rounded-lg p-3">
                  <div class="text-green-400 font-bold text-lg">
                    ⏰ {{ Math.ceil(activeBoosterTimers[`${userTeamSide}_${index}`]?.timeLeft || 0) }}s
                  </div>
                  <div class="text-green-300 text-sm">remaining</div>
                </div>
              </div>
              
              <!-- Expired State -->
              <div v-else-if="booster.expired" class="text-center">
                <div class="bg-red-500/20 border border-red-400 rounded-lg p-3">
                  <div class="text-red-400 font-semibold line-through">
                    🚫 Booster Expired
                  </div>
                </div>
              </div>

              <!-- Used State -->
              <div v-else-if="booster.used || booster.activated" class="text-center">
                <div class="bg-gray-500/20 border border-gray-400 rounded-lg p-3">
                  <div class="text-gray-400 font-semibold">
                    {{ booster.activated ? '✓ Booster Applied' : '✓ Already Used' }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Both Teams' Boosters Overview -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <h2 class="text-2xl font-bold text-white mb-6 flex items-center">
            <span class="mr-3">🎯</span>
            Selected Boosters
          </h2>
          
          <div class="grid md:grid-cols-2 gap-6">
            <!-- Team A Boosters -->
            <div class="space-y-3">
              <h3 class="text-lg font-semibold text-blue-300 flex items-center">
                <span class="mr-2">🔵</span>
                {{ getTeamName(match.team_a) }}
              </h3>
              
              <div v-if="!getTeamBoosters('teamA').length" class="text-center py-8">
                <div class="text-4xl mb-2">📋</div>
                <p class="text-blue-200">No boosters selected</p>
              </div>
              
              <div v-else class="space-y-2">
                <div 
                  v-for="(booster, index) in getTeamBoosters('teamA')"
                  :key="`team-a-${index}`"
                  class="bg-blue-500/10 border border-blue-400/30 rounded-lg p-3"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-2">
                      <span 
                        class="text-xl"
                        :class="{ 'line-through opacity-50': booster.expired }"
                      >
                        {{ booster.expired ? '🚫' : (booster.icon || '⚡') }}
                      </span>
                      <span 
                        class="text-white font-medium"
                        :class="{ 'line-through text-gray-400': booster.expired }"
                      >
                        {{ booster.name || booster.title }}
                      </span>
                    </div>
                    <div class="flex items-center space-x-2 text-sm">
                      <span v-if="booster.expired" class="text-red-400 font-semibold">● EXPIRED</span>
                      <span v-else-if="booster.activated" class="text-green-400 font-semibold">● ACTIVE</span>
                      <span v-else-if="booster.used" class="text-gray-400">● USED</span>
                      <span v-else class="text-yellow-400">● READY</span>
                      
                      <!-- Active timer for this booster -->
                      <span v-if="booster.activated && activeBoosterTimers[`a_${index}`]" class="text-green-400 font-bold">
                        ({{ Math.ceil(activeBoosterTimers[`a_${index}`]?.timeLeft || 0) }}s)
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Team B Boosters -->
            <div class="space-y-3">
              <h3 class="text-lg font-semibold text-purple-300 flex items-center">
                <span class="mr-2">🟣</span>
                {{ getTeamName(match.team_b) }}
              </h3>
              
              <div v-if="!getTeamBoosters('teamB').length" class="text-center py-8">
                <div class="text-4xl mb-2">📋</div>
                <p class="text-blue-200">No boosters selected</p>
              </div>
              
              <div v-else class="space-y-2">
                <div 
                  v-for="(booster, index) in getTeamBoosters('teamB')"
                  :key="`team-b-${index}`"
                  class="bg-purple-500/10 border border-purple-400/30 rounded-lg p-3"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-2">
                      <span 
                        class="text-xl"
                        :class="{ 'line-through opacity-50': booster.expired }"
                      >
                        {{ booster.expired ? '🚫' : (booster.icon || '⚡') }}
                      </span>
                      <span 
                        class="text-white font-medium"
                        :class="{ 'line-through text-gray-400': booster.expired }"
                      >
                        {{ booster.name || booster.title }}
                      </span>
                    </div>
                    <div class="flex items-center space-x-2 text-sm">
                      <span v-if="booster.expired" class="text-red-400 font-semibold">● EXPIRED</span>
                      <span v-else-if="booster.activated" class="text-green-400 font-semibold">● ACTIVE</span>
                      <span v-else-if="booster.used" class="text-gray-400">● USED</span>
                      <span v-else class="text-yellow-400">● READY</span>
                      
                      <!-- Active timer for this booster -->
                      <span v-if="booster.activated && activeBoosterTimers[`b_${index}`]" class="text-green-400 font-bold">
                        ({{ Math.ceil(activeBoosterTimers[`b_${index}`]?.timeLeft || 0) }}s)
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tournament Standings (if available) -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <h2 class="text-2xl font-bold text-white mb-6 flex items-center">
            <span class="mr-3">🏆</span>
            Tournament Standings
          </h2>
          
          <div v-if="loadingStandings" class="text-center py-8">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto mb-2"></div>
            <p class="text-blue-200">Loading standings...</p>
          </div>
          
          <div v-else-if="standings.length === 0" class="text-center py-8">
            <div class="text-4xl mb-4">📊</div>
            <p class="text-blue-200">No tournament standings available</p>
          </div>
          
          <div v-else class="space-y-2 max-h-80 overflow-y-auto">
            <div 
              v-for="(team, index) in standings.slice(0, 10)" 
              :key="team.id"
              class="flex justify-between items-center p-3 rounded-lg"
              :class="getStandingRowClass(team.id)"
            >
              <div class="flex items-center space-x-3">
                <span class="font-bold text-white w-8 text-center">{{ index + 1 }}.</span>
                <span 
                  class="text-white"
                  :class="{ 'font-bold': isHighlightedTeam(team.id) }"
                >
                  {{ team.name }}
                </span>
                <span v-if="isHighlightedTeam(team.id)" class="text-xs bg-yellow-500 px-2 py-1 rounded">
                  {{ getTeamLabel(team.id) }}
                </span>
              </div>
              <div class="text-right">
                <div class="text-white font-bold">{{ team.points || 0 }} pts</div>
                <div class="text-xs text-blue-200">{{ team.wins || 0 }}W {{ team.losses || 0 }}L</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="flex justify-center space-x-4">
          <RouterLink 
            :to="`/scoreboard/${match.id}`" 
            class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition-colors flex items-center space-x-2"
            target="_blank"
          >
            <span>📺</span>
            <span>Live Scoreboard</span>
          </RouterLink>
          
          <RouterLink 
            to="/dashboard" 
            class="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-lg font-medium transition-colors flex items-center space-x-2"
          >
            <span>📈</span>
            <span>My Dashboard</span>
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Props {
  id: string
}

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
  boosters?: {
    teamA?: any[]
    teamB?: any[]
  }
  created_at: string
}

interface Team {
  id: string
  name: string
}

interface TeamStanding {
  id: string
  name: string
  points: number
  wins: number
  losses: number
  goals_for: number
  goals_against: number
}

const props = defineProps<Props>()
const route = useRoute()
const authStore = useAuthStore()

const match = ref<Match | null>(null)
const teams = ref<Record<string, Team>>({})
const userTeam = ref<Team | null>(null)
const standings = ref<TeamStanding[]>([])
const loading = ref(true)
const loadingStandings = ref(true)
const error = ref<string>('')
const activatingBooster = ref(false)

// Real-time subscriptions
let matchSubscription: any = null
let timerInterval: number | null = null

// Active booster timers tracking
const activeBoosterTimers = ref<Record<string, {
  timeLeft: number
  intervalId: number
}>>({})

// Determine which side the user's team is on
const userTeamSide = computed(() => {
  const result = (() => {
    if (!userTeam.value || !match.value) return null
    if (match.value.team_a === userTeam.value.id) return 'a'
    if (match.value.team_b === userTeam.value.id) return 'b'
    return null
  })()
  
  console.log('🎯 userTeamSide computed:', {
    result,
    hasUserTeam: !!userTeam.value,
    hasMatch: !!match.value,
    userTeamId: userTeam.value?.id,
    matchTeamA: match.value?.team_a,
    matchTeamB: match.value?.team_b
  })
  
  return result
})

// Load user's team
async function loadUserTeam() {
  if (!authStore.profile?.assigned_team_id) return

  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')
      .eq('id', authStore.profile.assigned_team_id)
      .single()

    if (error) throw error
    userTeam.value = data
  } catch (error) {
    console.error('Error loading user team:', error)
  }
}

// Load all teams
async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')

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

// Load specific match
async function loadMatch() {
  try {
    const { data, error: supabaseError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', props.id)
      .single()

    if (supabaseError) throw supabaseError
    if (!data) {
      error.value = 'Match not found'
      return
    }

    match.value = data
    
    console.log('🚨 MATCH CENTER - Now watching match:', data.id)
    
    // Set up real-time subscription for match updates
    matchSubscription = supabase
      .channel(`match-${props.id}`)
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'matches',
        filter: `id=eq.${props.id}`
      }, (payload) => {
        console.log('🔄 Match update received:', payload.new)
        
        // CHECK FOR POTENTIAL RACE CONDITION
        console.log('🔍 RACE CONDITION CHECK:')
        console.log('🔍 Current local boosters before overwrite:', JSON.stringify(match.value?.boosters, null, 2))
        console.log('🔍 Incoming payload boosters:', JSON.stringify(payload.new.boosters, null, 2))
        
        // PREVENT RACE CONDITION: Merge booster states intelligently
        const updatedMatch = payload.new as Match
        
        // Store the original incoming boosters before any modifications
        const originalIncomingBoosters = updatedMatch.boosters ? JSON.parse(JSON.stringify(updatedMatch.boosters)) : null
        
        // If we have local booster activations that are newer than incoming data, preserve them
        if (match.value?.boosters && updatedMatch.boosters) {
          const localBoosters = match.value.boosters
          const incomingBoosters = updatedMatch.boosters
          
          // Check Team A boosters
          if (localBoosters.teamA && incomingBoosters.teamA && Array.isArray(incomingBoosters.teamA)) {
            localBoosters.teamA.forEach((localBooster: any, index: number) => {
              const incomingBooster = incomingBoosters.teamA?.[index]
              if (localBooster && incomingBooster && 
                  localBooster.activated && !incomingBooster.activated &&
                  localBooster.activatedAt && incomingBoosters.teamA) {
                // Local activation is newer, keep it
                console.log(`🔒 Preserving local Team A booster ${index} activation:`, localBooster.name)
                incomingBoosters.teamA[index] = localBooster
              }
            })
          }
          
          // Check Team B boosters
          if (localBoosters.teamB && incomingBoosters.teamB && Array.isArray(incomingBoosters.teamB)) {
            localBoosters.teamB.forEach((localBooster: any, index: number) => {
              const incomingBooster = incomingBoosters.teamB?.[index]
              if (localBooster && incomingBooster && 
                  localBooster.activated && !incomingBooster.activated &&
                  localBooster.activatedAt && incomingBoosters.teamB) {
                // Local activation is newer, keep it
                console.log(`🔒 Preserving local Team B booster ${index} activation:`, localBooster.name)
                incomingBoosters.teamB[index] = localBooster
              }
            })
          }
        }
        
        match.value = updatedMatch
        
        // If we preserved any local activations, we need to sync them back to the database
        // so other views can see them
        let preservedActivations = false
        if (match.value?.boosters && originalIncomingBoosters) {
          const currentBoosters = match.value.boosters
          
          // Check if we have any preserved activations that differ from the original incoming payload
          const hasTeamAPreservations = currentBoosters.teamA?.some((booster: any, index: number) => {
            const original = originalIncomingBoosters.teamA?.[index]
            return booster.activated && original && !original.activated
          })
          
          const hasTeamBPreservations = currentBoosters.teamB?.some((booster: any, index: number) => {
            const original = originalIncomingBoosters.teamB?.[index]
            return booster.activated && original && !original.activated
          })
          
          preservedActivations = Boolean(hasTeamAPreservations || hasTeamBPreservations)
          
          if (preservedActivations) {
            console.log('🔍 PRESERVATION DETAILS:')
            console.log('🔍 Current boosters:', JSON.stringify(currentBoosters, null, 2))
            console.log('🔍 Original incoming boosters:', JSON.stringify(originalIncomingBoosters, null, 2))
          }
        }
        
        if (preservedActivations) {
          console.log('🔄 Syncing preserved activations back to database...')
          console.log('🔄 Syncing this booster state:', JSON.stringify(match.value.boosters, null, 2))
          // Update the database with our preserved activations
          updateMatch({ boosters: match.value.boosters }).catch(error => {
            console.error('❌ Failed to sync preserved activations:', error)
          })
        }
        
        updateBoosterTimers()
      })
      .subscribe()

    // Update booster timers based on current match state
    updateBoosterTimers()
    
  } catch (err) {
    console.error('Error loading match:', err)
    error.value = 'Failed to load match data'
  } finally {
    loading.value = false
  }
}

// Update booster timers for active boosters
function updateBoosterTimers() {
  if (!match.value?.boosters) return

  // Clear existing timers
  Object.values(activeBoosterTimers.value).forEach(timer => {
    if (timer.intervalId) {
      clearInterval(timer.intervalId)
    }
  })
  activeBoosterTimers.value = {}

  // Set up timers for active boosters
  const teams = ['teamA', 'teamB']
  teams.forEach(teamKey => {
    const teamSide = teamKey === 'teamA' ? 'a' : 'b'
    const boosters = match.value?.boosters?.[teamKey as keyof typeof match.value.boosters] || []
    
    boosters.forEach((booster: any, index: number) => {
      if (booster.activated && booster.activatedAt && booster.duration) {
        const activatedTime = new Date(booster.activatedAt).getTime()
        const durationMs = booster.duration * 60 * 1000 // Convert minutes to milliseconds
        const endTime = activatedTime + durationMs
        const now = Date.now()
        const timeLeft = Math.max(0, (endTime - now) / 1000) // Convert to seconds

        if (timeLeft > 0) {
          const timerId = `${teamSide}_${index}`
          
          // Create timer tracking object
          const timerObj = {
            timeLeft,
            intervalId: setInterval(() => {
              const currentTimeLeft = Math.max(0, (endTime - Date.now()) / 1000)
              const timer = activeBoosterTimers.value[timerId]
              if (timer) {
                timer.timeLeft = currentTimeLeft
                
                if (currentTimeLeft <= 0) {
                  clearInterval(timer.intervalId)
                  delete activeBoosterTimers.value[timerId]
                  
                  // Mark booster as expired in database
                  markBoosterAsExpired(teamKey, booster.id)
                }
              }
            }, 1000)
          }
          
          activeBoosterTimers.value[timerId] = timerObj
        }
      }
    })
  })
}

// Mark booster as expired in database
async function markBoosterAsExpired(teamKey: string, boosterId: string) {
  if (!match.value) return
  
  try {
    console.log(`🚫 Marking booster ${boosterId} as expired for ${teamKey}`)
    
    // Get current boosters
    const updatedBoosters = { ...match.value.boosters }
    
    // Find and mark the booster as expired
    const teamKeyTyped = teamKey as 'teamA' | 'teamB'
    if (updatedBoosters[teamKeyTyped]) {
      updatedBoosters[teamKeyTyped] = updatedBoosters[teamKeyTyped].map((booster: any) => {
        if (booster.id === boosterId) {
          return { ...booster, expired: true }
        }
        return booster
      })
    }
    
    // Update database
    const { error } = await supabase
      .from('matches')
      .update({ boosters: updatedBoosters })
      .eq('id', match.value.id)
      
    if (error) {
      console.error('Error marking booster as expired:', error)
    } else {
      console.log(`✅ Booster ${boosterId} marked as expired in database`)
      // Update local match state immediately
      if (match.value) {
        match.value.boosters = updatedBoosters
      }
    }
  } catch (error) {
    console.error('Error marking booster as expired:', error)
  }
}

// Load tournament standings
async function loadTournamentStandings() {
  try {
    const allTeams = Object.values(teams.value)
    const standingsData: TeamStanding[] = []

    for (const team of allTeams) {
      const { data: matches } = await supabase
        .from('matches')
        .select('*')
        .or(`team_a.eq.${team.id},team_b.eq.${team.id}`)
        .eq('status', 'finished')

      let wins = 0
      let losses = 0
      let draws = 0
      let goalsFor = 0
      let goalsAgainst = 0

      matches?.forEach(match => {
        const isTeamA = match.team_a === team.id
        const teamScore = isTeamA ? match.score_a : match.score_b
        const opponentScore = isTeamA ? match.score_b : match.score_a

        goalsFor += teamScore
        goalsAgainst += opponentScore

        if (teamScore > opponentScore) {
          wins++
        } else if (teamScore < opponentScore) {
          losses++
        } else {
          draws++
        }
      })

      const points = wins * 3 + draws * 1

      standingsData.push({
        id: team.id,
        name: team.name,
        points,
        wins,
        losses,
        goals_for: goalsFor,
        goals_against: goalsAgainst
      })
    }

    standings.value = standingsData.sort((a, b) => {
      const pointsDiff = b.points - a.points
      if (pointsDiff !== 0) return pointsDiff
      
      const goalDiffA = a.goals_for - a.goals_against
      const goalDiffB = b.goals_for - b.goals_against
      return goalDiffB - goalDiffA
    })
  } catch (error) {
    console.error('Error loading standings:', error)
  } finally {
    loadingStandings.value = false
  }
}

// Update match function (same pattern as MatchControlView)
async function updateMatch(updates: Partial<any>) {
  console.log('🔧 updateMatch function started (MatchCenterView)')
  
  try {
    console.log('� Updating match with:', updates)
    console.log('� Match ID:', match.value?.id)
    
    // DETAILED DEBUGGING: Log the exact boosters structure being sent
    if (updates.boosters) {
      console.log('🔍 EXACT BOOSTERS BEING SENT TO DB:', JSON.stringify(updates.boosters, null, 2))
    }
    
    console.log('� About to call supabase update...')
    
    // Try the simplest possible update
    const result = await supabase
      .from('matches')
      .update(updates)
      .eq('id', match.value?.id)
    
    console.log('� Supabase update result:', result)
    
    if (result.error) {
      console.error('❌ Error updating match:', result.error)
      throw result.error
    }

    console.log('✅ Match updated successfully')
    
    // VERIFICATION: Check what was actually saved to database
    console.log('🔍 VERIFICATION: Fetching match from database to confirm update...')
    const { data: verificationData, error: verificationError } = await supabase
      .from('matches')
      .select('boosters')
      .eq('id', match.value?.id)
      .single()
    
    if (verificationError) {
      console.error('❌ Verification fetch failed:', verificationError)
    } else {
      console.log('🔍 DATABASE VERIFICATION - What was actually saved:', JSON.stringify(verificationData.boosters, null, 2))
    }
    
    // Update local state
    if (match.value) {
      Object.assign(match.value, updates)
      console.log('✅ Local state updated:', { boosters: match.value.boosters })
    }
    
    return { success: true }
  } catch (error) {
    console.error('❌ Exception updating match:', error)
    throw error
  }
}

// Activate booster for user's team
async function activateUserBooster(boosterIndex: number) {
  console.log('🎯 activateUserBooster called with index:', boosterIndex)
  console.log('🎯 Pre-checks:', {
    hasMatch: !!match.value,
    userTeamSide: userTeamSide.value,
    activatingBooster: activatingBooster.value
  })
  
  if (!match.value || !userTeamSide.value || activatingBooster.value) {
    console.log('❌ Activation blocked by pre-checks')
    return
  }

  activatingBooster.value = true
  
  try {
    const teamKey = userTeamSide.value === 'a' ? 'teamA' : 'teamB'
    const boosters = { ...match.value.boosters }
    
    console.log('🎯 Activation details:', {
      teamKey,
      boosterIndex,
      hasTeamBoosters: !!boosters[teamKey],
      boosterExists: !!(boosters[teamKey] && boosters[teamKey][boosterIndex]),
      isNotActivated: boosters[teamKey] && boosters[teamKey][boosterIndex] ? !boosters[teamKey][boosterIndex].activated : false,
      currentBooster: boosters[teamKey] ? boosters[teamKey][boosterIndex] : null
    })
    
    if (boosters[teamKey] && boosters[teamKey][boosterIndex] && !boosters[teamKey][boosterIndex].activated && !boosters[teamKey][boosterIndex].countdown) {
      const updatedTeamBoosters = [...boosters[teamKey]]
      const booster = updatedTeamBoosters[boosterIndex]
      
      // Start countdown first
      updatedTeamBoosters[boosterIndex] = {
        ...booster,
        countdown: true,
        countdownStartedAt: new Date().toISOString(),
        activatedBy: authStore.profile?.email || 'user'
      }
      
      boosters[teamKey] = updatedTeamBoosters
      
      console.log(`🏑 User starting countdown for team ${userTeamSide.value.toUpperCase()} booster:`, {
        boosterIndex,
        booster: updatedTeamBoosters[boosterIndex],
        fullBoosterState: boosters,
        matchId: match.value.id
      })

      // DETAILED DEBUGGING: Check the exact booster countdown start
      console.log('🔍 BOOSTER COUNTDOWN VERIFICATION:')
      console.log('🔍 Team Key:', teamKey)
      console.log('🔍 Booster Index:', boosterIndex)
      console.log('🔍 Updated Booster Object:', JSON.stringify(updatedTeamBoosters[boosterIndex], null, 2))
      console.log('🔍 Full Boosters Object for DB:', JSON.stringify(boosters, null, 2))

      // Use the same update pattern as MatchControlView
      await updateMatch({ boosters })
      
      // Start 7-second countdown before actual activation
      setTimeout(async () => {
        try {
          // Double-check booster still exists and countdown is still active
          const currentMatch = await supabase
            .from('matches')
            .select('boosters')
            .eq('id', match.value?.id)
            .single()
          
          if (currentMatch.error) {
            console.error('Error checking match state during countdown:', currentMatch.error)
            return
          }
          
          const currentBoosters = currentMatch.data.boosters
          const currentBooster = currentBoosters?.[teamKey]?.[boosterIndex]
          
          if (!currentBooster?.countdown) {
            console.log('🚫 User booster countdown was cancelled or already processed')
            return
          }
          
          // Now actually activate the booster
          console.log(`🚀 User countdown complete - activating booster for team ${userTeamSide.value?.toUpperCase() || 'UNKNOWN'}`)
          
          const finalBoosters = { ...currentBoosters }
          const finalUpdatedTeamBoosters = [...finalBoosters[teamKey]]
          
          finalUpdatedTeamBoosters[boosterIndex] = {
            ...currentBooster,
            activated: true,
            activatedAt: new Date().toISOString(),
            countdown: false // Clear countdown flag
          }
          
          finalBoosters[teamKey] = finalUpdatedTeamBoosters
          
          // Update database with final activation
          await updateMatch({ boosters: finalBoosters })
          
        } catch (error) {
          console.error('Error during user booster activation after countdown:', error)
        }
      }, 7000) // 7 seconds countdown
      
      console.log('✅ Database updated successfully with booster countdown started:', {
        matchId: match.value.id,
        updatedBoosters: boosters
      })
      
      console.log('🕐 DETAILED COUNTDOWN DATA:', {
        teamKey,
        countdownBooster: updatedTeamBoosters[boosterIndex],
        fullTeamABoosters: boosters.teamA,
        fullTeamBBoosters: boosters.teamB
      })
      
      console.log('🏑 MATCH CENTER - Booster countdown started for match:', match.value.id)

      // Local state updated by updateMatch function
      
      // IMMEDIATE CHECK: Verify local state after update
      console.log('🔍 IMMEDIATE LOCAL STATE CHECK:', JSON.stringify(match.value?.boosters, null, 2))
      
      // Set up timer for timed boosters
      if (booster.duration && booster.duration > 0) {
        updateBoosterTimers()
      }

      console.log('✅ Booster activated successfully!')
    } else {
      console.log('❌ Booster activation conditions not met:', {
        teamKey,
        boosterIndex,
        hasTeamBoosters: !!boosters[teamKey],
        teamBoostersLength: boosters[teamKey]?.length || 0,
        boosterExists: !!(boosters[teamKey] && boosters[teamKey][boosterIndex]),
        boosterData: boosters[teamKey] ? boosters[teamKey][boosterIndex] : null,
        isAlreadyActivated: boosters[teamKey] && boosters[teamKey][boosterIndex] ? boosters[teamKey][boosterIndex].activated : 'N/A'
      })
    }
  } catch (error) {
    console.error('❌ Error activating booster:', error)
    alert('Failed to activate booster. Please try again.')
  } finally {
    activatingBooster.value = false
  }
}

// Helper functions
function getTeamName(teamId: string) {
  return teams.value[teamId]?.name || 'Unknown Team'
}

function getMatchStatusClass(status: string) {
  switch (status) {
    case 'active':
      return 'bg-green-500 text-white'
    case 'pending':
      return 'bg-yellow-500 text-black'
    case 'paused':
      return 'bg-orange-500 text-white'
    case 'finished':
      return 'bg-gray-500 text-white'
    default:
      return 'bg-gray-400 text-white'
  }
}

function formatTimeLeft(seconds: number) {
  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${minutes}:${secs.toString().padStart(2, '0')}`
}

function getTeamBoosters(teamKey: 'teamA' | 'teamB') {
  return match.value?.boosters?.[teamKey] || []
}

function getUserTeamBoosters() {
  if (!userTeamSide.value) return []
  const teamKey = userTeamSide.value === 'a' ? 'teamA' : 'teamB'
  return getTeamBoosters(teamKey)
}

function getStandingRowClass(teamId: string) {
  if (teamId === userTeam.value?.id) {
    return 'bg-blue-600/30 border border-blue-400'
  }
  if (teamId === match.value?.team_a || teamId === match.value?.team_b) {
    return 'bg-white/10 border border-white/20'
  }
  return 'bg-white/5'
}

function isHighlightedTeam(teamId: string) {
  return teamId === userTeam.value?.id || teamId === match.value?.team_a || teamId === match.value?.team_b
}

function getTeamLabel(teamId: string) {
  if (teamId === userTeam.value?.id) return 'YOUR TEAM'
  if (teamId === match.value?.team_a || teamId === match.value?.team_b) return 'IN MATCH'
  return ''
}

// Initialize component
onMounted(async () => {
  await Promise.all([
    loadTeams(),
    loadUserTeam()
  ])
  
  await loadMatch()
  await loadTournamentStandings()

  // Set up timer update interval
  timerInterval = setInterval(() => {
    // Timer updates are handled by real-time subscription
  }, 1000)
})

// Cleanup
onUnmounted(() => {
  if (matchSubscription) {
    matchSubscription.unsubscribe()
  }
  
  if (timerInterval) {
    clearInterval(timerInterval)
  }

  // Clear all booster timers
  Object.values(activeBoosterTimers.value).forEach(timer => {
    if (timer.intervalId) {
      clearInterval(timer.intervalId)
    }
  })
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