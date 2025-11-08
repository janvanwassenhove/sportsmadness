<template>
  <div style="padding: 20px; font-family: Arial, sans-serif;">
    <h1 style="color: blue;">� Hockey Madness - Working!</h1>
    <p>Vue.js is rendering correctly ✅</p>
    
    <div style="background: lightgreen; padding: 15px; margin: 15px 0; border-radius: 5px;">
      <h3>🔍 Database Test</h3>
      <button @click="testDB" style="padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; margin: 5px;">
        Test Database
      </button>
      <button @click="checkSupabase" style="padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; margin: 5px;">
        Check Supabase Config
      </button>
      
      <div v-if="result" style="margin-top: 15px; padding: 10px; border-radius: 4px;" :style="resultStyle">
        <strong>{{ result.type }}:</strong> {{ result.message }}
        <pre v-if="result.data" style="margin-top: 10px; background: rgba(0,0,0,0.1); padding: 10px; border-radius: 3px; white-space: pre-wrap; font-size: 12px;">{{ result.data }}</pre>
      </div>
    </div>

    <div style="background: lightblue; padding: 15px; margin: 15px 0; border-radius: 5px;">
      <h3>📋 Navigation</h3>
      <a href="/scoreboard" style="color: blue; text-decoration: underline; margin-right: 15px;">Scoreboard</a>
      <a href="/login" style="color: blue; text-decoration: underline; margin-right: 15px;">Login</a>
      <a href="/admin" style="color: blue; text-decoration: underline;">Admin</a>
    </div>

    <div style="background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 5px; font-family: monospace; font-size: 14px;">
      <h3>🔧 Environment Info</h3>
      <p>Supabase URL: {{ supabaseUrl || 'Not set' }}</p>
      <p>Has Anon Key: {{ hasKey ? 'Yes' : 'No' }}</p>
      <p>Mode: {{ mode }}</p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WorkingTestView',
  data() {
    return {
      result: null,
      supabaseUrl: '',
      hasKey: false,
      mode: ''
    }
  },
  computed: {
    resultStyle() {
      if (!this.result) return {}
      return {
        background: this.result.type === 'SUCCESS' ? '#d4edda' : '#f8d7da',
        color: this.result.type === 'SUCCESS' ? '#155724' : '#721c24'
      }
    }
  },
  mounted() {
    this.supabaseUrl = import.meta.env.VITE_SUPABASE_URL
    this.hasKey = !!import.meta.env.VITE_SUPABASE_ANON_KEY
    this.mode = import.meta.env.MODE
  },
  methods: {
    async checkSupabase() {
      this.result = {
        type: 'INFO',
        message: 'Supabase Configuration Check',
        data: JSON.stringify({
          url: this.supabaseUrl,
          hasKey: this.hasKey,
          urlValid: this.supabaseUrl?.includes('.supabase.co'),
          keyValid: this.hasKey && import.meta.env.VITE_SUPABASE_ANON_KEY?.startsWith('eyJ')
        }, null, 2)
      }
    },
    async testDB() {
      try {
        this.result = { type: 'INFO', message: 'Testing database connection...' }
        
        // Dynamic import to avoid issues
        const { supabase } = await import('@/lib/supabase')
        
        // Test simple query
        const { data, error } = await supabase
          .from('teams')
          .select('count(*)')
        
        if (error) {
          this.result = {
            type: 'ERROR',
            message: `Database query failed: ${error.message}`,
            data: JSON.stringify(error, null, 2)
          }
          return
        }
        
        // Try to get actual teams
        const { data: teams, error: teamsError } = await supabase
          .from('teams')
          .select('*')
          .limit(3)
        
        if (teamsError) {
          this.result = {
            type: 'ERROR', 
            message: `Teams query failed: ${teamsError.message}`,
            data: JSON.stringify(teamsError, null, 2)
          }
          return
        }
        
        this.result = {
          type: 'SUCCESS',
          message: `Database connected! Found ${teams?.length || 0} teams`,
          data: JSON.stringify(teams, null, 2)
        }
        
      } catch (error) {
        this.result = {
          type: 'ERROR',
          message: `Connection exception: ${error.message}`,
          data: error.toString()
        }
      }
    }
  }
}
</script>