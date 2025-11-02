<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface Team {
  id: string
  name: string
  players: Player[]
}

interface Player {
  name: string
  number: number
  position: 'Forward' | 'Defense' | 'Goalie'
}

const teams = ref<Team[]>([])
const loading = ref(true)
const showAddTeam = ref(false)
const editingTeam = ref<Team | null>(null)

// Form data
const teamForm = ref({
  name: '',
  players: [] as Player[]
})

const newPlayer = ref({
  name: '',
  number: 1,
  position: 'Forward' as Player['position']
})

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')
      .order('name')

    if (error) {
      console.error('Error loading teams:', error)
      return
    }

    teams.value = data || []
  } catch (error) {
    console.error('Error loading teams:', error)
  } finally {
    loading.value = false
  }
}

function startAddTeam() {
  editingTeam.value = null
  teamForm.value = { name: '', players: [] }
  showAddTeam.value = true
}

function startEditTeam(team: Team) {
  editingTeam.value = team
  teamForm.value = {
    name: team.name,
    players: [...team.players]
  }
  showAddTeam.value = true
}

function cancelForm() {
  showAddTeam.value = false
  editingTeam.value = null
  teamForm.value = { name: '', players: [] }
  newPlayer.value = { name: '', number: 1, position: 'Forward' }
}

function addPlayer() {
  if (!newPlayer.value.name) return
  
  // Check if number is already used
  if (teamForm.value.players.some(p => p.number === newPlayer.value.number)) {
    alert('Player number already exists')
    return
  }
  
  teamForm.value.players.push({ ...newPlayer.value })
  newPlayer.value = { name: '', number: getNextNumber(), position: 'Forward' }
}

function removePlayer(index: number) {
  teamForm.value.players.splice(index, 1)
}

function getNextNumber(): number {
  const usedNumbers = teamForm.value.players.map(p => p.number)
  for (let i = 1; i <= 99; i++) {
    if (!usedNumbers.includes(i)) {
      return i
    }
  }
  return 1
}

async function saveTeam() {
  if (!teamForm.value.name || teamForm.value.players.length === 0) {
    alert('Please provide team name and at least one player')
    return
  }

  try {
    if (editingTeam.value) {
      // Update existing team
      const { error } = await supabase
        .from('teams')
        .update({
          name: teamForm.value.name,
          players: teamForm.value.players
        })
        .eq('id', editingTeam.value.id)

      if (error) {
        console.error('Error updating team:', error)
        alert('Error updating team')
        return
      }
    } else {
      // Create new team
      const { error } = await supabase
        .from('teams')
        .insert({
          name: teamForm.value.name,
          players: teamForm.value.players
        })

      if (error) {
        console.error('Error creating team:', error)
        alert('Error creating team')
        return
      }
    }

    await loadTeams()
    cancelForm()
  } catch (error) {
    console.error('Error saving team:', error)
    alert('Error saving team')
  }
}

async function deleteTeam(team: Team) {
  if (!confirm(`Are you sure you want to delete ${team.name}?`)) {
    return
  }

  try {
    const { error } = await supabase
      .from('teams')
      .delete()
      .eq('id', team.id)

    if (error) {
      console.error('Error deleting team:', error)
      alert('Error deleting team')
      return
    }

    await loadTeams()
  } catch (error) {
    console.error('Error deleting team:', error)
    alert('Error deleting team')
  }
}

onMounted(() => {
  loadTeams()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Page Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-4xl font-bold text-white mb-2">Teams Management</h1>
          <p class="text-blue-100">Manage tournament teams and players</p>
        </div>
        <button @click="startAddTeam" class="btn btn-primary">
          + Add Team
        </button>
      </div>

      <!-- Teams Grid -->
      <div v-if="loading" class="text-center py-16">
        <div class="text-4xl font-bold text-white animate-pulse">Loading teams...</div>
      </div>

      <div v-else-if="teams.length === 0" class="text-center py-16">
        <div class="text-6xl mb-6">🏒</div>
        <h2 class="text-3xl font-bold text-white mb-4">No Teams Yet</h2>
        <p class="text-blue-200 mb-8">Create your first team to get started</p>
        <button @click="startAddTeam" class="btn btn-primary">
          + Create First Team
        </button>
      </div>

      <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div 
          v-for="team in teams" 
          :key="team.id"
          class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20"
        >
          <div class="flex justify-between items-start mb-4">
            <h3 class="text-xl font-bold text-white">{{ team.name }}</h3>
            <div class="flex space-x-2">
              <button @click="startEditTeam(team)" class="btn btn-secondary text-sm">
                ✏️ Edit
              </button>
              <button @click="deleteTeam(team)" class="btn btn-danger text-sm">
                🗑️ Delete
              </button>
            </div>
          </div>

          <div class="text-blue-200 mb-4">
            {{ team.players.length }} players
          </div>

          <div class="space-y-2 max-h-40 overflow-y-auto">
            <div 
              v-for="player in team.players" 
              :key="player.name"
              class="flex justify-between items-center bg-white/5 rounded p-2 text-sm"
            >
              <span class="text-white font-medium">{{ player.name }}</span>
              <div class="text-right">
                <div class="text-yellow-400">#{{ player.number }}</div>
                <div class="text-blue-300 text-xs">{{ player.position }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add/Edit Team Modal -->
    <div 
      v-if="showAddTeam"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    >
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-white">
            {{ editingTeam ? 'Edit Team' : 'Add New Team' }}
          </h2>
          <button @click="cancelForm" class="text-white hover:text-red-400">
            ✕
          </button>
        </div>

        <!-- Team Name -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-white mb-2">
            Team Name
          </label>
          <input
            v-model="teamForm.name"
            type="text"
            class="input bg-white/10 text-white placeholder-blue-200 border-white/20"
            placeholder="Enter team name"
            required
          />
        </div>

        <!-- Add Player Section -->
        <div class="mb-6 bg-white/5 rounded-lg p-4">
          <h3 class="text-lg font-semibold text-white mb-4">Add Player</h3>
          
          <div class="grid md:grid-cols-3 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-white mb-2">
                Player Name
              </label>
              <input
                v-model="newPlayer.name"
                type="text"
                class="input bg-white/10 text-white placeholder-blue-200 border-white/20"
                placeholder="Player name"
              />
            </div>
            
            <div>
              <label class="block text-sm font-medium text-white mb-2">
                Jersey Number
              </label>
              <input
                v-model.number="newPlayer.number"
                type="number"
                min="1"
                max="99"
                class="input bg-white/10 text-white placeholder-blue-200 border-white/20"
              />
            </div>
            
            <div>
              <label class="block text-sm font-medium text-white mb-2">
                Position
              </label>
              <select
                v-model="newPlayer.position"
                class="input bg-white/10 text-white border-white/20"
              >
                <option value="Forward">Forward</option>
                <option value="Defense">Defense</option>
                <option value="Goalie">Goalie</option>
              </select>
            </div>
          </div>
          
          <button @click="addPlayer" class="btn btn-primary">
            + Add Player
          </button>
        </div>

        <!-- Players List -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-white mb-4">
            Team Roster ({{ teamForm.players.length }} players)
          </h3>
          
          <div v-if="teamForm.players.length === 0" class="text-center py-8 text-blue-200">
            No players added yet
          </div>
          
          <div v-else class="space-y-2 max-h-60 overflow-y-auto">
            <div 
              v-for="(player, index) in teamForm.players" 
              :key="index"
              class="flex justify-between items-center bg-white/5 rounded p-3"
            >
              <div class="flex items-center space-x-4">
                <div class="text-yellow-400 font-bold">#{{ player.number }}</div>
                <div>
                  <div class="text-white font-medium">{{ player.name }}</div>
                  <div class="text-blue-300 text-sm">{{ player.position }}</div>
                </div>
              </div>
              <button 
                @click="removePlayer(index)"
                class="text-red-400 hover:text-red-300"
              >
                🗑️ Remove
              </button>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-end space-x-4">
          <button @click="cancelForm" class="btn btn-secondary">
            Cancel
          </button>
          <button @click="saveTeam" class="btn btn-primary">
            {{ editingTeam ? 'Update Team' : 'Create Team' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>