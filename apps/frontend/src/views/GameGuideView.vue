<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'

interface Booster {
  id: string
  title: string
  description: string
  icon?: string
  picture?: string
  has_countdown: boolean
  duration: number
}

interface Maddie {
  id: string
  title: string
  description: string
  icon?: string
  picture?: string
  duration: number
}

interface Rule {
  id: string
  title: string
  description: string
  category: string
  icon?: string
  order_index: number
}

const { t } = useI18n()

const boosters = ref<Booster[]>([])
const maddies = ref<Maddie[]>([])
const rules = ref<Rule[]>([])
const loading = ref(true)
const activeTab = ref<'boosters' | 'maddies' | 'rules'>('boosters')

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

async function loadRules() {
  const { data, error } = await supabase
    .from('rules')
    .select('*')
    .eq('is_active', true)
    .order('order_index', { ascending: true })
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error loading rules:', error)
    return
  }

  rules.value = data || []
}

async function loadData() {
  loading.value = true
  await Promise.all([loadBoosters(), loadMaddies(), loadRules()])
  loading.value = false
}

const formatDuration = (seconds: number) => {
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  if (remainingSeconds === 0) return `${minutes}m`
  return `${minutes}m ${remainingSeconds}s`
}

function getCategoryLabel(category: string): string {
  const categories: Record<string, string> = {
    basic: t('gameGuide.categoryBasic'),
    gameplay: t('gameGuide.categoryGameplay'),
    scoring: t('gameGuide.categoryScoring'),
    penalties: t('gameGuide.categoryPenalties'),
    general: t('gameGuide.categoryGeneral')
  }
  return categories[category] || category
}

function getCategoryColor(category: string): string {
  const colors: Record<string, string> = {
    basic: 'bg-blue-500',
    gameplay: 'bg-purple-500',
    scoring: 'bg-green-500',
    penalties: 'bg-red-500',
    general: 'bg-gray-500'
  }
  return colors[category] || 'bg-gray-500'
}

// Group rules by category
const rulesByCategory = ref<Record<string, Rule[]>>({})

function groupRulesByCategory() {
  const grouped: Record<string, Rule[]> = {}
  rules.value.forEach(rule => {
    if (!grouped[rule.category]) {
      grouped[rule.category] = []
    }
    grouped[rule.category]!.push(rule)
  })
  rulesByCategory.value = grouped
}

onMounted(async () => {
  await loadData()
  groupRulesByCategory()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Page Header -->
      <div class="mb-8 text-center">
        <h1 class="text-4xl font-bold text-white mb-2">{{ $t('gameGuide.title') }}</h1>
        <p class="text-blue-100 text-lg">{{ $t('gameGuide.subtitle') }}</p>
      </div>

      <!-- Tabs -->
      <div class="flex space-x-1 mb-8 justify-center">
        <button 
          @click="activeTab = 'boosters'"
          :class="[
            'px-6 py-3 rounded-lg font-semibold transition-all duration-200',
            activeTab === 'boosters' 
              ? 'bg-blue-600 text-white shadow-lg' 
              : 'bg-white/10 text-blue-200 hover:bg-white/20'
          ]"
        >
          {{ $t('gameGuide.tabs.boosters') }}
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
          {{ $t('gameGuide.tabs.maddies') }}
        </button>
        <button 
          @click="activeTab = 'rules'"
          :class="[
            'px-6 py-3 rounded-lg font-semibold transition-all duration-200',
            activeTab === 'rules' 
              ? 'bg-green-600 text-white shadow-lg' 
              : 'bg-white/10 text-blue-200 hover:bg-white/20'
          ]"
        >
          {{ $t('gameGuide.tabs.rules') }}
        </button>
      </div>

      <!-- Boosters Tab -->
      <div v-if="activeTab === 'boosters'" class="space-y-6">
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-6">
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('gameGuide.boostersTitle') }}</h2>
          <p class="text-blue-100">{{ $t('gameGuide.boostersDescription') }}</p>
        </div>

        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">{{ $t('common.loading') }}</div>
        </div>

        <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div 
            v-for="booster in boosters" 
            :key="booster.id"
            class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
          >
            <div class="flex items-start space-x-3 mb-4">
              <div class="text-4xl">{{ booster.icon || '⚡' }}</div>
              <div class="flex-1">
                <h3 class="text-xl font-bold text-white mb-2">{{ booster.title }}</h3>
                <p class="text-blue-200 text-sm">{{ booster.description }}</p>
              </div>
            </div>
            
            <div class="space-y-2 border-t border-white/10 pt-4">
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">{{ $t('gameGuide.duration') }}:</span>
                <span class="text-white font-mono font-bold">{{ formatDuration(booster.duration) }}</span>
              </div>
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">{{ $t('gameGuide.countdown') }}:</span>
                <span :class="booster.has_countdown ? 'text-green-400' : 'text-yellow-400'">
                  {{ booster.has_countdown ? $t('common.yes') : $t('common.no') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Maddies Tab -->
      <div v-if="activeTab === 'maddies'" class="space-y-6">
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-6">
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('gameGuide.maddiesTitle') }}</h2>
          <p class="text-blue-100">{{ $t('gameGuide.maddiesDescription') }}</p>
        </div>

        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">{{ $t('common.loading') }}</div>
        </div>

        <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div 
            v-for="maddie in maddies" 
            :key="maddie.id"
            class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
          >
            <div class="flex items-start space-x-3 mb-4">
              <div class="text-4xl">{{ maddie.icon || '✨' }}</div>
              <div class="flex-1">
                <h3 class="text-xl font-bold text-white mb-2">{{ maddie.title }}</h3>
                <p class="text-blue-200 text-sm">{{ maddie.description }}</p>
              </div>
            </div>
            
            <div class="space-y-2 border-t border-white/10 pt-4">
              <div class="flex items-center justify-between text-sm">
                <span class="text-blue-300">{{ $t('gameGuide.duration') }}:</span>
                <span class="text-white font-mono font-bold">{{ formatDuration(maddie.duration) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Rules Tab -->
      <div v-if="activeTab === 'rules'" class="space-y-6">
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-6">
          <h2 class="text-2xl font-bold text-white mb-3">{{ $t('gameGuide.rulesTitle') }}</h2>
          <p class="text-blue-100">{{ $t('gameGuide.rulesDescription') }}</p>
        </div>

        <div v-if="loading" class="text-center py-8">
          <div class="text-white text-xl">{{ $t('common.loading') }}</div>
        </div>

        <div v-else class="space-y-6">
          <div v-for="(categoryRules, category) in rulesByCategory" :key="category" class="space-y-4">
            <h3 class="text-2xl font-bold text-white mb-4 flex items-center">
              <span 
                :class="[
                  'px-3 py-1 rounded-full text-white font-semibold mr-3',
                  getCategoryColor(category)
                ]"
              >
                {{ getCategoryLabel(category) }}
              </span>
            </h3>
            
            <div class="grid md:grid-cols-2 gap-4">
              <div 
                v-for="rule in categoryRules" 
                :key="rule.id"
                class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
              >
                <div class="flex items-start space-x-3">
                  <div class="text-3xl">{{ rule.icon || '📋' }}</div>
                  <div class="flex-1">
                    <h4 class="text-lg font-bold text-white mb-2">{{ rule.title }}</h4>
                    <p class="text-blue-200 text-sm">{{ rule.description }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Add any custom styles here if needed */
</style>
