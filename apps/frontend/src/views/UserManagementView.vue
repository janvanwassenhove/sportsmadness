<template>
  <div class="container mx-auto px-4 py-8">
    <div class="bg-white rounded-lg shadow-lg p-6">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-800">User Management</h1>
        <div class="flex space-x-3">
          <button 
            @click="loadUsers"
            class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
          >
            🔄 Refresh
          </button>
          <button 
            @click="showAddUserModal = true"
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
          >
            Add New User
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="flex justify-center items-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span class="ml-2 text-gray-600">Loading users...</span>
      </div>

      <!-- Users Table -->
      <div v-else class="overflow-x-auto">
        <table class="min-w-full table-auto">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Email</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Name</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Role</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Position</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Assigned Team</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Created</th>
              <th class="px-4 py-3 text-left text-sm font-semibold text-gray-900">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
              <td class="px-4 py-3 text-sm text-gray-900">{{ user.email }}</td>
              <td class="px-4 py-3 text-sm text-gray-900">{{ getUserFullName(user.id) || '-' }}</td>
              <td class="px-4 py-3 text-sm">
                <span 
                  class="inline-flex px-2 py-1 text-xs font-semibold rounded-full"
                  :class="getRoleBadgeClass(user.role)"
                >
                  {{ user.role }}
                </span>
              </td>
              <td class="px-4 py-3 text-sm text-gray-600">{{ getUserPosition(user.id) || '-' }}</td>
              <td class="px-4 py-3 text-sm text-gray-600">
                {{ user.assigned_team_id ? getTeamName(user.assigned_team_id) : '-' }}
              </td>
              <td class="px-4 py-3 text-sm text-gray-600">
                {{ formatDate(user.created_at) }}
              </td>
              <td class="px-4 py-3 text-sm">
                <button 
                  @click="editUser(user)"
                  class="text-blue-600 hover:text-blue-800 mr-3"
                >
                  Edit
                </button>
                <button 
                  v-if="user.id !== authStore.user?.id"
                  @click="deleteUser(user)"
                  class="text-red-600 hover:text-red-800"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add User Modal -->
    <div v-if="showAddUserModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
        <h2 class="text-xl font-bold mb-4">Add New User</h2>
        
        <form @submit.prevent="createUser" class="space-y-6">
          <!-- Account Information -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Account Information</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <input 
                  v-model="newUser.email"
                  type="email"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="user@example.com"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Password</label>
                <input 
                  v-model="newUser.password"
                  type="password"
                  required
                  minlength="6"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Minimum 6 characters"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Role</label>
                <select 
                  v-model="newUser.role"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="user">User</option>
                  <option value="team">Team</option>
                  <option value="admin">Admin</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Assign to Team
                  <span class="text-xs text-gray-500">(Optional for all roles)</span>
                </label>
                <select 
                  v-model="newUser.assigned_team_id"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">No team assigned</option>
                  <option v-for="team in teams" :key="team.id" :value="team.id">
                    {{ team.name }}
                  </option>
                </select>
                <p class="text-xs text-gray-500 mt-1">
                  Users can be assigned to teams regardless of their role for organizational purposes.
                </p>
              </div>
            </div>
          </div>

          <!-- Personal Information -->
          <div class="bg-white border rounded-lg p-4">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Personal Information</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">First Name</label>
                <input 
                  v-model="newUser.firstName"
                  type="text"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter first name"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                <input 
                  v-model="newUser.lastName"
                  type="text"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter last name"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Position</label>
                <select 
                  v-model="newUser.position"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select position</option>
                  <option value="Goalkeeper">Goalkeeper</option>
                  <option value="Defender">Defender</option>
                  <option value="Midfielder">Midfielder</option>
                  <option value="Forward">Forward</option>
                  <option value="Coach">Coach</option>
                  <option value="Assistant Coach">Assistant Coach</option>
                  <option value="Manager">Manager</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
                <input 
                  v-model="newUser.phone"
                  type="tel"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter phone number"
                >
              </div>
            </div>

            <div class="mt-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Bio / Description</label>
              <textarea 
                v-model="newUser.bio"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter bio or description..."
              ></textarea>
            </div>
          </div>

          <div class="flex justify-end space-x-3 pt-4 border-t">
            <button 
              type="button"
              @click="showAddUserModal = false"
              class="px-6 py-2 text-gray-600 hover:text-gray-800"
            >
              Cancel
            </button>
            <button 
              type="submit"
              :disabled="creating"
              class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg disabled:opacity-50"
            >
              {{ creating ? 'Creating...' : 'Create User' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Edit User Modal -->
    <div v-if="showEditUserModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
        <h2 class="text-xl font-bold mb-4">Edit User</h2>
        
        <form @submit.prevent="updateUser" class="space-y-6">
          <!-- Account Information -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Account Information</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                <input 
                  v-model="editingUser.email"
                  type="email"
                  readonly
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Role</label>
                <select 
                  v-model="editingUser.role"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="user">User</option>
                  <option value="team">Team</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
            </div>

            <div class="mt-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Assign to Team
                <span class="text-xs text-gray-500">(Optional for all roles)</span>
              </label>
              <select 
                v-model="editingUser.assigned_team_id"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">No team assigned</option>
                <option v-for="team in teams" :key="team.id" :value="team.id">
                  {{ team.name }}
                </option>
              </select>
              <p class="text-xs text-gray-500 mt-1">
                Users can be assigned to teams regardless of their role for organizational purposes.
              </p>
            </div>
          </div>

          <!-- Personal Information -->
          <div class="bg-white border rounded-lg p-4">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Personal Information</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">First Name</label>
                <input 
                  v-model="editingUserProfile.firstName"
                  type="text"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter first name"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                <input 
                  v-model="editingUserProfile.lastName"
                  type="text"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter last name"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Position</label>
                <select 
                  v-model="editingUserProfile.position"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select position</option>
                  <option value="Goalkeeper">Goalkeeper</option>
                  <option value="Defender">Defender</option>
                  <option value="Midfielder">Midfielder</option>
                  <option value="Forward">Forward</option>
                  <option value="Coach">Coach</option>
                  <option value="Assistant Coach">Assistant Coach</option>
                  <option value="Manager">Manager</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
                <input 
                  v-model="editingUserProfile.phone"
                  type="tel"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter phone number"
                >
              </div>
            </div>

            <div class="mt-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Bio / Description</label>
              <textarea 
                v-model="editingUserProfile.bio"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter bio or description..."
              ></textarea>
            </div>
          </div>

          <div class="flex justify-end space-x-3 pt-4 border-t">
            <button 
              type="button"
              @click="showEditUserModal = false"
              class="px-6 py-2 text-gray-600 hover:text-gray-800"
            >
              Cancel
            </button>
            <button 
              type="submit"
              :disabled="updating"
              class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg disabled:opacity-50"
            >
              {{ updating ? 'Updating...' : 'Update User' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface User {
  id: string
  email: string
  role: 'admin' | 'user' | 'team'
  assigned_team_id?: string | null
  created_at: string
}

interface UserProfile {
  firstName?: string
  lastName?: string
  position?: string
  phone?: string
  bio?: string
}

interface Team {
  id: string
  name: string
}

const authStore = useAuthStore()
const users = ref<User[]>([])
const teams = ref<Team[]>([])
const userProfiles = ref<Record<string, UserProfile>>({})
const loading = ref(true)
const creating = ref(false)
const updating = ref(false)

// Modal states
const showAddUserModal = ref(false)
const showEditUserModal = ref(false)

// Form data
const newUser = ref({
  email: '',
  password: '',
  role: 'user' as 'admin' | 'user' | 'team',
  assigned_team_id: '',
  firstName: '',
  lastName: '',
  position: '',
  phone: '',
  bio: ''
})

const editingUser = ref<User>({
  id: '',
  email: '',
  role: 'user',
  assigned_team_id: '',
  created_at: ''
})

const editingUserProfile = ref<UserProfile>({
  firstName: '',
  lastName: '',
  position: '',
  phone: '',
  bio: ''
})

async function loadUsers() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    users.value = data || []

    // Load profile data for each user
    await loadUserProfiles()
  } catch (error) {
    console.error('Error loading users:', error)
    alert('Failed to load users')
  } finally {
    loading.value = false
  }
}

async function loadUserProfiles() {
  try {
    // Load profile data for all users
    for (const user of users.value) {
      try {
        const { data: authUser, error } = await supabase.auth.admin.getUserById(user.id)
        if (!error && authUser.user?.user_metadata) {
          userProfiles.value[user.id] = {
            firstName: authUser.user.user_metadata.firstName || '',
            lastName: authUser.user.user_metadata.lastName || '',
            position: authUser.user.user_metadata.position || '',
            phone: authUser.user.user_metadata.phone || '',
            bio: authUser.user.user_metadata.bio || ''
          }
        }
      } catch (profileError) {
        console.warn(`Failed to load profile for user ${user.email}:`, profileError)
      }
    }
  } catch (error) {
    console.warn('Error loading user profiles:', error)
  }
}

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('id, name')
      .order('name')

    if (error) throw error
    teams.value = data || []
  } catch (error) {
    console.error('Error loading teams:', error)
  }
}

async function createUser() {
  try {
    creating.value = true
    
    // Create user in Supabase Auth with profile metadata
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: newUser.value.email,
      password: newUser.value.password,
      email_confirm: true,
      user_metadata: {
        firstName: newUser.value.firstName,
        lastName: newUser.value.lastName,
        position: newUser.value.position,
        phone: newUser.value.phone,
        bio: newUser.value.bio
      }
    })

    if (authError) throw authError

    // Update user profile with role and team assignment
    const { error: updateError } = await supabase
      .from('users')
      .update({
        role: newUser.value.role,
        assigned_team_id: newUser.value.assigned_team_id || null
      })
      .eq('id', authData.user.id)

    if (updateError) throw updateError

    // Reset form and close modal
    newUser.value = {
      email: '',
      password: '',
      role: 'user',
      assigned_team_id: '',
      firstName: '',
      lastName: '',
      position: '',
      phone: '',
      bio: ''
    }
    showAddUserModal.value = false
    
    // Reload users
    await loadUsers()
    
    alert('User created successfully!')
  } catch (error: any) {
    console.error('Error creating user:', error)
    alert(`Failed to create user: ${error.message}`)
  } finally {
    creating.value = false
  }
}

async function updateUser() {
  try {
    updating.value = true
    
    // Update role and team assignment in users table
    const { error: dbError } = await supabase
      .from('users')
      .update({
        role: editingUser.value.role,
        assigned_team_id: editingUser.value.assigned_team_id || null
      })
      .eq('id', editingUser.value.id)

    if (dbError) throw dbError

    // Update profile information in Supabase Auth metadata
    const { error: authError } = await supabase.auth.admin.updateUserById(
      editingUser.value.id,
      {
        user_metadata: {
          firstName: editingUserProfile.value.firstName,
          lastName: editingUserProfile.value.lastName,
          position: editingUserProfile.value.position,
          phone: editingUserProfile.value.phone,
          bio: editingUserProfile.value.bio
        }
      }
    )

    if (authError) {
      console.warn('Failed to update profile data:', authError)
      // Continue anyway since the main user data was updated
    }

    // Update the local profile cache
    userProfiles.value[editingUser.value.id] = { ...editingUserProfile.value }
    
    showEditUserModal.value = false
    await loadUsers()
    
    alert('User updated successfully!')
  } catch (error: any) {
    console.error('Error updating user:', error)
    alert(`Failed to update user: ${error.message}`)
  } finally {
    updating.value = false
  }
}

async function editUser(user: User) {
  editingUser.value = { ...user }
  
  // Load user's profile data from Supabase Auth metadata
  try {
    const { data: authUser, error } = await supabase.auth.admin.getUserById(user.id)
    
    if (error) {
      console.warn('Could not load user profile data:', error)
      // Reset profile form if we can't load data
      editingUserProfile.value = {
        firstName: '',
        lastName: '',
        position: '',
        phone: '',
        bio: ''
      }
    } else {
      // Load profile data from user metadata
      const metadata = authUser.user?.user_metadata || {}
      editingUserProfile.value = {
        firstName: metadata.firstName || '',
        lastName: metadata.lastName || '',
        position: metadata.position || '',
        phone: metadata.phone || '',
        bio: metadata.bio || ''
      }
    }
  } catch (error) {
    console.error('Error loading user profile:', error)
    // Reset profile form on error
    editingUserProfile.value = {
      firstName: '',
      lastName: '',
      position: '',
      phone: '',
      bio: ''
    }
  }
  
  showEditUserModal.value = true
}

async function deleteUser(user: User) {
  if (!confirm(`Are you sure you want to delete user "${user.email}"?`)) {
    return
  }

  try {
    // Delete from users table first
    const { error: dbError } = await supabase
      .from('users')
      .delete()
      .eq('id', user.id)
    
    if (dbError) throw dbError

    // Then delete from auth
    const { error: authError } = await supabase.auth.admin.deleteUser(user.id)
    if (authError) {
      console.warn('Failed to delete from auth, but user removed from database:', authError)
      // Continue anyway since the user is removed from our database
    }

    await loadUsers()
    alert('User deleted successfully!')
  } catch (error: any) {
    console.error('Error deleting user:', error)
    alert(`Failed to delete user: ${error.message}`)
  }
}

function getRoleBadgeClass(role: string) {
  switch (role) {
    case 'admin':
      return 'bg-red-100 text-red-800'
    case 'team':
      return 'bg-blue-100 text-blue-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

function getTeamName(teamId: string) {
  const team = teams.value.find(t => t.id === teamId)
  return team ? team.name : 'Unknown Team'
}

function getUserFullName(userId: string) {
  const profile = userProfiles.value[userId]
  if (!profile) return ''
  
  const firstName = profile.firstName || ''
  const lastName = profile.lastName || ''
  return `${firstName} ${lastName}`.trim()
}

function getUserPosition(userId: string) {
  const profile = userProfiles.value[userId]
  return profile?.position || ''
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString()
}

onMounted(async () => {
  await Promise.all([loadUsers(), loadTeams()])
})
</script>