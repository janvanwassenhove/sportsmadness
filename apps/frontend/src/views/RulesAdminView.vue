<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'

interface Rule {
  id: string
  title: string
  description: string
  category: string
  icon?: string
  order_index: number
  is_active: boolean
  created_at: string
  updated_at: string
}

const { t } = useI18n()

const rules = ref<Rule[]>([])
const loading = ref(true)
const showRuleForm = ref(false)
const editingRule = ref<Rule | null>(null)

// Form data
const ruleForm = ref({
  title: '',
  description: '',
  category: 'general',
  icon: '',
  order_index: 0,
  is_active: true
})

const categories = [
  { value: 'basic', label: 'Basic Rules' },
  { value: 'gameplay', label: 'Gameplay' },
  { value: 'scoring', label: 'Scoring' },
  { value: 'penalties', label: 'Penalties' },
  { value: 'general', label: 'General' }
]

const resetRuleForm = () => {
  ruleForm.value = {
    title: '',
    description: '',
    category: 'general',
    icon: '',
    order_index: 0,
    is_active: true
  }
  editingRule.value = null
}

async function loadRules() {
  loading.value = true
  const { data, error } = await supabase
    .from('rules')
    .select('*')
    .order('order_index', { ascending: true })
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error loading rules:', error)
  } else {
    rules.value = data || []
  }
  loading.value = false
}

async function saveRule() {
  try {
    if (editingRule.value) {
      // Update existing rule
      const { error } = await supabase
        .from('rules')
        .update({
          title: ruleForm.value.title,
          description: ruleForm.value.description,
          category: ruleForm.value.category,
          icon: ruleForm.value.icon || null,
          order_index: ruleForm.value.order_index,
          is_active: ruleForm.value.is_active
        })
        .eq('id', editingRule.value.id)

      if (error) throw error
    } else {
      // Create new rule
      const { error } = await supabase
        .from('rules')
        .insert({
          title: ruleForm.value.title,
          description: ruleForm.value.description,
          category: ruleForm.value.category,
          icon: ruleForm.value.icon || null,
          order_index: ruleForm.value.order_index,
          is_active: ruleForm.value.is_active
        })

      if (error) throw error
    }

    showRuleForm.value = false
    resetRuleForm()
    await loadRules()
  } catch (error) {
    console.error('Error saving rule:', error)
    alert('Error saving rule. Please try again.')
  }
}

function editRule(rule: Rule) {
  editingRule.value = rule
  ruleForm.value = {
    title: rule.title,
    description: rule.description,
    category: rule.category,
    icon: rule.icon || '',
    order_index: rule.order_index,
    is_active: rule.is_active
  }
  showRuleForm.value = true
}

async function deleteRule(id: string) {
  if (!confirm('Are you sure you want to delete this rule?')) return

  try {
    const { error } = await supabase
      .from('rules')
      .delete()
      .eq('id', id)

    if (error) throw error
    await loadRules()
  } catch (error) {
    console.error('Error deleting rule:', error)
    alert('Error deleting rule. Please try again.')
  }
}

async function toggleActiveStatus(rule: Rule) {
  try {
    const { error } = await supabase
      .from('rules')
      .update({ is_active: !rule.is_active })
      .eq('id', rule.id)

    if (error) throw error
    await loadRules()
  } catch (error) {
    console.error('Error updating rule status:', error)
    alert('Error updating rule status. Please try again.')
  }
}

function getCategoryLabel(category: string): string {
  const cat = categories.find(c => c.value === category)
  return cat?.label || category
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

onMounted(async () => {
  await loadRules()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-white mb-2">{{ $t('rulesAdmin.title') }}</h1>
        <p class="text-blue-100">{{ $t('rulesAdmin.subtitle') }}</p>
      </div>

      <!-- Header with Add Button -->
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-2xl font-bold text-white">{{ $t('rulesAdmin.manageRules') }}</h2>
        <button 
          @click="showRuleForm = true; resetRuleForm()"
          class="btn btn-primary"
        >
          + {{ $t('rulesAdmin.addRule') }}
        </button>
      </div>

      <!-- Rules Grid -->
      <div v-if="loading" class="text-center py-8">
        <div class="text-white text-xl">{{ $t('common.loading') }}</div>
      </div>

      <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div 
          v-for="rule in rules" 
          :key="rule.id"
          :class="[
            'bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 transition-all duration-300',
            rule.is_active ? 'hover:bg-white/15' : 'opacity-60'
          ]"
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center space-x-3 flex-1">
              <div class="text-3xl">{{ rule.icon || '📋' }}</div>
              <div class="flex-1">
                <div class="flex items-center space-x-2 mb-1">
                  <h3 class="text-lg font-bold text-white">{{ rule.title }}</h3>
                  <span 
                    :class="[
                      'text-xs px-2 py-1 rounded-full text-white font-semibold',
                      getCategoryColor(rule.category)
                    ]"
                  >
                    {{ getCategoryLabel(rule.category) }}
                  </span>
                </div>
                <p class="text-blue-200 text-sm">{{ rule.description }}</p>
              </div>
            </div>
          </div>
          
          <div class="space-y-2 mb-4">
            <div class="flex items-center justify-between text-sm">
              <span class="text-blue-300">{{ $t('rulesAdmin.orderIndex') }}:</span>
              <span class="text-white font-mono">{{ rule.order_index }}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-blue-300">{{ $t('common.status') }}:</span>
              <button
                @click="toggleActiveStatus(rule)"
                :class="[
                  'px-2 py-1 rounded text-xs font-semibold transition-colors',
                  rule.is_active 
                    ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30' 
                    : 'bg-red-500/20 text-red-400 hover:bg-red-500/30'
                ]"
              >
                {{ rule.is_active ? $t('rulesAdmin.active') : $t('rulesAdmin.inactive') }}
              </button>
            </div>
          </div>

          <div class="flex space-x-2">
            <button 
              @click="editRule(rule)"
              class="flex-1 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition-colors"
            >
              {{ $t('common.edit') }}
            </button>
            <button 
              @click="deleteRule(rule.id)"
              class="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-semibold transition-colors"
            >
              {{ $t('common.delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Rule Form Modal -->
    <div v-if="showRuleForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">
          {{ editingRule ? $t('rulesAdmin.editRule') : $t('rulesAdmin.addNewRule') }}
        </h2>

        <form @submit.prevent="saveRule" class="space-y-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              {{ $t('rulesAdmin.ruleTitle') }} *
            </label>
            <input 
              v-model="ruleForm.title"
              type="text" 
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="$t('rulesAdmin.ruleTitlePlaceholder')"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              {{ $t('rulesAdmin.ruleDescription') }} *
            </label>
            <textarea 
              v-model="ruleForm.description"
              required
              rows="4"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              :placeholder="$t('rulesAdmin.ruleDescriptionPlaceholder')"
            ></textarea>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              {{ $t('rulesAdmin.category') }} *
            </label>
            <select 
              v-model="ruleForm.category"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option v-for="cat in categories" :key="cat.value" :value="cat.value">
                {{ cat.label }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              {{ $t('rulesAdmin.iconEmoji') }}
            </label>
            <input 
              v-model="ruleForm.icon"
              type="text" 
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="📋 (emoji)"
            >
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              {{ $t('rulesAdmin.orderIndex') }}
            </label>
            <input 
              v-model.number="ruleForm.order_index"
              type="number" 
              min="0"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="0"
            >
            <p class="text-xs text-gray-500 mt-1">{{ $t('rulesAdmin.orderIndexHelp') }}</p>
          </div>

          <div>
            <label class="flex items-center space-x-2">
              <input 
                v-model="ruleForm.is_active"
                type="checkbox" 
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              >
              <span class="text-sm font-semibold text-gray-700">{{ $t('rulesAdmin.isActive') }}</span>
            </label>
          </div>

          <div class="flex space-x-3 pt-4">
            <button 
              type="submit"
              class="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              {{ editingRule ? $t('common.update') : $t('common.create') }}
            </button>
            <button 
              type="button"
              @click="showRuleForm = false; resetRuleForm()"
              class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 py-2 px-4 rounded-lg font-semibold transition-colors"
            >
              {{ $t('common.cancel') }}
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
</style>
