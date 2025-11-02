<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 p-8">
    <div class="container mx-auto max-w-4xl">
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
        <h1 class="text-3xl font-bold text-white mb-6">🔧 Authentication Diagnostic</h1>
        
        <!-- Environment Check -->
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-white mb-3">🌍 Environment Configuration</h2>
          <div class="bg-black/20 rounded-lg p-4 space-y-2 font-mono text-sm">
            <div class="text-green-300">
              <strong>Supabase URL:</strong> {{ supabaseConfig.url }}
            </div>
            <div class="text-green-300">
              <strong>Anon Key Preview:</strong> {{ supabaseConfig.keyPreview }}
            </div>
            <div class="text-yellow-300">
              <strong>Source:</strong> {{ supabaseConfig.source }}
            </div>
          </div>
        </div>

        <!-- Connection Test -->
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-white mb-3">🔌 Connection Test</h2>
          <button 
            @click="testConnection" 
            :disabled="connectionTesting"
            class="btn btn-primary mb-3"
          >
            {{ connectionTesting ? 'Testing...' : 'Test Supabase Connection' }}
          </button>
          
          <div v-if="connectionResult" class="bg-black/20 rounded-lg p-4 font-mono text-sm">
            <div :class="connectionResult.success ? 'text-green-300' : 'text-red-300'">
              <strong>Status:</strong> {{ connectionResult.success ? '✅ Connected' : '❌ Connection Failed' }}
            </div>
            <div v-if="connectionResult.error" class="text-red-300 mt-2">
              <strong>Error:</strong> {{ connectionResult.error }}
            </div>
            <div v-if="connectionResult.details" class="text-blue-300 mt-2">
              <strong>Details:</strong> {{ connectionResult.details }}
            </div>
          </div>
        </div>

        <!-- Auth Store Status -->
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-white mb-3">🔐 Auth Store Status</h2>
          <div class="bg-black/20 rounded-lg p-4 space-y-2 font-mono text-sm">
            <div class="text-blue-300">
              <strong>Loading:</strong> {{ authStore.loading }}
            </div>
            <div class="text-blue-300">
              <strong>Is Authenticated:</strong> {{ authStore.isAuthenticated }}
            </div>
            <div class="text-blue-300">
              <strong>Is Admin:</strong> {{ authStore.isAdmin }}
            </div>
            <div class="text-blue-300">
              <strong>User ID:</strong> {{ authStore.user?.id || 'None' }}
            </div>
            <div class="text-blue-300">
              <strong>Profile Email:</strong> {{ authStore.profile?.email || 'None' }}
            </div>
          </div>
        </div>

        <!-- Test Login -->
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-white mb-3">🧪 Test Authentication</h2>
          <div class="grid md:grid-cols-2 gap-4">
            <div>
              <label class="block text-white mb-2">Test Email:</label>
              <input 
                v-model="testEmail" 
                type="email" 
                placeholder="admin@test.com"
                class="input w-full"
              >
            </div>
            <div>
              <label class="block text-white mb-2">Test Password:</label>
              <input 
                v-model="testPassword" 
                type="password" 
                placeholder="password"
                class="input w-full"
              >
            </div>
          </div>
          <button 
            @click="testAuth" 
            :disabled="authTesting"
            class="btn btn-primary mt-3"
          >
            {{ authTesting ? 'Testing...' : 'Test Login' }}
          </button>
          
          <div v-if="authResult" class="bg-black/20 rounded-lg p-4 font-mono text-sm mt-3">
            <div :class="authResult.success ? 'text-green-300' : 'text-red-300'">
              <strong>Status:</strong> {{ authResult.success ? '✅ Login Successful' : '❌ Login Failed' }}
            </div>
            <div v-if="authResult.error" class="text-red-300 mt-2">
              <strong>Error:</strong> {{ authResult.error }}
            </div>
            <div v-if="authResult.details" class="text-blue-300 mt-2">
              <strong>Details:</strong> {{ authResult.details }}
            </div>
          </div>
        </div>

        <!-- Instructions -->
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-white mb-3">📋 Troubleshooting Steps</h2>
          <div class="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-4">
            <ol class="text-yellow-100 space-y-2 list-decimal list-inside">
              <li>Ensure Supabase is running: <code class="bg-black/20 px-2 py-1 rounded">npx supabase start</code></li>
              <li>Check if port 54321 is available</li>
              <li>Verify database migrations are applied: <code class="bg-black/20 px-2 py-1 rounded">npx supabase db reset</code></li>
              <li>Check if admin user exists in users table</li>
              <li>Try restarting both Supabase and the frontend server</li>
            </ol>
          </div>
        <li><strong>Schema:</strong> Run the SQL migration from <code>supabase/migrations/</code></li>
        <li><strong>Admin Account:</strong> Sign up at /login and set role to 'admin'</li>
      </ol>
    </div>

    <div style="margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; background: #f8f9fa;">
      <h2>🛠 Environment Info</h2>
      <p><strong>Supabase URL:</strong> {{ supabaseUrl || 'Not configured' }}</p>
      <p><strong>Base URL:</strong> {{ baseUrl }}</p>
      <p><strong>Node Env:</strong> {{ nodeEnv }}</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const baseUrl = import.meta.env.BASE_URL
const nodeEnv = import.meta.env.NODE_ENV

const envStatus = computed(() => {
  if (!supabaseUrl || supabaseUrl.includes('your-project-ref')) {
    return '⚠️ Supabase: Not configured'
  }
  return '✅ Supabase: Configured'
})

const authStatus = computed(() => {
  return '⚠️ Authentication: Requires database setup'
})
</script>