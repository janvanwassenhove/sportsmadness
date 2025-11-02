<template>
  <div style="padding: 20px; font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto;">
    <h1 style="color: #2563eb; margin-bottom: 20px;">🏒 Hockey Madness</h1>
    
    <div style="background: #f3f4f6; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
      <h2 style="color: #374151; margin: 0 0 15px 0;">Application Status</h2>
      <div style="display: grid; gap: 10px;">
        <div>✅ Vue 3: Running</div>
        <div>✅ Router: Working</div>
        <div>{{ supabaseStatus }}</div>
        <div>{{ envStatus }}</div>
      </div>
    </div>

    <div style="background: #fef3c7; padding: 20px; border-radius: 8px; border-left: 4px solid #f59e0b; margin-bottom: 20px;">
      <h2 style="color: #92400e; margin: 0 0 15px 0;">⚡ Quick Actions</h2>
      <div style="display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));">
        <a href="/login" style="padding: 10px; background: #3b82f6; color: white; text-decoration: none; border-radius: 4px; text-align: center;">Login</a>
        <a href="/scoreboard" style="padding: 10px; background: #10b981; color: white; text-decoration: none; border-radius: 4px; text-align: center;">Scoreboard</a>
        <a href="/admin" style="padding: 10px; background: #6366f1; color: white; text-decoration: none; border-radius: 4px; text-align: center;">Admin</a>
      </div>
    </div>

    <div style="background: #f0f9ff; padding: 20px; border-radius: 8px; border-left: 4px solid #0ea5e9;">
      <h2 style="color: #0c4a6e; margin: 0 0 15px 0;">📋 Setup Status</h2>
      <p><strong>Environment Variables:</strong> {{ envVarStatus }}</p>
      <p><strong>Database:</strong> {{ dbStatus }}</p>
      <p><strong>Next Step:</strong> {{ nextStep }}</p>
    </div>

    <div style="margin-top: 30px; padding: 15px; background: #1f2937; color: white; border-radius: 8px; font-family: monospace; font-size: 14px;">
      <p><strong>Debug Info:</strong></p>
      <p>Base URL: {{ baseUrl }}</p>
      <p>Mode: {{ mode }}</p>
      <p>Supabase URL: {{ maskedUrl }}</p>
    </div>

    <div style="margin-top: 20px; padding: 15px; background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px;">
      <h3 style="margin: 0 0 15px 0; color: #495057;">🔍 Database Test</h3>
      <button @click="testDatabase" style="padding: 8px 16px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; margin-right: 10px;">
        Test DB Connection
      </button>
      <div v-if="dbTestResult" style="margin-top: 10px; padding: 10px; border-radius: 4px;" :style="{ background: dbTestResult.success ? '#d4edda' : '#f8d7da', color: dbTestResult.success ? '#155724' : '#721c24' }">
        <strong>{{ dbTestResult.success ? '✅ Success:' : '❌ Error:' }}</strong> {{ dbTestResult.message }}
        <div v-if="dbTestResult.data" style="margin-top: 8px; font-family: monospace; font-size: 12px; background: rgba(0,0,0,0.1); padding: 8px; border-radius: 3px;">
          {{ JSON.stringify(dbTestResult.data, null, 2) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

// Environment info
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const baseUrl = import.meta.env.BASE_URL
const mode = import.meta.env.MODE

// Computed status indicators
const maskedUrl = computed(() => {
  if (!supabaseUrl || supabaseUrl.includes('placeholder')) {
    return 'Not configured'
  }
  return supabaseUrl.replace(/https:\/\/([^.]+)\.supabase\.co/, 'https://*****.supabase.co')
})

const supabaseStatus = computed(() => {
  if (!supabaseUrl || supabaseUrl.includes('placeholder')) {
    return '⚠️ Supabase: Not configured'
  }
  return '✅ Supabase: Configured'
})

const envStatus = computed(() => {
  const hasUrl = supabaseUrl && !supabaseUrl.includes('placeholder')
  const hasKey = import.meta.env.VITE_SUPABASE_ANON_KEY && !import.meta.env.VITE_SUPABASE_ANON_KEY.includes('placeholder')
  
  if (hasUrl && hasKey) {
    return '✅ Environment: Ready'
  } else {
    return '⚠️ Environment: Needs configuration'
  }
})

const envVarStatus = computed(() => {
  const hasUrl = supabaseUrl && !supabaseUrl.includes('placeholder')
  const hasKey = import.meta.env.VITE_SUPABASE_ANON_KEY && !import.meta.env.VITE_SUPABASE_ANON_KEY.includes('placeholder')
  
  if (hasUrl && hasKey) {
    return 'Configured via environment variables ✅'
  } else {
    return 'Need to set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY'
  }
})

const dbStatus = computed(() => {
  const hasConfig = supabaseUrl && !supabaseUrl.includes('placeholder')
  if (hasConfig) {
    return 'Ready for schema setup'
  } else {
    return 'Waiting for Supabase configuration'
  }
})

const nextStep = computed(() => {
  const hasConfig = supabaseUrl && !supabaseUrl.includes('placeholder')
  if (hasConfig) {
    return 'Run database migration in Supabase SQL Editor'
  } else {
    return 'Set up environment variables with Supabase credentials'
  }
})

// Database testing
const dbTestResult = ref(null)

const testDatabase = async () => {
  dbTestResult.value = null
  
  try {
    console.log('Testing database connection...')
    
    // Import supabase client
    const { supabase } = await import('@/lib/supabase')
    
    // Test 1: Try to fetch teams
    const { data: teams, error: teamsError } = await supabase
      .from('teams')
      .select('*')
      .limit(5)
    
    if (teamsError) {
      dbTestResult.value = {
        success: false,
        message: `Teams query failed: ${teamsError.message}`,
        data: teamsError
      }
      return
    }
    
    // Test 2: Try to fetch matches
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*')
      .limit(5)
    
    if (matchesError) {
      dbTestResult.value = {
        success: false,
        message: `Matches query failed: ${matchesError.message}`,
        data: matchesError
      }
      return
    }
    
    dbTestResult.value = {
      success: true,
      message: `Connected! Found ${teams?.length || 0} teams, ${matches?.length || 0} matches`,
      data: { teams: teams || [], matches: matches || [] }
    }
    
  } catch (error) {
    console.error('Database test error:', error)
    dbTestResult.value = {
      success: false,
      message: `Connection failed: ${error.message}`,
      data: error
    }
  }
}
</script>