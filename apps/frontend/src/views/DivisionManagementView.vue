<template>
  <div class="p-6 min-h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-indigo-900">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-3xl font-bold text-white mb-2">Division Management</h1>
          <div class="flex items-center space-x-4 text-sm">
            <span class="text-blue-200">Tournament: {{ tournament?.name }}</span>
            <span class="text-purple-200">Division: {{ division?.name }}</span>
            <div class="px-2 py-1 rounded text-xs font-semibold"
                 :class="getTournamentStatusClass(tournament?.status || 'setup')">
              {{ tournament?.status?.toUpperCase() }}
            </div>
          </div>
        </div>
        <div class="flex space-x-3">
          <button 
            v-if="tournament?.status === 'setup'"
            @click="autoFillTeams"
            class="btn btn-secondary"
          >
            🎲 Auto Fill Teams
          </button>
          <button 
            v-if="canGenerateMatches"
            @click="generateMatches"
            class="btn btn-success"
          >
            ⚡ Generate Matches
          </button>
          <router-link 
            :to="{ name: 'tournaments-admin' }" 
            class="btn btn-outline"
          >
            ← Back to Tournaments
          </router-link>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-12">
        <div class="text-white">Loading division data...</div>
      </div>

      <!-- Main Content -->
      <div v-else class="space-y-8">
        <!-- Team Pool -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <h2 class="text-xl font-bold text-white mb-4">Team Pool</h2>
          
          <div class="mb-4 flex items-center space-x-4 text-sm">
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
              :draggable="tournament?.status === 'setup'"
              @dragstart="handleDragStart(team, $event)"
              @dragend="handleDragEnd"
            >
              <div class="font-semibold">{{ team.name }}</div>
              <div class="text-xs opacity-75">{{ team.players?.length || 0 }} players</div>
              <div v-if="isTeamAssigned(team.id)" class="text-xs text-green-300 mt-1">
                Assigned to {{ getTeamGroup(team.id) }}
              </div>
            </div>
          </div>
          
          <!-- Drag-and-Drop Instructions -->
          <div v-if="tournament?.status === 'setup'" class="mt-4 p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
            <div class="text-blue-200 text-sm">
              🖱️ Drag teams from the list above to groups below, or drag teams within groups to reorder them
            </div>
          </div>
        </div>

        <!-- Group Phase Management -->
        <div v-if="division?.type === 'group'" class="space-y-6">
          <!-- Groups -->
          <div class="grid md:grid-cols-2 gap-6">
            <div 
              v-for="group in groups" 
              :key="group.id"
              class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20"
            >
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-semibold text-white">{{ group.name }}</h3>
                <span class="text-xs text-blue-200">
                  {{ getGroupTeams(group.id).length }}/{{ maxTeamsPerGroup }} teams
                </span>
              </div>

              <!-- Group Teams -->
              <div class="space-y-2">
                <div 
                  v-for="(participation, index) in getGroupTeams(group.id)" 
                  :key="participation.team_id"
                  class="team-in-group"
                  :class="{ 'dragging': draggedTeam?.id === participation.team_id }"
                  :draggable="tournament?.status === 'setup'"
                  @dragstart="handleTeamDragStart(getTeamById(participation.team_id), participation, group.id, participation.position_in_group || index, $event)"
                  @dragend="handleDragEnd"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex items-center space-x-3">
                      <div v-if="tournament?.status === 'setup'" class="drag-handle">
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
                      v-if="tournament?.status === 'setup'"
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
                  v-if="tournament?.status === 'setup' && getGroupTeams(group.id).length < maxTeamsPerGroup"
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
            </div>
          </div>
        </div>

        <!-- Knockout Phase Management -->
        <div v-else-if="division?.type === 'knockout'" class="space-y-6">
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h3 class="text-xl font-bold text-white mb-4">Knockout Participants</h3>
            
            <!-- Seeded Teams List -->
            <div class="space-y-2 mb-4">
              <div 
                v-for="(participation, index) in knockoutParticipations" 
                :key="participation.team_id"
                class="team-in-group knockout-team"
                :class="{ 'dragging': draggedTeam?.id === participation.team_id }"
                :draggable="tournament?.status === 'setup'"
                @dragstart="handleTeamDragStart(getTeamById(participation.team_id), participation, 'knockout', participation.position_in_group || index, $event)"
                @dragend="handleDragEnd"
              >
                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-3">
                    <div v-if="tournament?.status === 'setup'" class="drag-handle">
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
                    v-if="tournament?.status === 'setup'"
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
                v-if="tournament?.status === 'setup'"
                class="drop-zone"
                :class="{ 'active': dragOverGroup === 'knockout' }"
                @dragover.prevent="handleDragOver('knockout')"
                @dragleave="handleDragLeave"
                @drop="handleDrop('knockout', $event)"
              >
                Drop teams here for knockout bracket
              </div>
            </div>
          </div>
        </div>

        <!-- Matches Section -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-white">Match Schedule</h2>
            <div class="flex space-x-3">
              <button 
                v-if="tournament?.status === 'setup' && teamParticipations.length >= 2"
                @click="generateMatches"
                class="btn btn-primary"
              >
                � Generate Schedule
              </button>
              <button 
                v-if="matches.length > 0"
                @click="refreshMatches"
                class="btn btn-secondary"
              >
                🔄 Refresh
              </button>
            </div>
          </div>

          <div v-if="loadingMatches" class="text-center py-8">
            <div class="text-white/60">Loading matches...</div>
          </div>

          <div v-else-if="matches.length === 0" class="text-center py-8">
            <div class="text-white/60 mb-4">No matches scheduled yet</div>
            <div class="text-sm text-blue-200">
              {{ teamParticipations.length >= 2 
                ? 'Click "Generate Schedule" to create matches' 
                : 'Assign at least 2 teams to generate matches' 
              }}
            </div>
          </div>

          <div v-else class="space-y-4">
            <div class="grid gap-4">
              <div 
                v-for="(match, index) in matches" 
                :key="match.id"
                class="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-white/20 transition-colors"
              >
                <div class="flex justify-between items-center">
                  <div class="flex-1">
                    <div class="flex items-center space-x-4">
                      <div class="text-sm text-blue-200 font-mono min-w-[80px]">
                        {{ match.start_time || `Match ${index + 1}` }}
                      </div>
                      <div class="flex-1">
                        <div class="text-white font-semibold">
                          {{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}
                        </div>
                        <div class="text-xs text-white/60 mt-1">
                          {{ match.match_type || 'Friendly' }} • {{ formatMatchStatus(match.status) }}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div class="flex items-center space-x-4">
                    <div v-if="match.status === 'finished'" class="text-right">
                      <div class="text-white font-bold">
                        {{ match.score_a }} - {{ match.score_b }}
                      </div>
                    </div>
                    
                    <div class="flex space-x-2">
                      <router-link 
                        :to="{ name: 'match-control', params: { id: match.id } }"
                        class="btn btn-xs btn-primary"
                        title="Control Match"
                      >
                        🎮
                      </router-link>
                      
                      <button 
                        v-if="tournament?.status === 'setup'"
                        @click="editMatch(match)"
                        class="btn btn-xs bg-blue-600 hover:bg-blue-700 text-white"
                        title="Edit Match Settings"
                      >
                        ⚙️
                      </button>
                      
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
                </div>
              </div>
            </div>

            <div v-if="matches.length > 0" class="text-center pt-4 border-t border-white/10">
              <div class="text-sm text-blue-200">
                Total matches: {{ matches.length }} • 
                Finished: {{ matches.filter(m => m.status === 'finished').length }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Match Settings Modal -->
    <div 
      v-if="showEditMatch" 
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showEditMatch = false"
    >
      <div class="bg-gradient-to-br from-blue-900 via-purple-900 to-pink-900 rounded-xl p-6 w-full max-w-md mx-4 border border-white/20">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-xl font-bold text-white">Match Settings</h3>
          <button 
            @click="showEditMatch = false"
            class="text-white/60 hover:text-white text-xl"
          >
            ×
          </button>
        </div>

        <div v-if="editingMatch" class="space-y-4">
          <!-- Match Info -->
          <div class="bg-white/10 rounded-lg p-4 mb-4">
            <div class="text-white font-semibold text-center">
              {{ getTeamName(editingMatch.team_a) }} vs {{ getTeamName(editingMatch.team_b) }}
            </div>
            <div class="text-xs text-blue-200 text-center mt-1">
              {{ editingMatch.match_type || 'Friendly' }} Match
            </div>
          </div>

          <!-- Settings Form -->
          <div class="space-y-4">
            <!-- Quarters Count -->
            <div>
              <label class="block text-sm font-medium text-blue-200 mb-2">
                Quarters
              </label>
              <input
                v-model.number="editMatchSettings.quarters_count"
                type="number"
                min="1"
                max="10"
                class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
              <div class="text-xs text-white/60 mt-1">Default: 2 quarters</div>
            </div>

            <!-- Quarter Duration -->
            <div>
              <label class="block text-sm font-medium text-blue-200 mb-2">
                Quarter Length (minutes)
              </label>
              <input
                v-model.number="editMatchSettings.quarter_duration_minutes"
                type="number"
                min="1"
                max="60"
                class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
              <div class="text-xs text-white/60 mt-1">Default: 15 minutes per quarter</div>
            </div>

            <!-- Break Duration -->
            <div>
              <label class="block text-sm font-medium text-blue-200 mb-2">
                Break Time (minutes)
              </label>
              <input
                v-model.number="editMatchSettings.break_duration_minutes"
                type="number"
                min="0"
                max="30"
                class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
              <div class="text-xs text-white/60 mt-1">Default: 2 minutes between quarters</div>
            </div>

            <!-- Halftime Duration -->
            <div>
              <label class="block text-sm font-medium text-blue-200 mb-2">
                Halftime (minutes)
              </label>
              <input
                v-model.number="editMatchSettings.halftime_duration_minutes"
                type="number"
                min="0"
                max="60"
                class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
              <div class="text-xs text-white/60 mt-1">Default: 10 minutes at halftime</div>
            </div>
          </div>

          <!-- Source Info -->
          <div class="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-3 mt-4">
            <div class="text-xs text-yellow-200">
              <div class="font-semibold mb-1">Settings Source:</div>
              <div v-if="editingMatch.tournament_id">
                🏆 Tournament defaults applied • Can be customized per match
              </div>
              <div v-else>
                ⚡ Standalone match • Using standard defaults
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex space-x-3 pt-4">
            <button 
              @click="resetToDefaults"
              class="flex-1 btn btn-secondary"
            >
              Reset to Defaults
            </button>
            <button 
              @click="saveMatchSettings"
              class="flex-1 btn btn-primary"
            >
              Save Settings
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

interface Tournament {
  id: string
  name: string
  start_date: string
  end_date?: string
  status: 'setup' | 'active' | 'finished'
  max_teams_per_group?: number
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
}

interface Division {
  id: string
  tournament_id: string
  name: string
  type: 'group' | 'knockout'
}

interface Group {
  id: string
  division_id: string
  name: string
}

interface Team {
  id: string
  name: string
  players?: any[]
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
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  status: 'pending' | 'active' | 'paused' | 'finished'
  start_time?: string
  tournament_id?: string
  division_id?: string
  match_type?: string
  round_number?: number
  match_order?: number
  // Match settings
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
}

interface MatchSettings {
  quarters_count: number
  quarter_duration_minutes: number
  break_duration_minutes: number
  halftime_duration_minutes: number
}

const route = useRoute()
const router = useRouter()

// Reactive data
const tournament = ref<Tournament | null>(null)
const division = ref<Division | null>(null)
const groups = ref<Group[]>([])
const availableTeams = ref<Team[]>([])
const teamParticipations = ref<TeamParticipation[]>([])
const loading = ref(true)

// Matches data
const matches = ref<Match[]>([])
const loadingMatches = ref(false)

// Match editing
const showEditMatch = ref(false)
const editingMatch = ref<Match | null>(null)
const editMatchSettings = reactive<MatchSettings>({
  quarters_count: 2,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10
})

// Drag and drop state
const draggedTeam = ref<Team | null>(null)
const dragOverGroup = ref<string | null>(null)

// Computed properties
const maxTeamsPerGroup = computed(() => tournament.value?.max_teams_per_group || 4)

const assignedTeamsCount = computed(() => {
  return availableTeams.value.filter(team => isTeamAssigned(team.id)).length
})

const knockoutParticipations = computed(() => {
  return teamParticipations.value.filter(tp => !tp.group_id)
})

const canGenerateMatches = computed(() => {
  return tournament.value?.status === 'setup' && 
         teamParticipations.value.length >= 2
})

// Drag and drop functions
function handleDragStart(team: Team | undefined, event: DragEvent) {
  if (!team || !event.dataTransfer) return
  
  console.log('Drag started for team:', team.name)
  draggedTeam.value = team
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('text/plain', team.id)
}

function handleDragEnd() {
  draggedTeam.value = null
  dragOverGroup.value = null
}

function handleDragOver(groupId: string) {
  if (!draggedTeam.value) return
  
  const currentTeamsInGroup = getGroupTeams(groupId)
  if (currentTeamsInGroup.length < maxTeamsPerGroup.value) {
    dragOverGroup.value = groupId
  }
}

function handleDragLeave(event: DragEvent) {
  // Only clear if we're really leaving the drop zone
  if (event.relatedTarget && !(event.currentTarget as Element).contains(event.relatedTarget as Node)) {
    dragOverGroup.value = null
  }
}

async function handleDrop(groupId: string, event: DragEvent) {
  event.preventDefault()
  dragOverGroup.value = null
  
  if (!draggedTeam.value || !tournament.value) {
    console.log('No dragged team or tournament')
    return
  }
  
  const team = draggedTeam.value
  console.log('Dropping team:', team.name, 'into group:', groupId)
  
  // Check if group is full
  const currentTeamsInGroup = getGroupTeams(groupId)
  if (currentTeamsInGroup.length >= maxTeamsPerGroup.value) {
    console.log('Group is full')
    alert(`Group is full (${maxTeamsPerGroup.value} teams maximum)`)
    draggedTeam.value = null
    return
  }
  
  try {
    const newPosition = currentTeamsInGroup.length + 1
    console.log('Assigning team to position:', newPosition)
    
    // Use upsert to handle both new assignments and moves
    await upsertTeamInGroup(team.id, groupId, newPosition)
    
    // Reload data to update UI
    await loadData()
    console.log('Team assignment successful')
  } catch (error) {
    console.error('Error in drag and drop:', error)
    alert('Failed to move team')
  }
  
  draggedTeam.value = null
}

function handleTeamDragStart(team: Team | undefined, participation: TeamParticipation | undefined, groupId: string, position: number, event: DragEvent) {
  if (!team || !event.dataTransfer) return
  
  draggedTeam.value = team
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('text/plain', team.id)
}

// Team management functions
async function moveTeamToGroup(participationId: string, groupId: string, position: number) {
  try {
    const { error } = await supabase
      .from('tournament_team_participations')
      .update({ 
        group_id: groupId,
        position_in_group: position 
      })
      .eq('id', participationId)
    
    if (!error) {
      // Update local state
      const participation = teamParticipations.value.find(p => p.id === participationId)
      if (participation) {
        participation.group_id = groupId
        participation.position_in_group = position
      }
    }
  } catch (error) {
    console.error('Error moving team to group:', error)
  }
}

async function assignTeamToGroupAtPosition(teamId: string, groupId: string, position: number) {
  try {
    const { data, error } = await supabase
      .from('tournament_team_participations')
      .insert([{
        tournament_id: tournament.value!.id,
        team_id: teamId,
        group_id: groupId,
        position_in_group: position
      }])
      .select()
      .single()

    if (!error && data) {
      teamParticipations.value.push(data)
    }
  } catch (error) {
    console.error('Error assigning team to group:', error)
  }
}

async function upsertTeamInGroup(teamId: string, groupId: string, position: number) {
  if (!tournament.value) {
    throw new Error('No tournament loaded')
  }

  try {
    console.log('Upserting team:', teamId, 'to group:', groupId, 'at position:', position)
    
    // First check if team is already assigned to this tournament
    const { data: existingParticipation, error: checkError } = await supabase
      .from('tournament_team_participations')
      .select('*')
      .eq('tournament_id', tournament.value.id)
      .eq('team_id', teamId)
      .maybeSingle()

    if (checkError) {
      console.error('Error checking existing participation:', checkError)
      throw checkError
    }

    if (existingParticipation) {
      // Update existing participation
      const { data, error } = await supabase
        .from('tournament_team_participations')
        .update({
          group_id: groupId,
          position_in_group: position
        })
        .eq('id', existingParticipation.id)
        .select()
        .single()

      if (error) {
        console.error('Error updating team participation:', error)
        throw error
      }
      
      console.log('Updated existing participation:', data)
    } else {
      // Create new participation
      const { data, error } = await supabase
        .from('tournament_team_participations')
        .insert({
          tournament_id: tournament.value.id,
          team_id: teamId,
          group_id: groupId,
          position_in_group: position
        })
        .select()
        .single()

      if (error) {
        console.error('Error creating team participation:', error)
        throw error
      }
      
      console.log('Created new participation:', data)
    }
  } catch (error) {
    console.error('Error in upsertTeamInGroup:', error)
    throw error
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
      await loadData()
    }
  } catch (error) {
    console.error('Error removing team from group:', error)
  }
}

async function removeTeamFromKnockout(participationId: string) {
  await removeTeamFromGroup(participationId)
}

async function autoFillTeams() {
  if (!tournament.value || tournament.value.status !== 'setup') {
    alert('Auto-fill is only available during tournament setup')
    return
  }

  const unassignedTeams = availableTeams.value.filter(team => !isTeamAssigned(team.id))
  console.log('Unassigned teams:', unassignedTeams.length)
  
  if (unassignedTeams.length === 0) {
    alert('All teams are already assigned')
    return
  }

  if (groups.value.length === 0) {
    alert('No groups available for assignment')
    return
  }

  const confirmed = confirm(`Auto-fill ${unassignedTeams.length} unassigned teams into available group slots?`)
  if (!confirmed) return

  try {
    let groupIndex = 0
    let assignedCount = 0
    
    for (const team of unassignedTeams) {
      let attempts = 0
      let assigned = false
      
      // Try to find a group with space, starting from current groupIndex
      while (attempts < groups.value.length && !assigned) {
        const currentGroup = groups.value[groupIndex]
        if (currentGroup && getGroupTeams(currentGroup.id).length < maxTeamsPerGroup.value) {
          const position = getGroupTeams(currentGroup.id).length + 1
          console.log(`Assigning ${team.name} to ${currentGroup.name} at position ${position}`)
          
          await assignTeamToGroupAtPosition(team.id, currentGroup.id, position)
          assignedCount++
          assigned = true
        }
        
        groupIndex = (groupIndex + 1) % groups.value.length
        attempts++
      }
      
      if (!assigned) {
        console.log(`Could not assign ${team.name} - all groups are full`)
        break
      }
    }
    
    // Reload data to update UI
    await loadData()
    
    if (assignedCount > 0) {
      alert(`Successfully assigned ${assignedCount} teams to groups!`)
    } else {
      alert('No teams could be assigned - all groups may be full')
    }
    
  } catch (error) {
    console.error('Error in auto-fill teams:', error)
    alert('Failed to auto-fill teams. Please try again.')
  }
}

async function generateMatches() {
  if (!division.value || !tournament.value) {
    alert('Division or tournament not loaded')
    return
  }

  try {
    loadingMatches.value = true

    // Get teams assigned to this division
    const { data: participations, error: participationsError } = await supabase
      .from('tournament_team_participations')
      .select(`
        *,
        teams:team_id (id, name, players),
        tournament_groups:group_id (id, name, division_id)
      `)
      .eq('tournament_id', tournament.value.id)
    
    if (participationsError) {
      console.error('Error fetching team participations:', participationsError)
      alert('Failed to load team assignments. Please try again.')
      return
    }

    // Filter teams that are in groups belonging to this division
    const divisionTeams = participations?.filter(p => 
      p.tournament_groups?.division_id === division.value!.id
    ).map(p => p.teams) || []
    
    if (divisionTeams.length < 2) {
      alert(`Need at least 2 teams assigned to this division to generate matches. Currently ${divisionTeams.length} teams assigned.`)
      return
    }

    // Check if matches already exist for this division
    const { data: existingMatches } = await supabase
      .from('matches')
      .select('id')
      .eq('division_id', division.value.id)
      .eq('tournament_id', tournament.value.id)

    if (existingMatches && existingMatches.length > 0) {
      const confirmed = confirm(`This division already has ${existingMatches.length} matches. Do you want to delete them and generate new ones?`)
      if (!confirmed) return
      
      // Delete existing matches
      const { error: deleteError } = await supabase
        .from('matches')
        .delete()
        .eq('division_id', division.value.id)
        .eq('tournament_id', tournament.value.id)
        
      if (deleteError) {
        console.error('Error deleting existing matches:', deleteError)
        alert('Failed to delete existing matches. Please try again.')
        return
      }
    }

    // Generate matches based on division type
    const matchesToCreate: any[] = []
    
    // Get default match settings from tournament
    const defaultSettings = getDefaultMatchSettings({
      tournament_id: tournament.value.id,
      division_id: division.value.id
    } as Match)
    
    if (division.value.type === 'group') {
      // Round-robin for group divisions - every team plays every other team
      for (let i = 0; i < divisionTeams.length; i++) {
        for (let j = i + 1; j < divisionTeams.length; j++) {
          const teamA = divisionTeams[i]
          const teamB = divisionTeams[j]
          if (!teamA || !teamB) continue
          
          matchesToCreate.push({
            team_a: teamA.id,
            team_b: teamB.id,
            status: 'pending',
            division_id: division.value.id,
            tournament_id: tournament.value.id,
            match_type: 'group',
            score_a: 0,
            score_b: 0,
            time_left: (() => {
              const quarters = defaultSettings.quarters_count
              const quarterDuration = defaultSettings.quarter_duration_minutes
              const breakDuration = defaultSettings.break_duration_minutes
              const halftimeDuration = defaultSettings.halftime_duration_minutes
              
              const totalPlayingTime = quarters * quarterDuration
              let totalBreakTime = 0
              
              if (quarters === 1) {
                totalBreakTime = 0
              } else if (quarters === 2) {
                totalBreakTime = halftimeDuration
              } else if (quarters > 2) {
                const numberOfBreaks = quarters - 1
                const regularBreaks = numberOfBreaks - 1
                totalBreakTime = regularBreaks * breakDuration + halftimeDuration
              }
              
              return (totalPlayingTime + totalBreakTime) * 60 // Convert to seconds
            })(),
            maddie: false,
            boosters: {},
            cards: {},
            // Match settings from tournament defaults
            quarters_count: defaultSettings.quarters_count,
            quarter_duration_minutes: defaultSettings.quarter_duration_minutes,
            break_duration_minutes: defaultSettings.break_duration_minutes,
            halftime_duration_minutes: defaultSettings.halftime_duration_minutes
          })
        }
      }
    } else if (division.value.type === 'knockout') {
      // Single elimination for knockout divisions
      // First round matches
      for (let i = 0; i < divisionTeams.length - 1; i += 2) {
        const teamA = divisionTeams[i]
        const teamB = divisionTeams[i + 1]
        if (!teamA || !teamB) continue
        
        matchesToCreate.push({
          team_a: teamA.id,
          team_b: teamB.id,
          status: 'pending',
          division_id: division.value.id,
          tournament_id: tournament.value.id,
          match_type: 'knockout',
          round_number: 1,
          match_order: matchesToCreate.length,
          score_a: 0,
          score_b: 0,
          time_left: (() => {
            const quarters = defaultSettings.quarters_count
            const quarterDuration = defaultSettings.quarter_duration_minutes
            const breakDuration = defaultSettings.break_duration_minutes
            const halftimeDuration = defaultSettings.halftime_duration_minutes
            
            const totalPlayingTime = quarters * quarterDuration
            let totalBreakTime = 0
            
            if (quarters === 1) {
              totalBreakTime = 0
            } else if (quarters === 2) {
              totalBreakTime = halftimeDuration
            } else if (quarters > 2) {
              const numberOfBreaks = quarters - 1
              const regularBreaks = numberOfBreaks - 1
              totalBreakTime = regularBreaks * breakDuration + halftimeDuration
            }
            
            return (totalPlayingTime + totalBreakTime) * 60 // Convert to seconds
          })(),
          maddie: false,
          boosters: {},
          cards: {},
          // Match settings from tournament defaults
          quarters_count: defaultSettings.quarters_count,
          quarter_duration_minutes: defaultSettings.quarter_duration_minutes,
          break_duration_minutes: defaultSettings.break_duration_minutes,
          halftime_duration_minutes: defaultSettings.halftime_duration_minutes
        })
      }
    }

    if (matchesToCreate.length === 0) {
      alert('No matches could be generated. Check division configuration and team assignments.')
      return
    }

    // Save matches to database
    const { data, error } = await supabase
      .from('matches')
      .insert(matchesToCreate)
      .select()

    if (error) {
      console.error('Error saving matches:', error)
      alert('Failed to save matches to database. Please try again.')
      return
    }

    // Update local state with new matches
    if (data) {
      matches.value = data
      console.log(`Generated and saved ${data.length} matches for division: ${division.value.name}`)
      alert(`Successfully generated ${data.length} matches for ${division.value.name}!`)
    }
    
  } catch (error) {
    console.error('Error generating matches:', error)
    alert('An error occurred while generating matches. Please try again.')
  } finally {
    loadingMatches.value = false
  }
}

// Match-related functions
async function refreshMatches() {
  if (!division.value || !tournament.value) return
  
  try {
    loadingMatches.value = true
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .eq('division_id', division.value.id)
      .eq('tournament_id', tournament.value.id)
      .order('created_at')

    if (error) {
      console.error('Error loading matches:', error)
      return
    }

    matches.value = data || []
  } catch (error) {
    console.error('Error refreshing matches:', error)
  } finally {
    loadingMatches.value = false
  }
}

async function deleteMatch(matchId: string) {
  if (!confirm('Are you sure you want to delete this match?')) return
  
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

    // Remove from local state
    matches.value = matches.value.filter(m => m.id !== matchId)
  } catch (error) {
    console.error('Error deleting match:', error)
    alert('An error occurred while deleting the match.')
  }
}

function getTeamName(teamId: string): string {
  const team = availableTeams.value.find(t => t.id === teamId)
  return team?.name || 'Unknown Team'
}

function formatMatchStatus(status: string): string {
  switch (status) {
    case 'pending': return 'Scheduled'
    case 'active': return 'In Progress'
    case 'paused': return 'Paused'
    case 'finished': return 'Finished'
    default: return status
  }
}

// Match editing functions
function editMatch(match: Match) {
  editingMatch.value = match
  
  // Load settings from match or use defaults
  const defaultSettings = getDefaultMatchSettings(match)
  editMatchSettings.quarters_count = match.quarters_count || defaultSettings.quarters_count
  editMatchSettings.quarter_duration_minutes = match.quarter_duration_minutes || defaultSettings.quarter_duration_minutes
  editMatchSettings.break_duration_minutes = match.break_duration_minutes || defaultSettings.break_duration_minutes
  editMatchSettings.halftime_duration_minutes = match.halftime_duration_minutes || defaultSettings.halftime_duration_minutes
  
  showEditMatch.value = true
}

function getDefaultMatchSettings(match: Match): MatchSettings {
  // If tournament match, use tournament settings
  if (match.tournament_id && tournament.value) {
    return {
      quarters_count: tournament.value.quarters_count || 2,
      quarter_duration_minutes: tournament.value.quarter_duration_minutes || 15,
      break_duration_minutes: tournament.value.break_duration_minutes || 2,
      halftime_duration_minutes: tournament.value.halftime_duration_minutes || 10
    }
  }
  
  // Otherwise use standard defaults
  return {
    quarters_count: 2,
    quarter_duration_minutes: 15,
    break_duration_minutes: 2,
    halftime_duration_minutes: 10
  }
}

function resetToDefaults() {
  if (!editingMatch.value) return
  
  const defaults = getDefaultMatchSettings(editingMatch.value)
  editMatchSettings.quarters_count = defaults.quarters_count
  editMatchSettings.quarter_duration_minutes = defaults.quarter_duration_minutes
  editMatchSettings.break_duration_minutes = defaults.break_duration_minutes
  editMatchSettings.halftime_duration_minutes = defaults.halftime_duration_minutes
}

async function saveMatchSettings() {
  if (!editingMatch.value) return
  
  try {
    const { error } = await supabase
      .from('matches')
      .update({
        quarters_count: editMatchSettings.quarters_count,
        quarter_duration_minutes: editMatchSettings.quarter_duration_minutes,
        break_duration_minutes: editMatchSettings.break_duration_minutes,
        halftime_duration_minutes: editMatchSettings.halftime_duration_minutes
      })
      .eq('id', editingMatch.value.id)

    if (error) {
      console.error('Error updating match settings:', error)
      alert('Failed to save match settings. Please try again.')
      return
    }

    // Update local match object
    const matchIndex = matches.value.findIndex(m => m.id === editingMatch.value!.id)
    if (matchIndex >= 0 && matches.value[matchIndex]) {
      const match = matches.value[matchIndex]
      match.quarters_count = editMatchSettings.quarters_count
      match.quarter_duration_minutes = editMatchSettings.quarter_duration_minutes
      match.break_duration_minutes = editMatchSettings.break_duration_minutes
      match.halftime_duration_minutes = editMatchSettings.halftime_duration_minutes
    }

    showEditMatch.value = false
    editingMatch.value = null
    
    alert('Match settings saved successfully!')
  } catch (error) {
    console.error('Error saving match settings:', error)
    alert('An error occurred while saving match settings.')
  }
}

// Utility functions
function getGroupTeams(groupId: string): TeamParticipation[] {
  return teamParticipations.value
    .filter(tp => tp.group_id === groupId)
    .sort((a, b) => (a.position_in_group || 0) - (b.position_in_group || 0))
}

function getTeamById(teamId: string): Team | undefined {
  return availableTeams.value.find(t => t.id === teamId)
}

function isTeamAssigned(teamId: string): boolean {
  return teamParticipations.value.some(tp => tp.team_id === teamId)
}

function getTeamGroup(teamId: string): string {
  const participation = teamParticipations.value.find(tp => tp.team_id === teamId)
  if (!participation) return 'Unassigned'
  if (!participation.group_id) return 'Knockout'
  const group = groups.value.find(g => g.id === participation.group_id)
  return group?.name || 'Unknown'
}

function getTournamentStatusClass(status: string): string {
  switch (status) {
    case 'setup': return 'bg-yellow-500/20 text-yellow-300'
    case 'active': return 'bg-green-500/20 text-green-300' 
    case 'finished': return 'bg-blue-500/20 text-blue-300'
    default: return 'bg-gray-500/20 text-gray-300'
  }
}

// Data loading
async function loadData() {
  try {
    const divisionId = route.params.divisionId as string
    
    // Load division
    const { data: divisionData } = await supabase
      .from('tournament_divisions')
      .select('*')
      .eq('id', divisionId)
      .single()
    
    if (divisionData) {
      division.value = divisionData
    }

    // Load tournament
    const { data: tournamentData } = await supabase
      .from('tournaments')
      .select('*')
      .eq('id', divisionData?.tournament_id)
      .single()
    
    if (tournamentData) {
      tournament.value = tournamentData
    }

    // Load groups
    const { data: groupsData } = await supabase
      .from('tournament_groups')
      .select('*')
      .eq('division_id', divisionId)
      .order('name')
    
    if (groupsData) {
      groups.value = groupsData
    }

    // Load teams
    const { data: teamsData } = await supabase
      .from('teams')
      .select('*')
      .order('name')
    
    if (teamsData) {
      availableTeams.value = teamsData
    }

    // Load team participations
    const { data: participationsData } = await supabase
      .from('tournament_team_participations')
      .select('*')
      .eq('tournament_id', tournamentData?.id)
    
    if (participationsData) {
      teamParticipations.value = participationsData
    }

    // Load matches for this division
    if (divisionData && tournamentData) {
      const { data: matchesData } = await supabase
        .from('matches')
        .select('*')
        .eq('division_id', divisionData.id)
        .eq('tournament_id', tournamentData.id)
        .order('created_at')
      
      if (matchesData) {
        matches.value = matchesData
      }
    }

  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.btn {
  @apply px-4 py-2 rounded-lg font-medium transition-colors;
}

.btn-primary {
  @apply bg-blue-600 hover:bg-blue-700 text-white;
}

.btn-secondary {
  @apply bg-purple-600 hover:bg-purple-700 text-white;
}

.btn-success {
  @apply bg-green-600 hover:bg-green-700 text-white;
}

.btn-outline {
  @apply border border-white/30 text-white hover:bg-white/10;
}

.team-card {
  @apply bg-white/10 p-3 rounded-lg border border-white/20 text-white text-sm cursor-pointer transition-all;
}

.team-card:hover {
  @apply bg-white/20 transform scale-105;
}

.team-card.assigned {
  @apply bg-green-500/20 border-green-500/40;
}

.team-card.dragging {
  @apply opacity-50 transform rotate-2;
}

.team-in-group {
  @apply bg-white/5 p-3 rounded border border-white/10;
}

.team-in-group.dragging {
  @apply opacity-50;
}

.drop-zone {
  @apply border-2 border-dashed border-white/30 rounded-lg p-4 text-center text-white/60 text-sm transition-colors;
}

.drop-zone.active {
  @apply border-blue-400 bg-blue-400/10 text-blue-300;
}

.drag-handle {
  @apply cursor-move opacity-50 hover:opacity-100;
}
</style>