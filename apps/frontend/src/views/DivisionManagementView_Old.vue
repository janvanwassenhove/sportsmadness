<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-pink-900 p-4">
    <div class="container mx-auto">
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-4xl font-bold text-white mb-2">Division Management</h1>
          <p class="text-blue-200">{{ division?.name }} - {{ tournament?.name }}</p>
        </div>
        <div class="flex space-x-4">
          <button 
            @click="autoFillTeams" 
            class="btn btn-success"
            :disabled="!canAutoFill"
          >
            Auto Fill Teams
          </button>
          <button 
            @click="generateMatches" 
            class="btn btn-primary"
            :disabled="!canGenerateMatches"
          >
            Generate Matches
          </button>
          <RouterLink to="/admin/tournaments" class="btn btn-secondary">
            Back to Tournaments
          </RouterLink>
        </div>
      </div>

      <div v-if="loading" class="text-center text-white">Loading...</div>

      <div v-else-if="!division || !tournament" class="text-center text-white">
        Division not found
      </div>

      <div v-else class="space-y-8">
        <!-- Division Info -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <div class="grid md:grid-cols-3 gap-4">
            <div>
              <span class="text-blue-200">Division Type:</span>
              <div class="text-white font-semibold capitalize">
                {{ division.type === 'group' ? 'Group Phase' : 'Knockout Phase' }}
              </div>
            </div>
            <div>
              <span class="text-blue-200">Tournament Status:</span>
              <div class="capitalize">
                <span class="inline-block px-2 py-1 rounded text-xs font-semibold" 
                      :class="getStatusClass(tournament.status)">
                  {{ tournament.status }}
                </span>
              </div>
            </div>
            <div v-if="division.type === 'group'">
              <span class="text-blue-200">Groups:</span>
              <div class="text-white font-semibold">{{ groups.length }} groups</div>
            </div>
          </div>
        </div>

        <!-- Group Phase Management -->
        <div v-if="division.type === 'group'" class="space-y-6">
          <!-- Available Teams -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h3 class="text-xl font-bold text-white mb-4">Available Teams</h3>
            
            <div class="mb-4">
              <span class="text-blue-200">Total teams: {{ availableTeams.length }}</span>
              <span class="ml-4 text-green-200">Assigned: {{ assignedTeamsCount }}</span>
              <span class="ml-4 text-yellow-200">Unassigned: {{ availableTeams.length - assignedTeamsCount }}</span>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div 
                v-for="team in availableTeams" 
                :key="team.id"
                class="team-card"
                :class="{ 
                  'assigned': isTeamAssigned(team.id),
                  'dragging': draggedTeam?.id === team.id
                }"
                :draggable="tournament.status === 'setup' && !isTeamAssigned(team.id)"
                @dragstart="handleDragStart(team, $event)"
                @dragend="handleDragEnd"
              >
                <div class="font-semibold">{{ team.name }}</div>
                <div class="text-xs opacity-75">{{ team.players?.length || 0 }} players</div>
                <div v-if="isTeamAssigned(team.id)" class="text-xs text-green-300 mt-1">
                  Assigned to {{ getTeamGroup(team.id) }}
                </div>
                <div v-if="!isTeamAssigned(team.id) && tournament.status === 'setup'" class="text-xs text-blue-300 mt-1">
                  Click to select
                </div>
              </div>
            </div>
            
            <!-- Drag-and-Drop Instructions -->
            <div v-if="tournament.status === 'setup'" class="mt-4 p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
              <div class="text-blue-200 text-sm">
                �️ Drag teams from the list above to groups below, or drag teams within groups to reorder them
              </div>
            </div>
          </div>

          <!-- Groups -->
          <div class="grid md:grid-cols-2 gap-6">
            <div 
              v-for="group in groups" 
              :key="group.id"
              class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 group-container"
            >
              <div class="flex justify-between items-center mb-4">
                <h4 class="text-lg font-bold text-white">{{ group.name }}</h4>
                <span class="text-sm text-blue-200">
                  {{ getGroupTeams(group.id).length }} / {{ maxTeamsPerGroup }} teams
                </span>
              </div>

              <!-- Group Teams -->
              <div class="space-y-2">
                <div 
                  v-for="(participation, index) in getGroupTeams(group.id)" 
                  :key="participation.team_id"
                  class="team-in-group"
                  :class="{ 'dragging': draggedTeam?.id === participation.team_id }"
                  :draggable="tournament.status === 'setup'"
                  @dragstart="handleTeamDragStart(getTeamById(participation.team_id), participation, group.id, participation.position_in_group || index, $event)"
                  @dragend="handleDragEnd"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-3">
                      <div v-if="tournament.status === 'setup'" class="drag-handle">
                        <svg class="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M7 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
                        </svg>
                      </div>
                      <div>
                        <div class="font-semibold text-white">
                          {{ getTeamById(participation.team_id)?.name }}
                        </div>
                        <div class="text-xs text-blue-200">
                          Position {{ participation.position_in_group }}
                        </div>
                      </div>
                    </div>
                    <button 
                      v-if="tournament.status === 'setup'"
                      @click="removeTeamFromGroup(participation.id)"
                      class="text-red-400 hover:text-red-300 text-sm opacity-70 hover:opacity-100"
                      title="Remove team"
                    >
                      ✕
                    </button>
                  </div>
                </div>

                <!-- Drop Zone -->
                <div 
                  v-if="tournament.status === 'setup' && getGroupTeams(group.id).length < maxTeamsPerGroup"
                  class="drop-zone"
                  :class="{ 'active': dragOverGroup === group.id }"
                  @dragover.prevent="handleDragOver(group.id)"
                  @dragleave="handleDragLeave"
                  @drop="handleDrop(group.id, $event)"
                >
                  Drop teams here ({{ getGroupTeams(group.id).length }}/{{ maxTeamsPerGroup }})
                </div>

                <!-- Group Full Message -->
                <div 
                  v-else-if="getGroupTeams(group.id).length >= maxTeamsPerGroup"
                  class="text-center text-yellow-300 text-sm py-4"
                >
                  Group is full ({{ maxTeamsPerGroup }} teams)
                </div>
              </div>

              <!-- Group Standings (if matches have been played) -->
              <div v-if="groupStandings[group.id] && groupStandings[group.id]!.length > 0" class="mt-6 pt-4 border-t border-white/20">
                <h5 class="text-white font-semibold mb-3">Standings</h5>
                <div class="space-y-2">
                  <div 
                    v-for="standing in groupStandings[group.id]" 
                    :key="standing.team_id"
                    class="flex justify-between items-center text-sm"
                  >
                    <div class="flex items-center space-x-2">
                      <span class="text-yellow-300 font-bold">{{ standing.position }}.</span>
                      <span class="text-white">{{ standing.team_name }}</span>
                    </div>
                    <div class="flex space-x-4 text-xs">
                      <span class="text-blue-200">{{ standing.points }}pts</span>
                      <span class="text-green-200">{{ standing.wins }}W</span>
                      <span class="text-yellow-200">{{ standing.draws }}D</span>
                      <span class="text-red-200">{{ standing.losses }}L</span>
                      <span class="text-blue-200">{{ standing.goal_difference > 0 ? '+' : '' }}{{ standing.goal_difference }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Knockout Phase Management -->
        <div v-else-if="division.type === 'knockout'" class="space-y-6">
          <!-- Knockout Bracket (simplified for now) -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h3 class="text-xl font-bold text-white mb-4">Knockout Bracket</h3>
            
            <div class="text-center text-white/60 py-8">
              <div class="text-6xl mb-4">🚧</div>
              <p>Knockout bracket visualization coming soon</p>
              <p class="text-sm mt-2">For now, use the team list below to manage participants</p>
            </div>
          </div>

          <!-- Knockout Teams -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h3 class="text-xl font-bold text-white mb-4">Knockout Participants</h3>
            
            <!-- Seeded Teams List -->
            <div class="space-y-2 mb-4">
              <div 
                v-for="(participation, index) in knockoutParticipations" 
                :key="participation.team_id"
                class="team-in-group knockout-team"
                :class="{ 'dragging': draggedTeam?.id === participation.team_id }"
                :draggable="tournament.status === 'setup'"
                @dragstart="handleTeamDragStart(getTeamById(participation.team_id), participation, 'knockout', participation.position_in_group || index, $event)"
                @dragend="handleDragEnd"
              >
                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-3">
                    <div v-if="tournament.status === 'setup'" class="drag-handle">
                      <svg class="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M7 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
                      </svg>
                    </div>
                    <div>
                      <div class="font-semibold text-white">
                        {{ getTeamById(participation.team_id)?.name }}
                      </div>
                      <div class="text-xs text-blue-200">
                        Seed {{ participation.position_in_group }}
                      </div>
                    </div>
                  </div>
                  <button 
                    v-if="tournament.status === 'setup'"
                    @click="removeTeamFromKnockout(participation.id)"
                    class="text-red-400 hover:text-red-300 text-sm opacity-70 hover:opacity-100"
                    title="Remove team"
                  >
                    ✕
                  </button>
                </div>
              </div>

              <!-- Drop Zone -->
              <div 
                v-if="tournament.status === 'setup'"
                class="drop-zone"
                :class="{ 'active': dragOverGroup === 'knockout' }"
                @dragover.prevent="handleDragOver('knockout')"
                @dragleave="handleDragLeave"
                @drop="handleDrop('knockout', $event)"
              >
                Drop teams here for knockout bracket
              </div>
            </div>

            <!-- Add Teams Button -->
            <button 
              v-if="tournament.status === 'setup'"
              @click="showAddTeamsModal = true"
              class="btn btn-primary"
            >
              Add Teams to Knockout
            </button>
          </div>
        </div>

        <!-- Match Generation Status -->
        <div v-if="matches.length > 0" class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <h3 class="text-xl font-bold text-white mb-4">Generated Matches</h3>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div 
              v-for="match in matches" 
              :key="match.id"
              class="bg-white/5 rounded-lg p-4 border border-white/10"
            >
              <div class="flex justify-between items-center mb-2">
                <span class="text-xs text-blue-200">
                  {{ division.type === 'group' ? `Group ${getMatchGroup(match)}` : `Round ${match.round_number}` }}
                </span>
                <div class="flex items-center space-x-2">
                  <span class="text-xs px-2 py-1 rounded" 
                        :class="getMatchStatusClass(match.status)">
                    {{ match.status }}
                  </span>
                  <button 
                    v-if="tournament?.status === 'setup'"
                    @click="deleteMatch(match.id)" 
                    class="btn btn-xs bg-red-600 hover:bg-red-700 text-white"
                    title="Delete Match"
                  >
                    🗑️
                  </button>
                </div>
              </div>
              
              <!-- Match Start Time -->
              <div class="text-center mb-2">
                <div class="text-xs text-blue-200">Start Time</div>
                <div class="text-white font-mono text-sm">
                  {{ formatMatchStartTime(match) }}
                </div>
              </div>
              
              <div class="text-white font-semibold text-center">
                {{ getTeamById(match.team_a)?.name }} vs {{ getTeamById(match.team_b)?.name }}
              </div>
              <div v-if="match.status === 'finished'" class="text-center text-sm text-blue-200 mt-2">
                {{ match.score_a }} - {{ match.score_b }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Teams to Knockout Modal -->
    <div v-if="showAddTeamsModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">Add Teams to Knockout</h3>
        
        <div class="space-y-3 mb-4 max-h-64 overflow-y-auto">
          <div 
            v-for="team in unassignedTeams" 
            :key="team.id"
            class="flex items-center space-x-3"
          >
            <input 
              type="checkbox" 
              :id="`team-${team.id}`"
              :value="team.id"
              v-model="selectedTeamsForKnockout"
              class="rounded border-white/20"
            />
            <label :for="`team-${team.id}`" class="text-white flex-1">
              {{ team.name }}
            </label>
          </div>
        </div>

        <div class="flex space-x-3">
          <button 
            @click="addTeamsToKnockout"
            class="flex-1 btn btn-primary"
            :disabled="selectedTeamsForKnockout.length === 0"
          >
            Add Selected Teams
          </button>
          <button 
            @click="showAddTeamsModal = false; selectedTeamsForKnockout = []"
            class="flex-1 btn btn-secondary"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { supabase } from '@/lib/supabase'

interface Tournament {
  id: string
  name: string
  start_date: string
  end_date?: string
  description?: string
  status: 'setup' | 'active' | 'finished'
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
  tournament_start_time?: string
  match_gap_minutes?: number
}

interface Division {
  id: string
  tournament_id: string
  name: string
  type: 'group' | 'knockout'
  order_index: number
  settings: any
}

interface Group {
  id: string
  division_id: string
  name: string
  order_index: number
}

interface Team {
  id: string
  name: string
  players: any[]
}

interface TeamParticipation {
  id: string
  tournament_id: string
  team_id: string
  group_id?: string
  position_in_group?: number
}

interface Match {
  id: string
  tournament_id?: string
  division_id?: string
  group_id?: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  status: string
  match_type?: string
  round_number?: number
  match_order?: number
  start_time?: string
}

interface Standings {
  team_id: string
  team_name: string
  position: number
  points: number
  wins: number
  draws: number
  losses: number
  goals_for: number
  goals_against: number
  goal_difference: number
}

const route = useRoute()

// Data
const tournament = ref<Tournament | null>(null)
const division = ref<Division | null>(null)
const groups = ref<Group[]>([])
const availableTeams = ref<Team[]>([])
const teamParticipations = ref<TeamParticipation[]>([])
const matches = ref<Match[]>([])
const groupStandings = ref<Record<string, Standings[]>>({})
const loading = ref(true)

// Drag and drop


// Modals
const showAddTeamsModal = ref(false)
const selectedTeamsForKnockout = ref<string[]>([])

// Drag and drop state
const draggedTeam = ref<Team | null>(null)
const dragOverGroup = ref<string | null>(null)

// Computed
const assignedTeamsCount = computed(() => teamParticipations.value.length)

const maxTeamsPerGroup = computed(() => {
  return division.value?.settings?.teams_per_group || 4
})

const knockoutParticipations = computed(() => {
  return teamParticipations.value.filter(p => !p.group_id)
})

const unassignedTeams = computed(() => {
  const assignedTeamIds = teamParticipations.value.map(p => p.team_id)
  return availableTeams.value.filter(team => !assignedTeamIds.includes(team.id))
})

const canAutoFill = computed(() => {
  return tournament.value?.status === 'setup' && 
         division.value?.type === 'group' && 
         unassignedTeams.value.length > 0
})

const canGenerateMatches = computed(() => {
  if (division.value?.type === 'group') {
    // All groups should have at least 2 teams
    return groups.value.every(group => getGroupTeams(group.id).length >= 2)
  } else {
    // Knockout should have at least 2 teams
    return knockoutParticipations.value.length >= 2
  }
})

const getGroupSlotsWithTeams = computed(() => {
  return (groupId: string) => {
    const groupTeams = getGroupTeams(groupId)
    const maxSlots = Math.max(maxTeamsPerGroup.value, groupTeams.length)
    const slots: Array<{ 
      team?: Team; 
      participation?: TeamParticipation; 
      isPlaceholder?: boolean 
    }> = []

    // Fill slots with actual teams
    for (let i = 0; i < maxSlots; i++) {
      const participation = groupTeams[i]
      if (participation) {
        const team = getTeamById(participation.team_id)
        if (team) {
          slots.push({ team, participation })
        }
      } else {
        slots.push({ isPlaceholder: true })
      }
    }

    return slots
  }
})

const getKnockoutSlotsWithTeams = computed(() => {
  const knockoutTeams = knockoutParticipations.value.sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  const maxSlots = Math.max(8, knockoutTeams.length) // Minimum 8 slots for knockout
  const slots: Array<{ 
    team?: Team; 
    participation?: TeamParticipation; 
    isPlaceholder?: boolean 
  }> = []

  // Fill slots with actual teams
  for (let i = 0; i < maxSlots; i++) {
    const participation = knockoutTeams[i]
    if (participation) {
      const team = getTeamById(participation.team_id)
      if (team) {
        slots.push({ team, participation })
      }
    } else {
      slots.push({ isPlaceholder: true })
    }
  }

  return slots
})

// Drag and drop functions
function handleDragStart(team: Team | undefined, event: DragEvent) {
  if (!team || !event.dataTransfer) return
  
  draggedTeam.value = team
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('text/plain', team.id)
}

function handleDragEnd() {
  draggedTeam.value = null
  dragOverGroup.value = null
}

function handleDragOver(groupId: string) {
  if (draggedTeam.value && getGroupTeams(groupId).length < maxTeamsPerGroup.value) {
    dragOverGroup.value = groupId
  }
}

function handleDragLeave() {
  dragOverGroup.value = null
}

async function handleDrop(groupId: string, event: DragEvent) {
  dragOverGroup.value = null
  
  if (!draggedTeam.value || !tournament.value) return
  
  const team = draggedTeam.value
  
  try {
    // Check if team is being moved from another group or being assigned for the first time
    const existingParticipation = teamParticipations.value.find(tp => 
      tp.team_id === team.id && tp.division_id === division.value?.id
    )
    
    if (existingParticipation) {
      // Team is being moved from another group
      const newPosition = getGroupTeams(groupId).length + 1
      await moveTeamToGroup(existingParticipation.id, groupId, newPosition)
    } else {
      // Team is being assigned for the first time
      const newPosition = getGroupTeams(groupId).length + 1
      await assignTeamToGroupAtPosition(team.id, groupId, newPosition)
    }
    
    // Reload data to update UI
    await loadData()
  } catch (error) {
    console.error('Error in drag and drop:', error)
    alert('Failed to move team')
  }
  
  draggedTeam.value = null
}

// Utility functions
function formatMatchStartTime(match: Match): string {
  if (match.start_time) {
    // If match has explicit start time, use it
    return match.start_time.substring(0, 5) // HH:MM format
  }
  
  if (!tournament.value || !division.value) return 'TBD'
  
  // Calculate start time based on tournament settings and match order
  const matchIndex = matches.value.findIndex(m => m.id === match.id)
  if (matchIndex === -1) return 'TBD'
  
  const tournamentStartTime = tournament.value.tournament_start_time || '09:00:00'
  const matchDuration = calculateMatchDuration()
  const gapMinutes = tournament.value.match_gap_minutes || 15
  const totalSlotMinutes = matchDuration + gapMinutes
  
  // Parse start time
  const timeParts = tournamentStartTime.substring(0, 5).split(':').map(Number)
  const hours = timeParts[0] || 9
  const minutes = timeParts[1] || 0
  let currentTime = hours * 60 + minutes + (matchIndex * totalSlotMinutes)
  
  const matchHours = Math.floor(currentTime / 60)
  const matchMinutes = currentTime % 60
  return `${matchHours.toString().padStart(2, '0')}:${matchMinutes.toString().padStart(2, '0')}`
}

function calculateMatchDuration(): number {
  if (!tournament.value) return 75 // default
  
  const quarters = tournament.value.quarters_count || 4
  const quarterDuration = tournament.value.quarter_duration_minutes || 15
  const breakDuration = tournament.value.break_duration_minutes || 2
  const halftimeDuration = tournament.value.halftime_duration_minutes || 10
  
  const totalPlayingTime = quarters * quarterDuration
  const numberOfBreaks = quarters - 1
  const regularBreaks = numberOfBreaks > 1 ? numberOfBreaks - 1 : 0
  const totalBreakTime = regularBreaks * breakDuration + (numberOfBreaks > 0 ? halftimeDuration : 0)
  
  return totalPlayingTime + totalBreakTime
}

// Methods
async function loadData() {
  try {
    const divisionId = route.params.divisionId as string
    
    // Load division and tournament
    const { data: divisionData, error: divisionError } = await supabase
      .from('tournament_divisions')
      .select(`
        *,
        tournament:tournaments(*)
      `)
      .eq('id', divisionId)
      .single()

    if (divisionError) {
      console.error('Error loading division:', divisionError)
      return
    }

    division.value = divisionData
    tournament.value = divisionData.tournament

    // Load groups if it's a group division
    if (division.value && division.value.type === 'group') {
      const { data: groupsData, error: groupsError } = await supabase
        .from('tournament_groups')
        .select('*')
        .eq('division_id', divisionId)
        .order('order_index')

      if (!groupsError) {
        groups.value = groupsData || []
      }
    }

    // Load available teams
    const { data: teamsData, error: teamsError } = await supabase
      .from('teams')
      .select('*')
      .order('name')

    if (!teamsError) {
      availableTeams.value = teamsData || []
    }

    // Load team participations for this tournament
    const { data: participationsData, error: participationsError } = await supabase
      .from('tournament_team_participations')
      .select('*')
      .eq('tournament_id', tournament.value!.id)

    if (!participationsError) {
      teamParticipations.value = participationsData || []
    }

    // Load matches for this division
    const { data: matchesData, error: matchesError } = await supabase
      .from('matches')
      .select('*')
      .eq('division_id', divisionId)
      .order('match_order')

    if (!matchesError) {
      matches.value = matchesData || []
    }

    // Load standings for group divisions
    if (division.value?.type === 'group') {
      await loadGroupStandings()
    }
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

async function loadGroupStandings() {
  try {
    const { data: standingsData, error } = await supabase
      .from('tournament_group_standings')
      .select('*')
      .eq('tournament_id', tournament.value!.id)
      .order('group_id')
      .order('position')

    if (!error && standingsData) {
      const standingsByGroup: Record<string, Standings[]> = {}
      standingsData.forEach(standing => {
        if (!standingsByGroup[standing.group_id]) {
          standingsByGroup[standing.group_id] = []
        }
        standingsByGroup[standing.group_id]!.push(standing)
      })
      groupStandings.value = standingsByGroup
    }
  } catch (error) {
    console.error('Error loading standings:', error)
  }
}

function getGroupTeams(groupId: string): TeamParticipation[] {
  return teamParticipations.value
    .filter(p => p.group_id === groupId)
    .sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
}

function getTeamById(teamId: string): Team | undefined {
  return availableTeams.value.find(team => team.id === teamId)
}

function isTeamAssigned(teamId: string): boolean {
  return teamParticipations.value.some(p => p.team_id === teamId)
}

function getTeamGroup(teamId: string): string {
  const participation = teamParticipations.value.find(p => p.team_id === teamId)
  if (participation?.group_id) {
    const group = groups.value.find(g => g.id === participation.group_id)
    return group?.name || 'Unknown Group'
  }
  return 'Knockout'
}

function handleTeamDragStart(team: Team | undefined, participation: TeamParticipation | undefined, groupId: string, position: number, event: DragEvent) {
  if (!team || !event.dataTransfer) return
  
  draggedTeam.value = team
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('text/plain', team.id)
}

async function removeTeamFromGroup(participationId: string) {
  try {
    const { error } = await supabase
      .from('tournament_team_participations')
      .delete()
      .eq('id', participationId)

    if (!error) {
      teamParticipations.value = teamParticipations.value.filter(p => p.id !== participationId)
      await loadData()
    }
  } catch (error) {
    console.error('Error removing team from group:', error)
  }
}

async function removeTeamFromKnockout(participationId: string) {
  await removeTeamFromGroup(participationId)
}

async function deleteMatch(matchId: string) {
  if (!confirm('Are you sure you want to delete this match? This action cannot be undone.')) {
    return
  }

  try {
    const { error } = await supabase
      .from('matches')
      .delete()
      .eq('id', matchId)

    if (error) {
      console.error('Error deleting match:', error)
      alert('Failed to delete match')
      return
    }

    // Remove from local array
    matches.value = matches.value.filter(m => m.id !== matchId)
    
    alert('Match deleted successfully')
  } catch (error) {
    console.error('Error deleting match:', error)
    alert('Failed to delete match')
  }
}

function getTournamentStatusClass(status: string): string {
  switch (status) {
    case 'setup': return 'bg-yellow-500/20 text-yellow-300'
    case 'active': return 'bg-green-500/20 text-green-300' 
    case 'finished': return 'bg-blue-500/20 text-blue-300'
    default: return 'bg-gray-500/20 text-gray-300'
  }
}

function getMatchStatusClass(status: string): string {
  switch (status) {
    case 'pending': return 'bg-gray-500/20 text-gray-300'
    case 'active': return 'bg-green-500/20 text-green-300'
    case 'paused': return 'bg-yellow-500/20 text-yellow-300'
    case 'finished': return 'bg-blue-500/20 text-blue-300'
    default: return 'bg-gray-500/20 text-gray-300'
  }
}

onMounted(() => {
  loadData()
})
</script>
  draggedTeam.value = null
  dragOverGroup.value = null
  dragOverPosition.value = null
  draggedFromGroup.value = null
  draggedFromPosition.value = null
}

function handleDragOver(groupId: string) {
  if (draggedTeam.value && getGroupTeams(groupId).length < maxTeamsPerGroup.value) {
    dragOverGroup.value = groupId
  }
}

function handleDragLeave() {
  dragOverGroup.value = null
}

async function handleDrop(groupId: string, event: DragEvent) {
  event.preventDefault()
  dragOverGroup.value = null

  if (!draggedTeam.value || !tournament.value) return

  const team = draggedTeam.value
  const groupTeams = getGroupTeams(groupId)
  
  if (groupTeams.length >= maxTeamsPerGroup.value) {
    alert(`Group is full (max ${maxTeamsPerGroup.value} teams)`)
    return
  }

  try {
    // Check if team is already assigned to this tournament
    const existingParticipation = teamParticipations.value.find(p => p.team_id === team.id)
    
    if (existingParticipation) {
      // Update existing participation
      const { error } = await supabase
        .from('tournament_team_participations')
        .update({
          group_id: groupId,
          position_in_group: groupTeams.length + 1
        })
        .eq('id', existingParticipation.id)

      if (!error) {
        existingParticipation.group_id = groupId
        existingParticipation.position_in_group = groupTeams.length + 1
      }
    } else {
      // Create new participation
      const { data, error } = await supabase
        .from('tournament_team_participations')
        .insert([{
          tournament_id: tournament.value.id,
          team_id: team.id,
          group_id: groupId,
          position_in_group: groupTeams.length + 1
        }])
        .select()
        .single()

      if (!error && data) {
        teamParticipations.value.push(data)
      }
    }
  } catch (error) {
    console.error('Error assigning team to group:', error)
  }

  draggedTeam.value = null
}

// Enhanced drag and drop handlers for position-based reordering
function handleTeamDragStart(team: Team | undefined, participation: TeamParticipation | undefined, groupId: string, position: number, event: DragEvent) {
  if (!team || !participation || tournament.value?.status !== 'setup') return
  
  draggedTeam.value = team
  draggedFromGroup.value = groupId
  draggedFromPosition.value = position
  
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', team.id)
  }
}

function handleUnassignedTeamDragStart(team: Team | undefined, event: DragEvent) {
  if (!team || tournament.value?.status !== 'setup') return
  
  draggedTeam.value = team
  draggedFromGroup.value = null // No source group for unassigned teams
  draggedFromPosition.value = null // No source position for unassigned teams
  
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', team.id)
  }
}

function handleDragOverPosition(groupId: string, position: number, event: DragEvent) {
  if (!draggedTeam.value) return
  
  let canDrop = false
  
  if (groupId === 'knockout') {
    // For knockout, allow dropping anywhere
    canDrop = true
  } else {
    const groupTeams = getGroupTeams(groupId)
    canDrop = groupTeams.length < maxTeamsPerGroup.value || 
              (draggedFromGroup.value === groupId && position <= groupTeams.length)
  }
  
  if (canDrop) {
    dragOverPosition.value = { groupId, position }
    event.preventDefault()
  }
}

function handleDragLeavePosition() {
  dragOverPosition.value = null
}

async function handleDropAtPosition(groupId: string, position: number, event: DragEvent) {
  event.preventDefault()
  dragOverPosition.value = null
  
  if (!draggedTeam.value || !tournament.value) return

  const team = draggedTeam.value
  const fromGroup = draggedFromGroup.value
  const fromPosition = draggedFromPosition.value
  
  // Clear drag state
  draggedTeam.value = null
  draggedFromGroup.value = null
  draggedFromPosition.value = null

  try {
    const existingParticipation = teamParticipations.value.find(p => p.team_id === team.id)
    
    if (fromGroup === groupId && fromPosition !== null) {
      // Reordering within same group/knockout
      if (groupId === 'knockout') {
        await reorderTeamInKnockout(fromPosition, position)
      } else {
        await reorderTeamInGroup(groupId, fromPosition, position)
      }
    } else if (existingParticipation) {
      // Moving between groups or from unassigned
      if (groupId === 'knockout') {
        await moveTeamToKnockout(existingParticipation.id, position)
      } else {
        await moveTeamToGroup(existingParticipation.id, groupId, position)
      }
    } else {
      // New team assignment
      if (groupId === 'knockout') {
        await assignTeamToKnockoutAtPosition(team.id, position)
      } else {
        await assignTeamToGroupAtPosition(team.id, groupId, position)
      }
    }
  } catch (error) {
    console.error('Error handling drop at position:', error)
  }
}

async function reorderTeamInGroup(groupId: string, fromPos: number, toPos: number) {
  if (fromPos === toPos) return
  
  const groupTeams = getGroupTeams(groupId).sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Update positions sequentially to avoid conflicts
  if (fromPos < toPos) {
    // Moving down - shift teams up
    for (let i = fromPos + 1; i <= toPos; i++) {
      const participation = groupTeams[i]
      if (participation) {
        await supabase
          .from('tournament_team_participations')
          .update({ position_in_group: i })
          .eq('id', participation.id)
        participation.position_in_group = i
      }
    }
  } else {
    // Moving up - shift teams down
    for (let i = toPos; i < fromPos; i++) {
      const participation = groupTeams[i]
      if (participation) {
        await supabase
          .from('tournament_team_participations')
          .update({ position_in_group: i + 2 })
          .eq('id', participation.id)
        participation.position_in_group = i + 2
      }
    }
  }
  
  // Update the moved team
  const movedParticipation = groupTeams[fromPos]
  if (movedParticipation) {
    await supabase
      .from('tournament_team_participations')
      .update({ position_in_group: toPos + 1 })
      .eq('id', movedParticipation.id)
    movedParticipation.position_in_group = toPos + 1
  }
}

async function moveTeamToGroup(participationId: string, groupId: string, position: number) {
  const groupTeams = getGroupTeams(groupId).sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Shift existing teams down to make room
  for (let i = position; i < groupTeams.length; i++) {
    const participation = groupTeams[i]
    if (participation) {
      await supabase
        .from('tournament_team_participations')
        .update({ position_in_group: i + 2 })
        .eq('id', participation.id)
      participation.position_in_group = i + 2
    }
  }
  
  // Update the moved team
  await supabase
    .from('tournament_team_participations')
    .update({ 
      group_id: groupId,
      position_in_group: position + 1 
    })
    .eq('id', participationId)
  
  // Update local state
  const participation = teamParticipations.value.find(p => p.id === participationId)
  if (participation) {
    participation.group_id = groupId
    participation.position_in_group = position + 1
  }
}

async function assignTeamToGroupAtPosition(teamId: string, groupId: string, position: number) {
  const groupTeams = getGroupTeams(groupId).sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Shift existing teams down
  for (let i = position; i < groupTeams.length; i++) {
    const participation = groupTeams[i]
    if (participation) {
      await supabase
        .from('tournament_team_participations')
        .update({ position_in_group: i + 2 })
        .eq('id', participation.id)
      participation.position_in_group = i + 2
    }
  }
  
  // Create new participation
  const { data, error } = await supabase
    .from('tournament_team_participations')
    .insert([{
      tournament_id: tournament.value!.id,
      team_id: teamId,
      group_id: groupId,
      position_in_group: position + 1
    }])
    .select()
    .single()

  if (!error && data) {
    teamParticipations.value.push(data)
  }
}

// Knockout-specific drag and drop functions
async function reorderTeamInKnockout(fromPos: number, toPos: number) {
  if (fromPos === toPos) return
  
  const knockoutTeams = knockoutParticipations.value.sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Update positions sequentially to avoid conflicts
  if (fromPos < toPos) {
    // Moving down - shift teams up
    for (let i = fromPos + 1; i <= toPos; i++) {
      const participation = knockoutTeams[i]
      if (participation) {
        await supabase
          .from('tournament_team_participations')
          .update({ position_in_group: i })
          .eq('id', participation.id)
        participation.position_in_group = i
      }
    }
  } else {
    // Moving up - shift teams down
    for (let i = toPos; i < fromPos; i++) {
      const participation = knockoutTeams[i]
      if (participation) {
        await supabase
          .from('tournament_team_participations')
          .update({ position_in_group: i + 2 })
          .eq('id', participation.id)
        participation.position_in_group = i + 2
      }
    }
  }
  
  // Update the moved team
  const movedParticipation = knockoutTeams[fromPos]
  if (movedParticipation) {
    await supabase
      .from('tournament_team_participations')
      .update({ position_in_group: toPos + 1 })
      .eq('id', movedParticipation.id)
    movedParticipation.position_in_group = toPos + 1
  }
}

async function moveTeamToKnockout(participationId: string, position: number) {
  const knockoutTeams = knockoutParticipations.value.sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Shift existing teams down to make room
  for (let i = position; i < knockoutTeams.length; i++) {
    const participation = knockoutTeams[i]
    if (participation) {
      await supabase
        .from('tournament_team_participations')
        .update({ position_in_group: i + 2 })
        .eq('id', participation.id)
      participation.position_in_group = i + 2
    }
  }
  
  // Update the moved team (remove from group, add to knockout)
  await supabase
    .from('tournament_team_participations')
    .update({ 
      group_id: null,
      position_in_group: position + 1 
    })
    .eq('id', participationId)
  
  // Update local state
  const participation = teamParticipations.value.find(p => p.id === participationId)
  if (participation) {
    participation.group_id = undefined
    participation.position_in_group = position + 1
  }
}

async function assignTeamToKnockoutAtPosition(teamId: string, position: number) {
  const knockoutTeams = knockoutParticipations.value.sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
  
  // Shift existing teams down
  for (let i = position; i < knockoutTeams.length; i++) {
    const participation = knockoutTeams[i]
    if (participation) {
      await supabase
        .from('tournament_team_participations')
        .update({ position_in_group: i + 2 })
        .eq('id', participation.id)
      participation.position_in_group = i + 2
    }
  }
  
  // Create new participation
  const { data, error } = await supabase
    .from('tournament_team_participations')
    .insert([{
      tournament_id: tournament.value!.id,
      team_id: teamId,
      group_id: null, // null for knockout
      position_in_group: position + 1
    }])
    .select()
    .single()

  if (!error && data) {
    teamParticipations.value.push(data)
  }
}

async function removeTeamFromGroup(participationId: string) {
  try {
    const { error } = await supabase
      .from('tournament_team_participations')
      .delete()
      .eq('id', participationId)

    if (!error) {
      teamParticipations.value = teamParticipations.value.filter(p => p.id !== participationId)
    }
  } catch (error) {
    console.error('Error removing team from group:', error)
  }
}

async function removeTeamFromKnockout(participationId: string) {
  await removeTeamFromGroup(participationId)
}

async function deleteMatch(matchId: string) {
  if (!confirm('Are you sure you want to delete this match? This action cannot be undone.')) {
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

    // Remove match from local state
    matches.value = matches.value.filter(m => m.id !== matchId)
    console.log('✅ Match deleted successfully')
  } catch (error) {
    console.error('Error:', error)
    alert('Failed to delete match. Please try again.')
  }
}

async function addTeamsToKnockout() {
  if (!tournament.value || selectedTeamsForKnockout.value.length === 0) return

  try {
    const participations = selectedTeamsForKnockout.value.map((teamId, index) => ({
      tournament_id: tournament.value!.id,
      team_id: teamId,
      position_in_group: knockoutParticipations.value.length + index + 1
    }))

    const { data, error } = await supabase
      .from('tournament_team_participations')
      .insert(participations)
      .select()

    if (!error && data) {
      teamParticipations.value.push(...data)
      showAddTeamsModal.value = false
      selectedTeamsForKnockout.value = []
    }
  } catch (error) {
    console.error('Error adding teams to knockout:', error)
  }
}

async function autoFillTeams() {
  if (!canAutoFill.value || !tournament.value) return

  try {
    const teamsToAssign = [...unassignedTeams.value]
    const participations: any[] = []

    // Distribute teams evenly across groups
    let currentGroupIndex = 0
    let currentPositionInGroup: Record<string, number> = {}
    
    // Initialize positions
    groups.value.forEach(group => {
      currentPositionInGroup[group.id] = getGroupTeams(group.id).length + 1
    })

    teamsToAssign.forEach(team => {
      const group = groups.value[currentGroupIndex]
      if (group && currentPositionInGroup[group.id] && currentPositionInGroup[group.id]! <= maxTeamsPerGroup.value) {
        participations.push({
          tournament_id: tournament.value!.id,
          team_id: team.id,
          group_id: group.id,
          position_in_group: currentPositionInGroup[group.id]
        })
        
        currentPositionInGroup[group.id] = (currentPositionInGroup[group.id] || 0) + 1
        currentGroupIndex = (currentGroupIndex + 1) % groups.value.length
      }
    })

    if (participations.length > 0) {
      const { data, error } = await supabase
        .from('tournament_team_participations')
        .insert(participations)
        .select()

      if (!error && data) {
        teamParticipations.value.push(...data)
      }
    }
  } catch (error) {
    console.error('Error auto-filling teams:', error)
  }
}

async function generateMatches() {
  if (!canGenerateMatches.value || !division.value || !tournament.value) return

  try {
    if (division.value.type === 'group') {
      // Generate matches for each group
      for (const group of groups.value) {
        const { error } = await supabase.rpc('generate_group_matches', {
          group_uuid: group.id
        })
        
        if (error) {
          console.error(`Error generating matches for ${group.name}:`, error)
        }
      }
    } else {
      // Generate knockout matches
      const teamIds = knockoutParticipations.value.map(p => p.team_id)
      const { error } = await supabase.rpc('generate_knockout_matches', {
        division_uuid: division.value.id,
        team_ids: teamIds
      })
      
      if (error) {
        console.error('Error generating knockout matches:', error)
      }
    }

    // Reload matches
    const { data: matchesData } = await supabase
      .from('matches')
      .select('*')
      .eq('division_id', division.value.id)
      .order('match_order')

    if (matchesData) {
      matches.value = matchesData
    }
  } catch (error) {
    console.error('Error generating matches:', error)
  }
}

function getMatchGroup(match: Match): string {
  if (match.group_id) {
    const group = groups.value.find(g => g.id === match.group_id)
    return group?.name.replace('Group ', '') || '?'
  }
  return '?'
}

function getStatusClass(status: string): string {
  switch (status) {
    case 'setup': return 'bg-yellow-500/20 text-yellow-300'
    case 'active': return 'bg-green-500/20 text-green-300'
    case 'finished': return 'bg-blue-500/20 text-blue-300'
    default: return 'bg-gray-500/20 text-gray-300'
  }
}

function getMatchStatusClass(status: string): string {
  switch (status) {
    case 'pending': return 'bg-gray-500/20 text-gray-300'
    case 'active': return 'bg-green-500/20 text-green-300'
    case 'paused': return 'bg-yellow-500/20 text-yellow-300'
    case 'finished': return 'bg-blue-500/20 text-blue-300'
    default: return 'bg-gray-500/20 text-gray-300'
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.team-card {
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 0.5rem;
  padding: 0.75rem;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  text-align: center;
  transition: all 0.2s;
}

.team-card.draggable {
  cursor: move;
}

.team-card.draggable:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.team-card.assigned {
  border-color: rgba(74, 222, 128, 0.5);
  background-color: rgba(74, 222, 128, 0.1);
}

.team-card.dragging {
  opacity: 0.7;
  transform: scale(1.05);
  z-index: 1000;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
}

.team-in-group {
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 0.5rem;
  padding: 0.75rem;
  border: 1px solid rgba(255, 255, 255, 0.1);
  cursor: move;
  transition: all 0.3s ease;
}

.team-in-group:hover {
  background-color: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.2);
}

.team-in-group.dragging {
  opacity: 0.5;
  transform: rotate(2deg);
}

.team-in-group.drag-placeholder {
  opacity: 0.3;
  border-style: dashed;
}

.group-container {
  transition: all 0.2s;
}

.group-container.drag-over {
  border-color: rgb(250, 204, 21);
  background-color: rgba(250, 204, 21, 0.1);
}

.drop-zone {
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 0.5rem;
  padding: 1rem;
  text-align: center;
  color: rgba(255, 255, 255, 0.5);
  transition: all 0.2s;
}

.drop-zone.active {
  border-color: rgb(250, 204, 21);
  color: rgb(253, 224, 71);
  background-color: rgba(250, 204, 21, 0.1);
}

.drop-zone-between {
  height: 4px;
  margin: 2px 0;
  border-radius: 2px;
  transition: all 0.3s ease;
  opacity: 0;
}

.drop-zone-between.visible {
  opacity: 0.5;
  height: 6px;
  background: linear-gradient(90deg, 
    transparent 0%, 
    rgba(255, 255, 255, 0.4) 50%, 
    transparent 100%
  );
}

.final-drop-zone.visible {
  opacity: 0.7;
  height: 8px;
  background: linear-gradient(90deg, 
    transparent 0%, 
    rgba(34, 197, 94, 0.5) 10%, 
    rgba(34, 197, 94, 0.5) 90%, 
    transparent 100%
  );
}

.drop-zone-between.active {
  opacity: 1;
  height: 8px;
  background: linear-gradient(90deg, 
    transparent 0%, 
    rgb(250, 204, 21) 10%, 
    rgb(250, 204, 21) 90%, 
    transparent 100%
  );
  box-shadow: 0 0 10px rgba(250, 204, 21, 0.5);
}

.drop-zone-between .drop-indicator {
  text-align: center;
  font-size: 0.75rem;
  color: rgb(253, 224, 71);
  padding: 4px;
  background: rgba(0, 0, 0, 0.7);
  border-radius: 4px;
  margin-top: 2px;
}

.group-slot {
  position: relative;
}

.drag-handle {
  cursor: grab;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.5;
  transition: opacity 0.2s;
}

.drag-handle:hover {
  opacity: 1;
}

.drag-handle:active {
  cursor: grabbing;
}

.knockout-slot {
  position: relative;
}

.knockout-team {
  border-left: 4px solid rgba(251, 191, 36, 0.6);
}

.knockout-team:hover {
  border-left-color: rgb(251, 191, 36);
}

.btn {
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-weight: 600;
  transition: all 0.2s;
  outline: none;
  border: 1px solid transparent;
}

.btn-primary {
  background-color: rgb(37, 99, 235);
  color: white;
}

.btn-primary:hover {
  background-color: rgb(29, 78, 216);
}

.btn-secondary {
  background-color: rgba(255, 255, 255, 0.1);
  color: white;
  border-color: rgba(255, 255, 255, 0.2);
}

.btn-secondary:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

.btn-success {
  background-color: rgb(22, 163, 74);
  color: white;
}

.btn-success:hover {
  background-color: rgb(21, 128, 61);
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>