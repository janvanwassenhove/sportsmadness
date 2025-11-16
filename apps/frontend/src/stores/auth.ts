import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User } from '@supabase/supabase-js'

export interface UserProfile {
  id: string
  email: string
  role: 'admin' | 'user' | 'team'
  assigned_team_id?: string | null
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const profile = ref<UserProfile | null>(null)
  const loading = ref(true)

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => profile.value?.role === 'admin')
  const isTeam = computed(() => profile.value?.role === 'team')
  const isUser = computed(() => profile.value?.role === 'user')

  async function initialize() {
    try {
      loading.value = true
      console.log('🔍 Auth initialization started')
      
      // Set a failsafe timeout
      setTimeout(() => {
        if (loading.value) {
          console.warn('🔍 Auth initialization timeout - forcing completion')
          loading.value = false
        }
      }, 15000)
      
      // Check if Supabase is properly configured
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
      console.log('🔍 Supabase URL check:', supabaseUrl ? 'Set' : 'Missing')
      if (!supabaseUrl || supabaseUrl.includes('your-project-ref')) {
        console.warn('Supabase not configured. Please update .env.local with your Supabase credentials.')
        loading.value = false
        return
      }
      
      // Get current session
      console.log('🔍 Getting current session...')
      const { data: { session } } = await supabase.auth.getSession()
      console.log('🔍 Session result:', session ? 'User logged in' : 'No session')
      
      if (session?.user) {
        user.value = session.user
        console.log('🔍 Loading user profile...')
        await loadProfile()
      }

      // Listen for auth changes
      supabase.auth.onAuthStateChange(async (event, session) => {
        console.log('🔍 Auth state changed:', event, session ? 'Session exists' : 'No session')
        if (session?.user) {
          console.log('🔍 Setting user from auth state change')
          user.value = session.user
          await loadProfile()
          console.log('🔍 Auth state updated - isAuthenticated:', !!user.value, 'isAdmin:', profile.value?.role === 'admin')
        } else {
          console.log('🔍 Clearing user from auth state change')
          user.value = null
          profile.value = null
        }
      })
    } catch (error) {
      console.error('Error initializing auth:', error)
    } finally {
      loading.value = false
      console.log('🔍 Auth initialization completed, loading set to:', loading.value)
    }
  }

  async function loadProfile() {
    if (!user.value) {
      console.log('🔍 No user found, skipping profile load')
      return
    }

    try {
      console.log('🔍 Loading profile for user:', user.value.id)
      
      // Add timeout to prevent hanging on profile load
      const profilePromise = supabase
        .from('users')
        .select('*')
        .eq('id', user.value.id)
        .single()
      
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Profile load timeout')), 5000)
      )
      
      const { data, error } = await Promise.race([profilePromise, timeoutPromise]) as any

      if (error) {
        console.error('🔍 Error loading profile:', error)
        console.warn('🔍 Continuing without profile - user will have basic access only')
        // Set a minimal profile to ensure user has some role
        profile.value = {
          id: user.value.id,
          email: user.value.email || '',
          role: 'user' // Default role
        }
        return
      }

      profile.value = data
      console.log('🔍 Profile loaded successfully:', data?.email, 'Role:', data?.role)
    } catch (error) {
      console.error('🔍 Exception loading profile:', error)
      // Set default profile on timeout or error
      profile.value = {
        id: user.value.id,
        email: user.value.email || '',
        role: 'user'
      }
      console.log('🔍 Using default profile due to error')
    }
  }

  async function signIn(email: string, password: string) {
    try {
      console.log('🔐 Starting sign in process for:', email)
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        console.error('🔐 Sign in error:', error)
        throw error
      }
      
      console.log('🔐 Sign in successful:', data.user ? 'User data received' : 'No user data')
      console.log('🔐 Session:', data.session ? 'Session created' : 'No session')
      
      // Explicitly set user and load profile (don't just rely on auth state change listener)
      if (data.user) {
        console.log('🔐 Explicitly setting user after sign in')
        user.value = data.user
        console.log('🔐 User value set to:', user.value.id, user.value.email)
        
        await loadProfile()
        
        // Force reactivity update by triggering computed properties
        const authState = isAuthenticated.value
        const adminState = isAdmin.value
        
        console.log('🔐 After loading profile:')
        console.log('🔐 - user.value:', !!user.value, user.value?.id)
        console.log('🔐 - profile.value:', !!profile.value, profile.value?.role)
        console.log('🔐 - isAuthenticated:', authState)
        console.log('🔐 - isAdmin:', adminState)
        
        // Ensure the values are actually computed
        await new Promise(resolve => setTimeout(resolve, 50))
        console.log('🔐 Final verification - isAuthenticated:', isAuthenticated.value, 'isAdmin:', isAdmin.value)
      } else {
        console.error('🔐 No user data in sign in response!')
      }
      
      return { data, error: null }
    } catch (error: any) {
      console.error('🔐 Sign in exception:', error)
      return { data: null, error: error.message }
    }
  }

  async function signUp(email: string, password: string) {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      })

      if (error) throw error
      
      return { data, error: null }
    } catch (error: any) {
      return { data: null, error: error.message }
    }
  }

  async function signOut() {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      
      user.value = null
      profile.value = null
    } catch (error) {
      console.error('Error signing out:', error)
    }
  }

  return {
    user: computed(() => user.value),
    profile: computed(() => profile.value),
    loading: computed(() => loading.value),
    isAuthenticated,
    isAdmin,
    isTeam,
    isUser,
    initialize,
    signIn,
    signUp,
    signOut,
  }
})