<template>
  <div class="container mx-auto px-4 py-8 max-w-2xl">
    <div class="bg-white rounded-lg shadow-lg p-6">
      <div class="flex items-center mb-6">
        <button 
          @click="$router.go(-1)"
          class="mr-4 text-gray-600 hover:text-gray-800"
        >
          ← Back
        </button>
        <h1 class="text-3xl font-bold text-gray-800">My Profile</h1>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="flex justify-center items-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span class="ml-2 text-gray-600">Loading profile...</span>
      </div>

      <!-- Profile Form -->
      <form v-else @submit.prevent="updateProfile" class="space-y-6">
        <!-- Basic Info (Read-only) -->
        <div class="bg-gray-50 rounded-lg p-4">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Account Information</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
              <input 
                :value="authStore.profile?.email"
                type="email"
                readonly
                class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100"
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Role</label>
              <div class="flex items-center">
                <span 
                  class="inline-flex px-3 py-1 text-sm font-semibold rounded-full"
                  :class="getRoleBadgeClass(authStore.profile?.role)"
                >
                  {{ authStore.profile?.role }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Team Assignment (for users assigned to teams) -->
        <div v-if="assignedTeam" class="bg-blue-50 rounded-lg p-4">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Team Assignment</h2>
          
          <div class="flex items-center space-x-3">
            <div class="text-2xl">👥</div>
            <div>
              <div class="font-medium text-gray-900">{{ assignedTeam.name }}</div>
              <div class="text-sm text-gray-600">{{ assignedTeam.players?.length || 0 }} players</div>
            </div>
          </div>

          <!-- Team Players List -->
          <div v-if="assignedTeam.players?.length" class="mt-4">
            <h3 class="text-sm font-medium text-gray-700 mb-2">Team Members</h3>
            <div class="bg-white rounded border p-3 max-h-32 overflow-y-auto">
              <div 
                v-for="(player, index) in assignedTeam.players" 
                :key="index"
                class="text-sm text-gray-800 py-1"
              >
                {{ player.name || `Player ${index + 1}` }}
                <span v-if="player.position" class="text-gray-500 ml-2">({{ player.position }})</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Personal Information (Editable) -->
        <div class="bg-white border rounded-lg p-4">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Personal Information</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">First Name</label>
              <input 
                v-model="profileForm.firstName"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your first name"
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
              <input 
                v-model="profileForm.lastName"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your last name"
              >
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Position
                <span class="text-xs text-gray-500">(Optional)</span>
              </label>
              <select 
                v-model="profileForm.position"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select position</option>
                <option value="Goalkeeper">Goalkeeper</option>
                <option value="Defender">Defender</option>
                <option value="Midfielder">Midfielder</option>
                <option value="Forward">Forward</option>
                <option value="Coach">Coach</option>
                <option value="Assistant Coach">Assistant Coach</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
              <input 
                v-model="profileForm.phone"
                type="tel"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your phone number"
              >
            </div>
          </div>

          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-2">Bio</label>
            <textarea 
              v-model="profileForm.bio"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Tell us about yourself..."
            ></textarea>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-end space-x-3 pt-4 border-t">
          <button 
            type="button"
            @click="$router.push('/')"
            class="px-6 py-2 text-gray-600 hover:text-gray-800"
          >
            Cancel
          </button>
          <button 
            type="submit"
            :disabled="updating"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ updating ? 'Updating...' : 'Update Profile' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Team {
  id: string
  name: string
  players: any[]
}

interface ProfileForm {
  firstName: string
  lastName: string
  position: string
  phone: string
  bio: string
}

const authStore = useAuthStore()
const loading = ref(true)
const updating = ref(false)
const assignedTeam = ref<Team | null>(null)

const profileForm = ref<ProfileForm>({
  firstName: '',
  lastName: '',
  position: '',
  phone: '',
  bio: ''
})

// Load user's assigned team if they have one assigned
async function loadAssignedTeam() {
  if (!authStore.profile?.assigned_team_id) {
    return
  }

  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')
      .eq('id', authStore.profile.assigned_team_id)
      .single()

    if (error) throw error
    assignedTeam.value = data
  } catch (error) {
    console.error('Error loading assigned team:', error)
  }
}

// Load user's profile data (extended fields if they exist)
async function loadProfile() {
  try {
    loading.value = true
    
    // For now, we'll store extended profile data in the user metadata
    // In a real app, you might want a separate user_profiles table
    const user = authStore.user
    if (user?.user_metadata) {
      profileForm.value = {
        firstName: user.user_metadata.firstName || '',
        lastName: user.user_metadata.lastName || '',
        position: user.user_metadata.position || '',
        phone: user.user_metadata.phone || '',
        bio: user.user_metadata.bio || ''
      }
    }
  } catch (error) {
    console.error('Error loading profile:', error)
  } finally {
    loading.value = false
  }
}

// Update user profile
async function updateProfile() {
  try {
    updating.value = true

    const { error } = await supabase.auth.updateUser({
      data: {
        firstName: profileForm.value.firstName,
        lastName: profileForm.value.lastName,
        position: profileForm.value.position,
        phone: profileForm.value.phone,
        bio: profileForm.value.bio
      }
    })

    if (error) throw error

    alert('Profile updated successfully!')
  } catch (error: any) {
    console.error('Error updating profile:', error)
    alert(`Failed to update profile: ${error.message}`)
  } finally {
    updating.value = false
  }
}

function getRoleBadgeClass(role?: string) {
  switch (role) {
    case 'admin':
      return 'bg-red-100 text-red-800'
    case 'team':
      return 'bg-blue-100 text-blue-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

onMounted(async () => {
  await Promise.all([loadProfile(), loadAssignedTeam()])
})
</script>