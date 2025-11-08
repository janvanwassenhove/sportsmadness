<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { soundManager, SoundManager } from '@/lib/soundManager'

interface Booster {
  id: string
  title: string
  description: string
  icon?: string
  picture?: string
  sound_file?: string
  has_countdown: boolean
  duration: number
  created_at: string
  updated_at: string
}

interface Maddie {
  id: string
  title: string
  description: string
  icon?: string
  picture?: string
  sound_file?: string
  duration: number
  created_at: string
  updated_at: string
}

const { t } = useI18n()

const boosters = ref<Booster[]>([])
const maddies = ref<Maddie[]>([])
const loading = ref(true)
const activeTab = ref<'boosters' | 'maddies'>('boosters')

// Form states
const showBoosterForm = ref(false)
const showMaddieForm = ref(false)
const editingBooster = ref<Booster | null>(null)
const editingMaddie = ref<Maddie | null>(null)

// Sound-related state
const availableBoosterSounds = ref<any[]>([])
const availableMaddieSounds = ref<any[]>([])
const uploadingSound = ref(false)

// Form data
const boosterForm = ref({
  title: '',
  description: '',
  icon: '',
  picture: '',
  sound_file: '',
  has_countdown: true,
  duration: 60
})

const maddieForm = ref({
  title: '',
  description: '',
  icon: '',
  picture: '',
  sound_file: '',
  duration: 60
})

const resetBoosterForm = () => {
  boosterForm.value = {
    title: '',
    description: '',
    icon: '',
    picture: '',
    sound_file: '',
    has_countdown: true,
    duration: 60
  }
  editingBooster.value = null
}

const resetMaddieForm = () => {
  maddieForm.value = {
    title: '',
    description: '',
    icon: '',
    picture: '',
    sound_file: '',
    duration: 60
  }
  editingMaddie.value = null
}

async function loadBoosters() {
  const { data, error } = await supabase
    .from('boosters')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error loading boosters:', error)
    return
  }

  boosters.value = data || []
}

async function loadMaddies() {
  const { data, error } = await supabase
    .from('maddies')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error loading maddies:', error)
    return
  }

  maddies.value = data || []
}

async function loadData() {
  loading.value = true
  await Promise.all([loadBoosters(), loadMaddies()])
  loading.value = false
}

// Sound management functions
function getRandomSound(type: 'boosters' | 'maddies'): string {
  const sounds = type === 'boosters' 
    ? ['booster_1.mp3', 'booster_2.mp3', 'booster_3.mp3', 'booster_4.mp3']
    : ['maddie_1.mp3', 'maddie_2.mp3', 'maddie_3.mp3', 'maddie_4.mp3']
  
  const index = Math.floor(Math.random() * sounds.length)
  return sounds[index]!   // assert non-null because array is never empty
}

function assignRandomSoundIfNeeded(item: Booster | Maddie, type: 'boosters' | 'maddies'): string {
  if (!item.sound_file) {
    return getRandomSound(type)
  }
  return item.sound_file
}

function getSoundDisplayName(soundFile?: string): string {
  if (!soundFile) return 'No sound'
  
  if (soundFile.startsWith('custom_')) {
    return 'Custom sound'
  }
  
  // Convert filename to display name
  return soundFile
    .replace('.mp3', '')
    .replace('_', ' ')
    .replace(/\b\w/g, l => l.toUpperCase())
}

async function playSoundPreview(soundFile?: string, type: 'boosters' | 'maddies' = 'boosters') {
  if (!soundFile) return
  
  try {
    if (soundFile.startsWith('custom_')) {
      const customSoundData = SoundManager.getCustomSound(soundFile)
      if (customSoundData) {
        await SoundManager.playSound(customSoundData)
      }
    } else {
      await SoundManager.playSound(`/sounds/${type}/${soundFile}`)
    }
  } catch (error) {
    console.error('Error playing sound preview:', error)
  }
}

async function saveBooster() {
  try {
    // Auto-assign random sound if none selected
    const soundFile = boosterForm.value.sound_file || getRandomSound('boosters')
    
    if (editingBooster.value) {
      // Update existing booster
      const { error } = await supabase
        .from('boosters')
        .update({
          title: boosterForm.value.title,
          description: boosterForm.value.description,
          icon: boosterForm.value.icon || null,
          picture: boosterForm.value.picture || null,
          sound_file: soundFile,
          has_countdown: boosterForm.value.has_countdown,
          duration: boosterForm.value.duration
        })
        .eq('id', editingBooster.value.id)

      if (error) throw error
    } else {
      // Create new booster
      const { error } = await supabase
        .from('boosters')
        .insert({
          title: boosterForm.value.title,
          description: boosterForm.value.description,
          icon: boosterForm.value.icon || null,
          picture: boosterForm.value.picture || null,
          sound_file: soundFile,
          has_countdown: boosterForm.value.has_countdown,
          duration: boosterForm.value.duration
        })

      if (error) throw error
    }

    showBoosterForm.value = false
    resetBoosterForm()
    await loadBoosters()
  } catch (error) {
    console.error('Error saving booster:', error)
    alert('Error saving booster. Please try again.')
  }
}

async function saveMaddie() {
  try {
    // Auto-assign random sound if none selected
    const soundFile = maddieForm.value.sound_file || getRandomSound('maddies')
    
    if (editingMaddie.value) {
      // Update existing maddie
      const { error } = await supabase
        .from('maddies')
        .update({
          title: maddieForm.value.title,
          description: maddieForm.value.description,
          icon: maddieForm.value.icon || null,
          picture: maddieForm.value.picture || null,
          sound_file: soundFile,
          duration: maddieForm.value.duration
        })
        .eq('id', editingMaddie.value.id)

      if (error) throw error
    } else {
      // Create new maddie
      const { error } = await supabase
        .from('maddies')
        .insert({
          title: maddieForm.value.title,
          description: maddieForm.value.description,
          icon: maddieForm.value.icon || null,
          picture: maddieForm.value.picture || null,
          sound_file: soundFile,
          duration: maddieForm.value.duration
        })

      if (error) throw error
    }

    showMaddieForm.value = false
    resetMaddieForm()
    await loadMaddies()
  } catch (error) {
    console.error('Error saving maddie:', error)
    alert('Error saving maddie. Please try again.')
  }
}

function editBooster(booster: Booster) {
  editingBooster.value = booster
  boosterForm.value = {
    title: booster.title,
    description: booster.description,
    icon: booster.icon || '',
    picture: booster.picture || '',
    sound_file: booster.sound_file || '',
    has_countdown: booster.has_countdown,
    duration: booster.duration
  }
  showBoosterForm.value = true
}

function editMaddie(maddie: Maddie) {
  editingMaddie.value = maddie
  maddieForm.value = {
    title: maddie.title,
    description: maddie.description,
    icon: maddie.icon || '',
    picture: maddie.picture || '',
    sound_file: maddie.sound_file || '',
    duration: maddie.duration
  }
  showMaddieForm.value = true
}

async function deleteBooster(id: string) {
  if (!confirm('Are you sure you want to delete this booster?')) return

  try {
    const { error } = await supabase
      .from('boosters')
      .delete()
      .eq('id', id)

    if (error) throw error
    await loadBoosters()
  } catch (error) {
    console.error('Error deleting booster:', error)
    alert('Error deleting booster. Please try again.')
  }
}

async function deleteMaddie(id: string) {
  if (!confirm('Are you sure you want to delete this maddie?')) return

  try {
    const { error } = await supabase
      .from('maddies')
      .delete()
      .eq('id', id)

    if (error) throw error
    await loadMaddies()
  } catch (error) {
    console.error('Error deleting maddie:', error)
    alert('Error deleting maddie. Please try again.')
  }
}

const formatDuration = (seconds: number) => {
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  if (remainingSeconds === 0) return `${minutes}m`
  return `${minutes}m ${remainingSeconds}s`
}

// Sound-related functions
async function loadAvailableSounds() {
  try {
    const [boosterSounds, maddieSounds] = await Promise.all([
      SoundManager.getAvailableSounds('boosters'),
      SoundManager.getAvailableSounds('maddies')
    ])
    
    availableBoosterSounds.value = boosterSounds
    availableMaddieSounds.value = maddieSounds
  } catch (error) {
    console.error('Error loading available sounds:', error)
  }
}

async function handleSoundUpload(event: Event, type: 'boosters' | 'maddies') {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  if (!file) return
  
  if (!SoundManager.isValidAudioFile(file)) {
    alert('Please select a valid audio file (MP3, WAV, OGG) under 10MB')
    return
  }
  
  try {
    uploadingSound.value = true
    const itemId = type === 'boosters' 
      ? (editingBooster.value?.id || 'new')
      : (editingMaddie.value?.id || 'new')
    
    const soundPath = await SoundManager.uploadCustomSound(file, type, itemId)
    
    // Update the form with the custom sound path
    if (type === 'boosters') {
      boosterForm.value.sound_file = `custom_${type}_${itemId}_${file.name}`
    } else {
      maddieForm.value.sound_file = `custom_${type}_${itemId}_${file.name}`
    }
    
    console.log('✅ Sound uploaded successfully:', file.name)
  } catch (error) {
    console.error('Error uploading sound:', error)
    alert('Error uploading sound file. Please try again.')
  } finally {
    uploadingSound.value = false
  }
}

async function previewSound(soundFile: string, type: 'boosters' | 'maddies') {
  if (!soundFile) return
  
  try {
    let soundPath: string
    
    // Check if it's a custom uploaded sound
    if (soundFile.startsWith('custom_')) {
      const customSound = SoundManager.getCustomSound(soundFile)
      if (customSound) {
        soundPath = customSound
      } else {
        console.error('Custom sound not found:', soundFile)
        return
      }
    } else {
      // Use predefined sound from the public folder
      soundPath = `/sounds/${type}/${soundFile}`
    }
    
    await SoundManager.playSound(soundPath, 0.5) // Lower volume for preview
  } catch (error) {
    console.error('Error previewing sound:', error)
  }
}

onMounted(async () => {
  await Promise.all([loadData(), loadAvailableSounds()])
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-white mb-2">{{ $t('boostersAdmin.title') }}</h1>
        <p class="text-blue-100">{{ $t('boostersAdmin.subtitle') }}</p>
      </div>

      <!-- Tabs -->
      <div class="flex space-x-1 mb-8">
        <button 
          @click="activeTab = 'boosters'"
          :class="[
            'px-6 py-3 rounded-lg font-semibold transition-all duration-200',
            activeTab === 'boosters' 
              ? 'bg-blue-600 text-white shadow-lg' 
              : 'bg-white/10 text-blue-200 hover:bg-white/20'
          ]"
        >
          {{ $t('boostersAdmin.tabs.boosters') }}
        </button>
        <button 
          @click="activeTab = 'maddies'"
          :class="[
            'px-6 py-3 rounded-lg font-semibold transition-all duration-200',
            activeTab === 'maddies' 
              ? 'bg-purple-600 text-white shadow-lg' 
              : 'bg-white/10 text-blue-200 hover:bg-white/20'
          ]"
        >
          {{ $t('boostersAdmin.tabs.maddies') }}
        </button>
      </div>

      <!-- Boosters Tab -->
      <div v-if="activeTab === 'boosters'" class="space-y-6">
        <!-- Header with Add Button -->
        <div class="flex justify-between items-center">
          <h2 class="text-2xl font-bold text-white">Boosters</h2>
          <button 
            @click="showBoosterForm = true; resetBoosterForm()"
            class="btn btn-primary"
          >
            + Add Booster
          </button>
        </div>

        <!-- Boosters Grid -->
        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">Loading boosters...</div>
        </div>

        <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div 
            v-for="booster in boosters" 
            :key="booster.id"
            class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
          >
            <div class="flex items-start justify-between mb-4">
              <div class="flex items-center space-x-3">
                <div class="text-3xl">{{ booster.icon || '⚡' }}</div>
                <div>
                  <h3 class="text-lg font-bold text-white">{{ booster.title }}</h3>
                  <p class="text-blue-200 text-sm">{{ booster.description }}</p>
                </div>
              </div>
            </div>
            
            <div class="space-y-2 mb-4">
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">Duration:</span>
                <span class="text-white font-mono">{{ formatDuration(booster.duration) }}</span>
              </div>
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">Countdown:</span>
                <span :class="booster.has_countdown ? 'text-green-400' : 'text-red-400'">
                  {{ booster.has_countdown ? 'Yes' : 'No' }}
                </span>
              </div>
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">Sound:</span>
                <div class="flex items-center space-x-2">
                  <span class="text-white text-xs">{{ getSoundDisplayName(booster.sound_file) }}</span>
                  <button
                    v-if="booster.sound_file"
                    @click="playSoundPreview(booster.sound_file, 'boosters')"
                    class="text-blue-400 hover:text-blue-300 text-xs"
                    title="Play sound"
                  >
                    🔊
                  </button>
                </div>
              </div>
            </div>

            <div class="flex space-x-2">
              <button 
                @click="editBooster(booster)"
                class="flex-1 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition-colors"
              >
                Edit
              </button>
              <button 
                @click="deleteBooster(booster.id)"
                class="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-semibold transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Maddies Tab -->
      <div v-if="activeTab === 'maddies'" class="space-y-6">
        <!-- Header with Add Button -->
        <div class="flex justify-between items-center">
          <h2 class="text-2xl font-bold text-white">Maddies</h2>
          <button 
            @click="showMaddieForm = true; resetMaddieForm()"
            class="btn btn-primary"
          >
            + Add Maddie
          </button>
        </div>

        <!-- Maddies Grid -->
        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">Loading maddies...</div>
        </div>

        <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div 
            v-for="maddie in maddies" 
            :key="maddie.id"
            class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
          >
            <div class="flex items-start justify-between mb-4">
              <div class="flex items-center space-x-3">
                <div class="text-3xl">{{ maddie.icon || '✨' }}</div>
                <div>
                  <h3 class="text-lg font-bold text-white">{{ maddie.title }}</h3>
                  <p class="text-blue-200 text-sm">{{ maddie.description }}</p>
                </div>
              </div>
            </div>
            
            <div class="space-y-2 mb-4">
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">Duration:</span>
                <span class="text-white font-mono">{{ formatDuration(maddie.duration) }}</span>
              </div>
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">Sound:</span>
                <div class="flex items-center space-x-2">
                  <span class="text-white text-xs">{{ getSoundDisplayName(maddie.sound_file) }}</span>
                  <button
                    v-if="maddie.sound_file"
                    @click="playSoundPreview(maddie.sound_file, 'maddies')"
                    class="text-blue-400 hover:text-blue-300 text-xs"
                    title="Play sound"
                  >
                    🔊
                  </button>
                </div>
              </div>
            </div>

            <div class="flex space-x-2">
              <button 
                @click="editMaddie(maddie)"
                class="flex-1 py-2 px-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm font-semibold transition-colors"
              >
                Edit
              </button>
              <button 
                @click="deleteMaddie(maddie.id)"
                class="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-semibold transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Booster Form Modal -->
    <div v-if="showBoosterForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">
          {{ editingBooster ? 'Edit Booster' : 'Add New Booster' }}
        </h2>

        <form @submit.prevent="saveBooster" class="space-y-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Title *</label>
            <input 
              v-model="boosterForm.title"
              type="text" 
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="e.g., Power Play"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Description *</label>
            <textarea 
              v-model="boosterForm.description"
              required
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Describe what this booster does..."
            ></textarea>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Icon/Emoji</label>
            <input 
              v-model="boosterForm.icon"
              type="text" 
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="⚡ (emoji or URL)"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Picture URL</label>
            <input 
              v-model="boosterForm.picture"
              type="url" 
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="https://example.com/image.png"
            >
          </div>

          <div>
            <label class="flex items-center space-x-2">
              <input 
                v-model="boosterForm.has_countdown"
                type="checkbox" 
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              >
              <span class="text-sm font-semibold text-gray-700">Enable countdown during effect</span>
            </label>
            <p class="text-xs text-gray-500 mt-1">
              Uncheck for instant effects like "Coach Stroke" where time stops
            </p>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Duration (seconds) *</label>
            <input 
              v-model.number="boosterForm.duration"
              type="number" 
              min="0"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="60"
            >
          </div>

          <!-- Sound Selection -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Sound Effect</label>
            
            <!-- Predefined sounds dropdown -->
            <select 
              v-model="boosterForm.sound_file"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 mb-2"
            >
              <option value="">No sound</option>
              <option 
                v-for="sound in availableBoosterSounds" 
                :key="sound.name" 
                :value="sound.name"
              >
                {{ sound.displayName }}
              </option>
            </select>

            <!-- Custom sound upload -->
            <div class="mt-2">
              <label class="block text-xs text-gray-500 mb-1">Or upload custom sound:</label>
              <input 
                type="file" 
                accept="audio/*"
                @change="handleSoundUpload($event, 'boosters')"
                :disabled="uploadingSound"
                class="w-full text-sm text-gray-500 file:mr-4 file:py-1 file:px-3 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              >
            </div>

            <!-- Sound preview -->
            <div v-if="boosterForm.sound_file" class="mt-2 flex items-center space-x-2">
              <button
                type="button"
                @click="previewSound(boosterForm.sound_file, 'boosters')"
                class="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded transition-colors"
              >
                🔊 Preview
              </button>
              <span class="text-xs text-gray-500">{{ boosterForm.sound_file }}</span>
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button 
              type="submit"
              class="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              {{ editingBooster ? 'Update' : 'Create' }}
            </button>
            <button 
              type="button"
              @click="showBoosterForm = false; resetBoosterForm()"
              class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Maddie Form Modal -->
    <div v-if="showMaddieForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">
          {{ editingMaddie ? 'Edit Maddie' : 'Add New Maddie' }}
        </h2>

        <form @submit.prevent="saveMaddie" class="space-y-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Title *</label>
            <input 
              v-model="maddieForm.title"
              type="text" 
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="e.g., Maddie Magic"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Description *</label>
            <textarea 
              v-model="maddieForm.description"
              required
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="Describe what this maddie does..."
            ></textarea>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Icon/Emoji</label>
            <input 
              v-model="maddieForm.icon"
              type="text" 
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="✨ (emoji or URL)"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Picture URL</label>
            <input 
              v-model="maddieForm.picture"
              type="url" 
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="https://example.com/image.png"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Duration (seconds) *</label>
            <input 
              v-model.number="maddieForm.duration"
              type="number" 
              min="0"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500"
              placeholder="60"
            >
          </div>

          <!-- Sound Selection -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Sound Effect</label>
            
            <!-- Predefined sounds dropdown -->
            <select 
              v-model="maddieForm.sound_file"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 mb-2"
            >
              <option value="">No sound</option>
              <option 
                v-for="sound in availableMaddieSounds" 
                :key="sound.name" 
                :value="sound.name"
              >
                {{ sound.displayName }}
              </option>
            </select>

            <!-- Custom sound upload -->
            <div class="mt-2">
              <label class="block text-xs text-gray-500 mb-1">Or upload custom sound:</label>
              <input 
                type="file" 
                accept="audio/*"
                @change="handleSoundUpload($event, 'maddies')"
                :disabled="uploadingSound"
                class="w-full text-sm text-gray-500 file:mr-4 file:py-1 file:px-3 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-purple-50 file:text-purple-700 hover:file:bg-purple-100"
              >
            </div>

            <!-- Sound preview -->
            <div v-if="maddieForm.sound_file" class="mt-2 flex items-center space-x-2">
              <button
                type="button"
                @click="previewSound(maddieForm.sound_file, 'maddies')"
                class="text-xs bg-gray-100 hover:bg-gray-200 px-2 py-1 rounded transition-colors"
              >
                🔊 Preview
              </button>
              <span class="text-xs text-gray-500">{{ maddieForm.sound_file }}</span>
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button 
              type="submit"
              class="flex-1 bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              {{ editingMaddie ? 'Update' : 'Create' }}
            </button>
            <button 
              type="button"
              @click="showMaddieForm = false; resetMaddieForm()"
              class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-weight: 600;
  transition: background-color 0.2s;
}

.btn-primary {
  background-color: #2563eb;
  color: white;
}

.btn-primary:hover {
  background-color: #1d4ed8;
}

.btn-secondary {
  background-color: #4b5563;
  color: white;
}

.btn-secondary:hover {
  background-color: #374151;
}

.btn-success {
  background-color: #16a34a;
  color: white;
}

.btn-success:hover {
  background-color: #15803d;
}
</style>