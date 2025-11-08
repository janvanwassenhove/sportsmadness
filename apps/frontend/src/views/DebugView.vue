<template>
  <div style="padding: 20px; font-family: monospace;">
    <h1>🔍 Database Debug View</h1>
    
    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ccc; border-radius: 5px;">
      <h2>🗃️ Teams in Database</h2>
      <div v-if="loading">Loading teams...</div>
      <div v-else-if="teams.length === 0" style="color: orange;">No teams found in database</div>
      <div v-else>
        <p><strong>Found {{ teams.length }} teams:</strong></p>
        <div v-for="team in teams" :key="team.id" style="margin: 10px 0; padding: 10px; background: #f0f0f0; border-radius: 4px;">
          <strong>{{ team.name }}</strong> (ID: {{ team.id }})
          <br>Players: {{ team.players?.length || 0 }}
          <div v-if="team.players?.length > 0" style="margin-left: 20px; font-size: 0.9em;">
            <div v-for="player in team.players" :key="player">• {{ player }}</div>
          </div>
        </div>
      </div>
    </div>

    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ccc; border-radius: 5px;">
      <h2>� Matches in Database</h2>
      <div v-if="loading">Loading matches...</div>
      <div v-else-if="matches.length === 0" style="color: orange;">No matches found in database</div>
      <div v-else>
        <p><strong>Found {{ matches.length }} matches:</strong></p>
        <div v-for="match in matches" :key="match.id" style="margin: 10px 0; padding: 10px; background: #f0f0f0; border-radius: 4px;">
          <strong>{{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}</strong>
          <br>Score: {{ match.score_a }} - {{ match.score_b }}
          <br>Status: {{ match.status }}
          <br>Time: {{ Math.floor(match.time_left / 60) }}:{{ (match.time_left % 60).toString().padStart(2, '0') }}
        </div>
      </div>
    </div>

    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px;">
      <h2>🔧 Actions</h2>
      <button @click="refreshData" style="padding: 10px 20px; margin: 5px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;">
        🔄 Refresh Data
      </button>
      <button @click="testInsert" style="padding: 10px 20px; margin: 5px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer;">
        ➕ Test Insert Team
      </button>
    </div>

    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; background: #f8f9fa;">
      <h2>📋 Raw Data (JSON)</h2>
      <details>
        <summary>Teams Data</summary>
        <pre style="background: white; padding: 10px; overflow: auto;">{{ JSON.stringify(teams, null, 2) }}</pre>
      </details>
      <details>
        <summary>Matches Data</summary>
        <pre style="background: white; padding: 10px; overflow: auto;">{{ JSON.stringify(matches, null, 2) }}</pre>
      </details>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const teams = ref([])
const matches = ref([])
const loading = ref(true)

const getTeamName = (teamId) => {
  const team = teams.value.find(t => t.id === teamId)
  return team ? team.name : `Unknown (${teamId})`
}

const loadTeams = async () => {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')
    
    if (error) {
      console.error('Teams error:', error)
      return
    }
    
    teams.value = data || []
    console.log('Loaded teams:', data)
  } catch (error) {
    console.error('Teams exception:', error)
  }
}

const loadMatches = async () => {
  try {
    const { data, error } = await supabase
      .from('matches')
      .select('*')
    
    if (error) {
      console.error('Matches error:', error)
      return
    }
    
    matches.value = data || []
    console.log('Loaded matches:', data)
  } catch (error) {
    console.error('Matches exception:', error)
  }
}

const refreshData = async () => {
  loading.value = true
  await Promise.all([loadTeams(), loadMatches()])
  loading.value = false
}

const testInsert = async () => {
  try {
    const { data, error } = await supabase
      .from('teams')
      .insert({
        name: 'Test Team ' + Date.now(),
        players: ['Test Player 1', 'Test Player 2']
      })
    
    if (error) {
      console.error('Insert error:', error)
      alert('Insert failed: ' + error.message)
    } else {
      console.log('Insert success:', data)
      alert('Test team inserted successfully!')
      await refreshData()
    }
  } catch (error) {
    console.error('Insert exception:', error)
    alert('Insert exception: ' + error.message)
  }
}

onMounted(async () => {
  await refreshData()
})
</script>