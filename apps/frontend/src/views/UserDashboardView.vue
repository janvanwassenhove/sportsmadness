<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-white mb-4">
          Welcome, {{ getUserDisplayName() }}! �
        </h1>
        <div v-if="userTeam" class="text-xl text-blue-100">
          <span class="bg-blue-600 px-4 py-2 rounded-full">
            {{ userTeam.name }} Team Member
          </span>
        </div>
        <div v-else class="text-lg text-blue-200">
          You're not currently assigned to a team
        </div>
      </div>

      <!-- Main Dashboard Grid -->
      <div class="grid lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
        
        <!-- Left Column: Team Matches -->
        <div class="lg:col-span-2 space-y-6">
          
          <!-- Upcoming Matches -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <div class="flex items-center mb-6">
              <h2 class="text-2xl font-bold text-white">📅 Upcoming Matches</h2>
              <div v-if="userTeam" class="ml-4 text-sm text-blue-200">
                for {{ userTeam.name }}
              </div>
            </div>
            
            <!-- Loading State -->
            <div v-if="loadingMatches" class="text-center py-8">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-white mx-auto mb-2"></div>
              <p class="text-blue-200">Loading matches...</p>
            </div>

            <!-- No Team Assigned -->
            <div v-else-if="!userTeam" class="text-center py-8">
              <div class="text-6xl mb-4">👥</div>
              <p class="text-xl text-white mb-2">No Team Assigned</p>
              <p class="text-blue-200">Contact an administrator to be assigned to a team</p>
            </div>

            <!-- No Matches -->
            <div v-else-if="!upcomingMatches.length" class="text-center py-8">
              <div class="text-6xl mb-4">📊</div>
              <p class="text-xl text-white mb-2">No Upcoming Matches</p>
              <p class="text-blue-200">Your team doesn't have any scheduled matches at the moment</p>
            </div>

            <!-- Matches List -->
            <div v-else class="space-y-4">
              <RouterLink
                v-for="match in upcomingMatches" 
                :key="match.id"
                :to="{ name: 'match-center', params: { id: match.id } }"
                class="block bg-white/5 hover:bg-white/10 rounded-lg p-4 border border-white/10 transition-colors cursor-pointer"
              >
                <div class="flex justify-between items-center mb-3">
                  <div class="flex items-center space-x-4">
                    <span class="text-lg font-semibold text-white">
                      {{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}
                    </span>
                    <span 
                      class="px-3 py-1 rounded-full text-xs font-semibold"
                      :class="getMatchStatusClass(match.status)"
                    >
                      {{ match.status }}
                    </span>
                  </div>
                  <div class="text-right text-sm text-blue-200">
                    <div v-if="match.match_date">{{ formatMatchDate(match.match_date) }}</div>
                    <div v-if="match.start_time">{{ match.start_time }}</div>
                  </div>
                </div>
                
                <div class="flex justify-between items-center">
                  <div class="text-2xl font-bold text-white">
                    {{ match.score_a }} - {{ match.score_b }}
                  </div>
                  <div class="text-sm text-blue-200">
                    <div v-if="match.time_left && match.status === 'active'">
                      ⏱️ {{ formatTimeLeft(match.time_left) }} remaining
                    </div>
                    <div v-if="match.tournament_id || match.division_id" class="mt-1">
                      🏆 Tournament Match
                    </div>
                  </div>
                </div>
              </RouterLink>
            </div>
          </div>

          <!-- Recent Results -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-white mb-6">📈 Recent Results</h2>
            
            <div v-if="recentMatches.length === 0" class="text-center py-8">
              <div class="text-4xl mb-4">📝</div>
              <p class="text-blue-200">No recent matches to display</p>
            </div>
            
            <div v-else class="space-y-3">
              <RouterLink 
                v-for="match in recentMatches" 
                :key="match.id"
                :to="{ name: 'match-center', params: { id: match.id } }"
                class="block bg-white/5 hover:bg-white/10 rounded-lg p-3 border border-white/10 transition-colors cursor-pointer"
              >
                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-3">
                    <span class="text-white font-medium">
                      {{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}
                    </span>
                    <span class="text-lg font-bold text-white">
                      {{ match.score_a }} - {{ match.score_b }}
                    </span>
                    <span 
                      class="px-2 py-1 rounded text-xs font-semibold"
                      :class="getMatchResultClass(match, userTeam?.id)"
                    >
                      {{ getMatchResult(match, userTeam?.id) }}
                    </span>
                  </div>
                  <div class="text-xs text-blue-200">
                    {{ formatMatchDate(match.created_at) }}
                  </div>
                </div>
              </RouterLink>
            </div>
          </div>
        </div>

        <!-- Right Column: Tournament & Help -->
        <div class="space-y-6">
          
          <!-- Tournament Standings -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-white mb-6">🏆 Tournament Standings</h2>
            
            <div v-if="loadingStandings" class="text-center py-4">
              <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-white mx-auto mb-2"></div>
              <p class="text-blue-200 text-sm">Loading standings...</p>
            </div>
            
            <div v-else-if="standings.length === 0" class="text-center py-8">
              <div class="text-4xl mb-4">📊</div>
              <p class="text-blue-200">No tournament data available</p>
            </div>
            
            <div v-else class="space-y-2">
              <div 
                v-for="(team, index) in standings" 
                :key="team.id"
                class="flex justify-between items-center p-3 rounded-lg"
                :class="team.id === userTeam?.id ? 'bg-blue-600/30 border border-blue-400' : 'bg-white/5'"
              >
                <div class="flex items-center space-x-3">
                  <span class="font-bold text-white w-6">{{ index + 1 }}.</span>
                  <span class="text-white" :class="{ 'font-bold': team.id === userTeam?.id }">
                    {{ team.name }}
                  </span>
                  <span v-if="team.id === userTeam?.id" class="text-xs bg-blue-500 px-2 py-1 rounded">
                    YOUR TEAM
                  </span>
                </div>
                <div class="text-right">
                  <div class="text-white font-bold">{{ team.points || 0 }} pts</div>
                  <div class="text-xs text-blue-200">{{ team.wins || 0 }}W {{ team.losses || 0 }}L</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Help Section -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-white mb-6">❓ Game Help</h2>
            
            <div class="space-y-6">
              <!-- Boosters Section -->
              <div>
                <h3 class="text-lg font-semibold text-white mb-3 flex items-center">
                  ⚡ Boosters
                </h3>
                <div class="space-y-3 text-sm text-blue-100">
                  <div class="bg-white/5 rounded-lg p-3">
                    <div class="font-semibold text-white mb-1">🚀 Speed Boost</div>
                    <p>Increases team movement speed for a limited time</p>
                  </div>
                  <div class="bg-white/5 rounded-lg p-3">
                    <div class="font-semibold text-white mb-1">🎯 Accuracy Boost</div>
                    <p>Improves shooting accuracy and goal-scoring chances</p>
                  </div>
                  <div class="bg-white/5 rounded-lg p-3">
                    <div class="font-semibold text-white mb-1">🛡️ Defense Boost</div>
                    <p>Strengthens defensive capabilities and blocking</p>
                  </div>
                  <div class="bg-white/5 rounded-lg p-3">
                    <div class="font-semibold text-white mb-1">⭐ Power Play</div>
                    <p>Temporary advantage with enhanced all-around performance</p>
                  </div>
                </div>
              </div>

              <!-- Maddies Section -->
              <div>
                <h3 class="text-lg font-semibold text-white mb-3 flex items-center">
                  🎪 Maddies
                </h3>
                <div class="bg-white/5 rounded-lg p-4">
                  <div class="font-semibold text-white mb-2">🎭 Maddie Events</div>
                  <p class="text-blue-100 text-sm mb-3">
                    Special chaotic events that can dramatically change the game!
                  </p>
                  <ul class="space-y-2 text-sm text-blue-100">
                    <li class="flex items-start">
                      <span class="mr-2">🌪️</span>
                      <span><strong>Chaos Mode:</strong> Unpredictable gameplay changes</span>
                    </li>
                    <li class="flex items-start">
                      <span class="mr-2">🔄</span>
                      <span><strong>Team Swap:</strong> Players switch sides temporarily</span>
                    </li>
                    <li class="flex items-start">
                      <span class="mr-2">⚡</span>
                      <span><strong>Lightning Round:</strong> Super fast-paced gameplay</span>
                    </li>
                    <li class="flex items-start">
                      <span class="mr-2">🎲</span>
                      <span><strong>Random Events:</strong> Surprise effects during play</span>
                    </li>
                  </ul>
                </div>
              </div>

              <!-- Strategy Tips -->
              <div>
                <h3 class="text-lg font-semibold text-white mb-3">💡 Pro Tips</h3>
                <div class="bg-white/5 rounded-lg p-4 space-y-2 text-sm text-blue-100">
                  <p><strong>⏱️ Timing:</strong> Save boosters for crucial moments</p>
                  <p><strong>🎯 Strategy:</strong> Coordinate with your team for maximum effect</p>
                  <p><strong>🎪 Adaptation:</strong> Stay flexible when Maddie events trigger</p>
                  <p><strong>📊 Analytics:</strong> Watch the scoreboard for opponent patterns</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="mt-8 flex justify-center space-x-4">
        <RouterLink 
          to="/scoreboard" 
          class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition-colors flex items-center space-x-2"
        >
          <span>📺</span>
          <span>Live Scoreboard</span>
        </RouterLink>
        <RouterLink 
          to="/profile" 
          class="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-lg font-medium transition-colors flex items-center space-x-2"
        >
          <span>👤</span>
          <span>My Profile</span>
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
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
}

interface Team {
  id: string
  name: string
  players: any[]
}

interface TeamStanding {
  id: string
  name: string
  points: number
  wins: number
  losses: number
  draws: number
  goals_for: number
  goals_against: number
}

const authStore = useAuthStore()
const userTeam = ref<Team | null>(null)
const upcomingMatches = ref<Match[]>([])
const recentMatches = ref<Match[]>([])
const standings = ref<TeamStanding[]>([])
const teams = ref<Record<string, Team>>({})
const loadingMatches = ref(true)
const loadingStandings = ref(true)

// Get user display name
function getUserDisplayName() {
  const user = authStore.user
  if (user?.user_metadata?.firstName || user?.user_metadata?.lastName) {
    return `${user.user_metadata.firstName || ''} ${user.user_metadata.lastName || ''}`.trim()
  }
  return authStore.profile?.email?.split('@')[0] || 'User'
}

// Load user's assigned team
async function loadUserTeam() {
  if (!authStore.profile?.assigned_team_id) {
    return
  }

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

// Load all teams for reference
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

// Load matches for user's team
async function loadUserMatches() {
  if (!userTeam.value) {
    loadingMatches.value = false
    return
  }

  try {
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .or(`team_a.eq.${userTeam.value.id},team_b.eq.${userTeam.value.id}`)
      .order('created_at', { ascending: false })

    if (error) throw error

    const matches = data || []
    
    // Separate upcoming and recent matches
    upcomingMatches.value = matches.filter(m => m.status === 'pending' || m.status === 'active').slice(0, 5)
    recentMatches.value = matches.filter(m => m.status === 'finished').slice(0, 5)
  } catch (error) {
    console.error('Error loading matches:', error)
  } finally {
    loadingMatches.value = false
  }
}

// Generate mock tournament standings
async function loadTournamentStandings() {
  try {
    // Get all teams and calculate basic standings
    const allTeams = Object.values(teams.value)
    const standingsData: TeamStanding[] = []

    for (const team of allTeams) {
      // Get matches for this team
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
        draws,
        goals_for: goalsFor,
        goals_against: goalsAgainst
      })
    }

    // Sort by points (descending), then by goal difference
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
    case 'finished':
      return 'bg-gray-500 text-white'
    default:
      return 'bg-gray-400 text-white'
  }
}

function getMatchResult(match: Match, teamId?: string) {
  if (!teamId) return 'N/A'
  
  const isTeamA = match.team_a === teamId
  const teamScore = isTeamA ? match.score_a : match.score_b
  const opponentScore = isTeamA ? match.score_b : match.score_a

  if (teamScore > opponentScore) return 'WIN'
  if (teamScore < opponentScore) return 'LOSS'
  return 'DRAW'
}

function getMatchResultClass(match: Match, teamId?: string) {
  const result = getMatchResult(match, teamId)
  switch (result) {
    case 'WIN':
      return 'bg-green-500 text-white'
    case 'LOSS':
      return 'bg-red-500 text-white'
    case 'DRAW':
      return 'bg-yellow-500 text-black'
    default:
      return 'bg-gray-400 text-white'
  }
}

function formatMatchDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

function formatTimeLeft(seconds: number) {
  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${minutes}:${secs.toString().padStart(2, '0')}`
}

// Initialize data
onMounted(async () => {
  await loadTeams()
  await loadUserTeam()
  await Promise.all([
    loadUserMatches(),
    loadTournamentStandings()
  ])
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