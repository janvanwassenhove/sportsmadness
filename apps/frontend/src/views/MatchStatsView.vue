<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import type { TimelineEvent } from '@/types/timeline'
import { formatTimelineEvent, getEventsByType, getEventsByTeam } from '@/types/timeline'

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  pc_a?: number
  pc_b?: number
  status: 'pending' | 'active' | 'paused' | 'finished'
  time_left: number
  timeline?: TimelineEvent[]
  created_at: string
}

interface Team {
  id: string
  name: string
  players: any[]
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const match = ref<Match | null>(null)
const teams = ref<Record<string, Team>>({})
const loading = ref(true)
const filterType = ref<string>('all')
const filterTeam = ref<string>('all')

const matchId = computed(() => route.params.id as string)

const teamA = computed(() => match.value ? teams.value[match.value.team_a] : null)
const teamB = computed(() => match.value ? teams.value[match.value.team_b] : null)

// Timeline sorted by timestamp (most recent first)
const sortedTimeline = computed(() => {
  if (!match.value?.timeline) return []
  
  return [...match.value.timeline].sort((a, b) => {
    return new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  })
})

// Filtered timeline based on filters
const filteredTimeline = computed(() => {
  let events = sortedTimeline.value
  
  // Filter by event type
  if (filterType.value !== 'all') {
    events = events.filter(event => event.type === filterType.value)
  }
  
  // Filter by team
  if (filterTeam.value !== 'all') {
    events = events.filter(event => event.team === filterTeam.value)
  }
  
  return events
})

// Statistics
const stats = computed(() => {
  if (!match.value?.timeline) return null
  
  const teamAEvents = getEventsByTeam(match.value.timeline, 'a')
  const teamBEvents = getEventsByTeam(match.value.timeline, 'b')
  
  const teamAGoals = teamAEvents.filter(e => e.type === 'goal').length
  const teamBGoals = teamBEvents.filter(e => e.type === 'goal').length
  
  const teamAPCs = teamAEvents.filter(e => e.type === 'penalty_corner').length
  const teamBPCs = teamBEvents.filter(e => e.type === 'penalty_corner').length
  
  const teamABoosters = teamAEvents.filter(e => e.type === 'booster_activated').length
  const teamBBoosters = teamBEvents.filter(e => e.type === 'booster_activated').length
  
  const teamACards = teamAEvents.filter(e => e.type === 'card_issued')
  const teamBCards = teamBEvents.filter(e => e.type === 'card_issued')
  
  const maddies = match.value.timeline.filter(e => e.type === 'maddie_activated').length
  
  return {
    teamA: {
      goals: teamAGoals,
      pcs: teamAPCs,
      boosters: teamABoosters,
      cards: {
        yellow: teamACards.filter((e: any) => e.details.card_type === 'yellow').length,
        green: teamACards.filter((e: any) => e.details.card_type === 'green').length,
        red: teamACards.filter((e: any) => e.details.card_type === 'red').length,
        total: teamACards.length
      }
    },
    teamB: {
      goals: teamBGoals,
      pcs: teamBPCs,
      boosters: teamBBoosters,
      cards: {
        yellow: teamBCards.filter((e: any) => e.details.card_type === 'yellow').length,
        green: teamBCards.filter((e: any) => e.details.card_type === 'green').length,
        red: teamBCards.filter((e: any) => e.details.card_type === 'red').length,
        total: teamBCards.length
      }
    },
    maddies,
    totalEvents: match.value.timeline.length
  }
})

// Get event icon
function getEventIcon(event: TimelineEvent): string {
  switch (event.type) {
    case 'goal':
      return '⚽'
    case 'penalty_corner':
      return '🏒'
    case 'booster_activated':
      return (event as any).details.booster_icon || '⚡'
    case 'maddie_activated':
      return (event as any).details.maddie_icon || '🎪'
    case 'card_issued':
      const cardType = (event as any).details.card_type
      return cardType === 'yellow' ? '🟨' : cardType === 'green' ? '🟩' : '🟥'
    case 'match_started':
      return '▶️'
    case 'match_paused':
      return '⏸️'
    case 'match_resumed':
      return '▶️'
    case 'match_finished':
      return '🏁'
    default:
      return '📝'
  }
}

// Get event color class
function getEventColorClass(event: TimelineEvent): string {
  if (event.team === 'a') return 'border-l-4 border-blue-500 bg-blue-50'
  if (event.team === 'b') return 'border-l-4 border-orange-500 bg-orange-50'
  return 'border-l-4 border-purple-500 bg-purple-50'
}

// Format timestamp
function formatTimestamp(timestamp: string): string {
  const date = new Date(timestamp)
  return date.toLocaleTimeString('en-US', { 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  })
}

async function loadMatch() {
  try {
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .eq('id', matchId.value)
      .single()

    if (error) {
      console.error('Error loading match:', error)
      return
    }

    match.value = data
  } catch (error) {
    console.error('Error loading match:', error)
  }
}

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')

    if (error) {
      console.error('Error loading teams:', error)
      return
    }

    const teamsMap: Record<string, Team> = {}
    data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
  } catch (error) {
    console.error('Error loading teams:', error)
  }
}

function goBack() {
  router.push(`/match-control/${matchId.value}`)
}

onMounted(async () => {
  loading.value = true
  await Promise.all([loadMatch(), loadTeams()])
  loading.value = false
})
</script>

<template>
  <div class="min-h-screen bg-base-200 p-4">
    <div v-if="loading" class="text-center py-16">
      <span class="loading loading-spinner loading-lg"></span>
      <p class="mt-4">{{ t('loading') }}</p>
    </div>

    <div v-else-if="match" class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <button @click="goBack" class="btn btn-ghost btn-sm mb-2">
            ← Back to Match Control
          </button>
          <h1 class="text-3xl font-bold">Match Statistics & Timeline</h1>
          <p class="text-sm opacity-70">
            {{ teamA?.name || 'Team A' }} vs {{ teamB?.name || 'Team B' }}
          </p>
        </div>
        <div class="text-right">
          <div class="text-4xl font-bold">
            {{ match.score_a }} - {{ match.score_b }}
          </div>
          <div class="badge" :class="{
            'badge-success': match.status === 'active',
            'badge-warning': match.status === 'paused',
            'badge-info': match.status === 'pending',
            'badge-neutral': match.status === 'finished'
          }">
            {{ match.status.toUpperCase() }}
          </div>
        </div>
      </div>

      <!-- Statistics Summary -->
      <div v-if="stats" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <!-- Team A Stats -->
        <div class="card bg-blue-100 shadow-lg">
          <div class="card-body">
            <h3 class="card-title text-blue-800">{{ teamA?.name || 'Team A' }}</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span>⚽ Goals:</span>
                <span class="font-bold">{{ stats.teamA.goals }}</span>
              </div>
              <div class="flex justify-between">
                <span>🏒 Penalty Corners:</span>
                <span class="font-bold">{{ stats.teamA.pcs }}</span>
              </div>
              <div class="flex justify-between">
                <span>⚡ Boosters Used:</span>
                <span class="font-bold">{{ stats.teamA.boosters }}</span>
              </div>
              <div class="flex justify-between">
                <span>Cards:</span>
                <span class="font-bold">
                  <span v-if="stats.teamA.cards.yellow" class="mr-1">🟨{{ stats.teamA.cards.yellow }}</span>
                  <span v-if="stats.teamA.cards.green" class="mr-1">🟩{{ stats.teamA.cards.green }}</span>
                  <span v-if="stats.teamA.cards.red">🟥{{ stats.teamA.cards.red }}</span>
                  <span v-if="!stats.teamA.cards.total">None</span>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Match Stats -->
        <div class="card bg-purple-100 shadow-lg">
          <div class="card-body">
            <h3 class="card-title text-purple-800">Match Stats</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span>🎪 Maddies:</span>
                <span class="font-bold">{{ stats.maddies }}</span>
              </div>
              <div class="flex justify-between">
                <span>📊 Total Events:</span>
                <span class="font-bold">{{ stats.totalEvents }}</span>
              </div>
              <div class="flex justify-between">
                <span>📝 Current Score:</span>
                <span class="font-bold">{{ match.score_a }} - {{ match.score_b }}</span>
              </div>
              <div class="flex justify-between">
                <span>⏱️ Time Left:</span>
                <span class="font-bold">{{ Math.floor(match.time_left / 60) }}:{{ String(match.time_left % 60).padStart(2, '0') }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Team B Stats -->
        <div class="card bg-orange-100 shadow-lg">
          <div class="card-body">
            <h3 class="card-title text-orange-800">{{ teamB?.name || 'Team B' }}</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span>⚽ Goals:</span>
                <span class="font-bold">{{ stats.teamB.goals }}</span>
              </div>
              <div class="flex justify-between">
                <span>🏒 Penalty Corners:</span>
                <span class="font-bold">{{ stats.teamB.pcs }}</span>
              </div>
              <div class="flex justify-between">
                <span>⚡ Boosters Used:</span>
                <span class="font-bold">{{ stats.teamB.boosters }}</span>
              </div>
              <div class="flex justify-between">
                <span>Cards:</span>
                <span class="font-bold">
                  <span v-if="stats.teamB.cards.yellow" class="mr-1">🟨{{ stats.teamB.cards.yellow }}</span>
                  <span v-if="stats.teamB.cards.green" class="mr-1">🟩{{ stats.teamB.cards.green }}</span>
                  <span v-if="stats.teamB.cards.red">🟥{{ stats.teamB.cards.red }}</span>
                  <span v-if="!stats.teamB.cards.total">None</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters -->
      <div class="card bg-base-100 shadow-lg mb-6">
        <div class="card-body">
          <h3 class="card-title mb-4">Filters</h3>
          <div class="flex flex-wrap gap-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Event Type</span>
              </label>
              <select v-model="filterType" class="select select-bordered">
                <option value="all">All Events</option>
                <option value="goal">Goals</option>
                <option value="penalty_corner">Penalty Corners</option>
                <option value="booster_activated">Boosters</option>
                <option value="maddie_activated">Maddies</option>
                <option value="card_issued">Cards</option>
                <option value="match_started">Match Started</option>
                <option value="match_paused">Match Paused</option>
                <option value="match_finished">Match Finished</option>
              </select>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Team</span>
              </label>
              <select v-model="filterTeam" class="select select-bordered">
                <option value="all">All Teams</option>
                <option value="a">{{ teamA?.name || 'Team A' }}</option>
                <option value="b">{{ teamB?.name || 'Team B' }}</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Timeline -->
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <h3 class="card-title mb-4">Match Timeline</h3>
          
          <div v-if="filteredTimeline.length === 0" class="text-center py-8 text-base-content/50">
            No events to display
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="(event, index) in filteredTimeline"
              :key="index"
              class="p-4 rounded-lg transition-all hover:shadow-md"
              :class="getEventColorClass(event)"
            >
              <div class="flex items-start gap-3">
                <div class="text-3xl">{{ getEventIcon(event) }}</div>
                <div class="flex-1">
                  <div class="flex justify-between items-start">
                    <p class="font-medium">
                      {{ formatTimelineEvent(event, teamA?.name || 'Team A', teamB?.name || 'Team B') }}
                    </p>
                    <span class="text-xs opacity-70">{{ formatTimestamp(event.timestamp) }}</span>
                  </div>
                  
                  <!-- Additional details for specific event types -->
                  <div v-if="event.type === 'booster_activated'" class="mt-2 text-sm opacity-80">
                    Duration: {{ (event as any).details.duration ? `${(event as any).details.duration} min` : 'Instant' }}
                  </div>
                  <div v-if="event.type === 'maddie_activated'" class="mt-2 text-sm opacity-80">
                    Duration: {{ (event as any).details.duration ? `${(event as any).details.duration} min` : 'Instant' }}
                  </div>
                  <div v-if="event.type === 'card_issued'" class="mt-2 text-sm opacity-80">
                    Penalty: {{ (event as any).details.duration === 'never' ? 'Game' : `${(event as any).details.duration / 60} min` }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="text-center py-16">
      <p class="text-xl">Match not found</p>
      <button @click="router.push('/admin')" class="btn btn-primary mt-4">
        Go to Admin Panel
      </button>
    </div>
  </div>
</template>

<style scoped>
/* Add any custom styles here */
</style>
