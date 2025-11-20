<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')
const isSignUp = ref(false)

async function handleSubmit() {
  if (!email.value || !password.value) {
    error.value = 'Email and password are required' // TODO: Use $t('auth.emailRequired') when available in script
    return
  }

  loading.value = true
  error.value = ''
  success.value = ''

  try {
    console.log('🔐 Login form: Starting authentication process')
    const result = isSignUp.value 
      ? await authStore.signUp(email.value, password.value)
      : await authStore.signIn(email.value, password.value)

    console.log('🔐 Login form: Auth result:', result)

    if (result.error) {
      console.error('🔐 Login form: Auth error:', result.error)
      error.value = result.error
      return
    }

    if (isSignUp.value) {
      success.value = 'Account created successfully! You can now sign in.'
      // Switch to login mode after successful signup
      isSignUp.value = false
      // Clear password for security
      password.value = ''
      return
    }

    console.log('🔐 Login form: Login successful, checking auth state')
    console.log('🔐 Login form: isAuthenticated:', authStore.isAuthenticated)
    console.log('🔐 Login form: isAdmin:', authStore.isAdmin)

    // Wait for auth state and profile to fully update
    let attempts = 0
    while (!authStore.isAuthenticated && attempts < 20) {
      await new Promise(resolve => setTimeout(resolve, 100))
      attempts++
    }

    if (!authStore.isAuthenticated) {
      console.error('🔐 Login form: Auth state did not update after sign in')
      error.value = 'Authentication state error. Please try again.'
      return
    }

    console.log('🔐 Login form: Auth state confirmed after', attempts, 'attempts')
    console.log('🔐 Login form: Final state - isAuthenticated:', authStore.isAuthenticated, 'isAdmin:', authStore.isAdmin)

    // Redirect to intended page or appropriate dashboard based on role
    let redirectPath = route.query.redirect as string
    
    // Clean up redirect path if it came from GitHub Pages query string conversion
    if (redirectPath && redirectPath.startsWith('/?/')) {
      redirectPath = redirectPath.substring(2) // Remove /? prefix
    }
    
    // Default redirect based on role if no redirect specified
    if (!redirectPath) {
      redirectPath = '/' // Redirect all users to home page after login
    }
    
    console.log('🔐 Login form: Redirecting to:', redirectPath)
    
    // Use Vue Router for navigation to avoid page reload and maintain auth state
    // This works correctly with both local development and GitHub Pages
    await router.push(redirectPath)
  } catch (err: any) {
    console.error('🔐 Login form: Exception:', err)
    error.value = err.message || 'An error occurred'
  } finally {
    loading.value = false
  }
}

function toggleMode() {
  isSignUp.value = !isSignUp.value
  error.value = ''
  success.value = ''
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 flex items-center justify-center px-4">
    <div class="bg-white/10 backdrop-blur-sm rounded-xl p-8 w-full max-w-md border border-white/20">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-white mb-2">
          {{ isSignUp ? $t('auth.createAccount') : $t('auth.adminLogin') }}
        </h1>
        <p class="text-blue-100">
          {{ isSignUp ? $t('auth.signUpSubtitle') : $t('auth.loginSubtitle') }}
        </p>
      </div>

      <form @submit.prevent="handleSubmit" class="space-y-6">
        <div>
          <label for="email" class="block text-sm font-medium text-white mb-2">
            {{ $t('auth.email') }}
          </label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            class="input bg-white/10 text-white placeholder-blue-200 border-white/20"
            placeholder="admin@hockeymadness.com"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-white mb-2">
            {{ $t('auth.password') }}
          </label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            class="input bg-white/10 text-white placeholder-blue-200 border-white/20"
            :placeholder="$t('auth.enterPassword')"
          />
        </div>

        <div v-if="error" class="bg-red-500/20 border border-red-500/50 rounded-lg p-3">
          <p class="text-red-100 text-sm">{{ error }}</p>
        </div>

        <div v-if="success" class="bg-green-500/20 border border-green-500/50 rounded-lg p-3">
          <p class="text-green-100 text-sm">{{ success }}</p>
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full btn btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="loading">
            {{ isSignUp ? $t('auth.creatingAccount') : $t('auth.signingIn') }}
          </span>
          <span v-else>
            {{ isSignUp ? $t('auth.createAccount') : $t('auth.signIn') }}
          </span>
        </button>

        <div class="text-center">
          <button
            type="button"
            @click="toggleMode"
            class="text-blue-200 hover:text-white transition-colors"
          >
            {{ isSignUp ? $t('auth.alreadyHaveAccount') : $t('auth.needAccount') }}
          </button>
        </div>

        <div class="text-center">
          <RouterLink 
            to="/"
            class="text-blue-200 hover:text-white transition-colors text-sm"
          >
            {{ $t('auth.backToHome') }}
          </RouterLink>
        </div>
      </form>
    </div>
  </div>
</template>